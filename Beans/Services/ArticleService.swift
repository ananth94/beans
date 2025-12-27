import Foundation
import SwiftData
import Observation
import WebKit

// MARK: - Parsed Article Model
public struct ParsedArticle: Codable, Sendable {
    public let title: String
    public let content: String
    public let textContent: String
    public let excerpt: String
    public let byline: String?
    public let siteName: String?
    public let imageURL: String?
    public let length: Int?
}

// MARK: - Content Parser
@MainActor
public class ContentParser: NSObject, WKNavigationDelegate {
    public let webView: WKWebView
    private var continuation: CheckedContinuation<ParsedArticle, Error>?
    private var url: URL?
    private var timeoutTask: Task<Void, Never>?
    
    public override init() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.webView.navigationDelegate = self
    }
    
    public func parse(url: URL) async throws -> ParsedArticle {
        cancelRequest()
        self.url = url
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                if !Task.isCancelled {
                    fail(with: NSError(domain: "ContentParser", code: 408, userInfo: [NSLocalizedDescriptionKey: "Brewing timed out. The website is taking too long to respond."]))
                }
            }
            
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
    }
    
    private func cancelRequest() {
        timeoutTask?.cancel()
        timeoutTask = nil
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
    
    private func fail(with error: Error) {
        timeoutTask?.cancel()
        continuation?.resume(throwing: error)
        continuation = nil
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let bundle = Bundle(for: ContentParser.self)
        guard let scriptURL = bundle.url(forResource: "Readability", withExtension: "js"),
              let scriptContent = try? String(contentsOf: scriptURL, encoding: .utf8) else {
            fail(with: NSError(domain: "ContentParser", code: 404, userInfo: [NSLocalizedDescriptionKey: "Readability.js not found."]))
            return
        }
        
        let parsingScript = """
        (function() {
            \(scriptContent)
            var loc = document.location;
            var uri = {
                spec: loc.href,
                host: loc.host,
                prePath: loc.protocol + "//" + loc.host,
                scheme: loc.protocol.substr(0, loc.protocol.indexOf(":")),
                pathBase: loc.protocol + "//" + loc.host + loc.pathname.substr(0, loc.pathname.lastIndexOf("/") + 1)
            };
            try {
                var scripts = document.getElementsByTagName('script');
                var i = scripts.length; while (i--) { scripts[i].parentNode.removeChild(scripts[i]); }
                var article = new Readability(uri, document).parse();
                if (article) {
                    // Try to find a hero image
                    var heroImage = document.querySelector('meta[property="og:image"]')?.content || 
                                    document.querySelector('meta[name="twitter:image"]')?.content || 
                                    document.querySelector('link[rel="image_src"]')?.href;
                    
                    article.imageURL = heroImage;
                    return JSON.stringify(article);
                } else {
                    return "ERROR: Could not find readable content.";
                }
            } catch (e) {
                return "ERROR: " + e.toString();
            }
        })();
        """
        
        webView.evaluateJavaScript(parsingScript) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.fail(with: error)
            } else if let resultString = result as? String {
                if resultString.hasPrefix("ERROR:") {
                    self.fail(with: NSError(domain: "ContentParser", code: 500, userInfo: [NSLocalizedDescriptionKey: resultString]))
                    return
                }
                if let data = resultString.data(using: .utf8) {
                    do {
                        let article = try JSONDecoder().decode(ParsedArticle.self, from: data)
                        self.timeoutTask?.cancel()
                        self.continuation?.resume(returning: article)
                        self.continuation = nil
                    } catch {
                        self.fail(with: error)
                    }
                }
            } else {
                self.fail(with: NSError(domain: "ContentParser", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data returned."]))
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail(with: error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        fail(with: error)
    }
}

// MARK: - Article Service
@Observable
@MainActor
public class ArticleService {
    public let parser: ContentParser
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext, parser: ContentParser? = nil) {
        self.parser = parser ?? ContentParser()
        self.modelContext = modelContext
    }
    
    public func saveArticle(from url: URL) async throws {
        let urlString = url.absoluteString
        let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.url == urlString })
        if let _ = try? modelContext.fetch(descriptor).first {
            return
        }
        
        let parsed = try await parser.parse(url: url)
        
        let article = Article(
            url: url.absoluteString,
            originalURL: url.absoluteString,
            title: parsed.title,
            content: parsed.content,
            author: parsed.byline,
            siteName: parsed.siteName,
            excerpt: parsed.excerpt,
            readingTimeMinutes: calculateReadingTime(text: parsed.textContent),
            imageURL: parsed.imageURL,
            savedDate: Date(),
            status: .toRead
        )
        
        modelContext.insert(article)
        try modelContext.save()
    }
    
    private func calculateReadingTime(text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines).count
        return max(1, Int(ceil(Double(words) / 200.0)))
    }
}
