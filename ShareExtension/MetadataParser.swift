import Foundation

/// Lightweight HTML metadata parser using URLSession (no WebView)
/// Designed for Share Extension where WKWebView is unreliable
public class MetadataParser {
    
    public struct Metadata: Sendable {
        public let title: String?
        public let imageURL: String?
        public let siteName: String?
        public let description: String?
    }
    
    private let timeout: TimeInterval
    
    public init(timeout: TimeInterval = 2.0) {
        self.timeout = timeout
    }
    
    /// Parse metadata from a URL using URLSession (fast, no JS)
    public func parse(url: URL) async throws -> Metadata {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "MetadataParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not decode HTML"])
        }
        
        return extractMetadata(from: html)
    }
    
    private func extractMetadata(from html: String) -> Metadata {
        let title = extractMetaContent(from: html, property: "og:title")
            ?? extractMetaContent(from: html, name: "title")
            ?? extractTitleTag(from: html)
        
        let imageURL = extractMetaContent(from: html, property: "og:image")
            ?? extractMetaContent(from: html, name: "twitter:image")
        
        let siteName = extractMetaContent(from: html, property: "og:site_name")
        
        let description = extractMetaContent(from: html, property: "og:description")
            ?? extractMetaContent(from: html, name: "description")
        
        return Metadata(
            title: title,
            imageURL: imageURL,
            siteName: siteName,
            description: description
        )
    }
    
    // MARK: - Private Extraction Helpers
    
    private func extractMetaContent(from html: String, property: String) -> String? {
        // Match: <meta property="og:title" content="...">
        let pattern = #"<meta[^>]+property\s*=\s*["']\#(property)["'][^>]+content\s*=\s*["']([^"']+)["']"#
        return extractRegex(pattern: pattern, from: html)
            ?? extractRegexReversed(property: property, from: html)
    }
    
    private func extractMetaContent(from html: String, name: String) -> String? {
        // Match: <meta name="title" content="...">
        let pattern = #"<meta[^>]+name\s*=\s*["']\#(name)["'][^>]+content\s*=\s*["']([^"']+)["']"#
        return extractRegex(pattern: pattern, from: html)
    }
    
    private func extractTitleTag(from html: String) -> String? {
        // Match: <title>...</title>
        let pattern = #"<title[^>]*>([^<]+)</title>"#
        return extractRegex(pattern: pattern, from: html)
    }
    
    private func extractRegex(pattern: String, from html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else { return nil }
        
        // Get the capture group (content value)
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range(at: 0)
        guard let swiftRange = Range(captureRange, in: html) else { return nil }
        return String(html[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractRegexReversed(property: String, from html: String) -> String? {
        // Some sites have content before property: <meta content="..." property="og:title">
        let pattern = #"<meta[^>]+content\s*=\s*["']([^"']+)["'][^>]+property\s*=\s*["']\#(property)["']"#
        return extractRegex(pattern: pattern, from: html)
    }
}
