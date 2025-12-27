import UIKit
import UniformTypeIdentifiers
import SwiftData
import SwiftUI

@objc(ShareViewController)
class ShareViewController: UIViewController {

    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private var emitter: CAEmitterLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupParticles()
        handleShare()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 1.0)
        
        statusLabel.text = "Blending Beans..."
        statusLabel.textColor = UIColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 1.0)
        statusLabel.font = UIFont(name: "Georgia-Italic", size: 22) ?? .italicSystemFont(ofSize: 22)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .white
        spinner.startAnimating()
        
        view.addSubview(statusLabel)
        view.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20)
        ])
    }
    
    private func setupParticles() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.midY - 100)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        
        let cell = CAEmitterCell()
        cell.birthRate = 12
        cell.lifetime = 4.0
        cell.velocity = 150
        cell.velocityRange = 80
        cell.emissionLongitude = .pi
        cell.scale = 0.12
        cell.scaleRange = 0.08
        cell.contents = createCoffeeBeanImage()?.cgImage
        cell.spin = 2.0
        cell.spinRange = 4.0
        
        emitter.emitterCells = [cell]
        view.layer.insertSublayer(emitter, at: 0)
        self.emitter = emitter
    }
    
    private func createCoffeeBeanImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 40))
        return renderer.image { ctx in
            let path = UIBezierPath(ovalIn: CGRect(x: 5, y: 5, width: 20, height: 30))
            UIColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1.0).setFill()
            path.fill()
            
            let crack = UIBezierPath()
            crack.move(to: CGPoint(x: 15, y: 10))
            crack.addQuadCurve(to: CGPoint(x: 15, y: 30), controlPoint: CGPoint(x: 18, y: 20))
            UIColor(red: 0.2, green: 0.1, blue: 0.05, alpha: 1.0).setStroke()
            crack.lineWidth = 2
            crack.stroke()
        }
    }
    
    private func handleShare() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            completeRequest()
            return
        }
        
        let urlType = UTType.url.identifier
        let textType = UTType.plainText.identifier
        
        for provider in extensionItem.attachments ?? [] {
            if provider.hasItemConformingToTypeIdentifier(urlType) {
                provider.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] (item, error) in
                    guard let self = self else { return }
                    if let url = item as? URL {
                        Task { @MainActor in
                            self.saveURL(url)
                        }
                    } else {
                        DispatchQueue.main.async { self.completeRequest() }
                    }
                }
                return
            } else if provider.hasItemConformingToTypeIdentifier(textType) {
                provider.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] (item, error) in
                    guard let self = self else { return }
                    if let text = item as? String, let url = self.extractURL(from: text) {
                        Task { @MainActor in
                            self.saveURL(url)
                        }
                    } else {
                        DispatchQueue.main.async { self.completeRequest() }
                    }
                }
                return
            }
        }
        
        completeRequest()
    }
    
    private func extractURL(from text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url
    }
    
    @MainActor
    private func saveURL(_ url: URL) {
        // Get the shared model context
        let context = PersistenceService.shared.container.mainContext
        
        // Check if article already exists
        let urlString = url.absoluteString
        let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.url == urlString })
        if let _ = try? context.fetch(descriptor).first {
            // Already saved, show success and exit
            showSuccess(url: url)
            return
        }
        
        // Try to fetch metadata quickly before saving
        Task {
            var title = url.host ?? "Untitled"
            var imageURL: String? = nil
            var siteName = url.host
            var excerpt: String? = nil
            
            // Attempt fast metadata extraction (2 second timeout)
            do {
                let parser = MetadataParser(timeout: 2.0)
                let metadata = try await parser.parse(url: url)
                
                if let metaTitle = metadata.title, !metaTitle.isEmpty {
                    title = metaTitle
                }
                imageURL = metadata.imageURL
                if let metaSiteName = metadata.siteName {
                    siteName = metaSiteName
                }
                excerpt = metadata.description
            } catch {
                // Failed to fetch metadata - that's fine, we'll use fallback
                print("Metadata fetch failed: \(error.localizedDescription)")
            }
            
            // Create article with whatever data we have
            let article = Article(
                url: url.absoluteString,
                originalURL: url.absoluteString,
                title: title,
                content: "",  // Will be populated by main app
                siteName: siteName,
                excerpt: excerpt,
                imageURL: imageURL,
                savedDate: Date(),
                status: .toRead,
                isDownloaded: false  // Marks it as needing full content parsing
            )
            
            context.insert(article)
            
            do {
                try context.save()
                showSuccess(url: url)
            } catch {
                statusLabel.text = "Spilled some beans."
                statusLabel.textColor = .systemRed
                spinner.stopAnimating()
                print("Save error: \(error)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.completeRequest()
                }
            }
        }
    }
    
    private func showSuccess(url: URL) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        statusLabel.isHidden = true
        spinner.stopAnimating()
        emitter?.birthRate = 0
        
        let successView = SaveSuccessView(
            onDismiss: { [weak self] in
                self?.completeRequest()
            }
        )
        let hostingController = UIHostingController(rootView: successView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.alpha = 0
        hostingController.view.backgroundColor = .clear
        view.addSubview(hostingController.view)
        
        UIView.animate(withDuration: 0.3) {
            hostingController.view.alpha = 1.0
        }
        
        hostingController.didMove(toParent: self)
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
