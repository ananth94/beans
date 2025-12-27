import Foundation
import SwiftData

typealias PersistenceController = PersistenceService

public class PersistenceService {
    public static let shared = PersistenceService()
    
    public let container: ModelContainer
    
    public init(inMemory: Bool = false) {
        let schema = Schema([
            Article.self,
            Highlight.self,
        ])
        
        // TODO: Replace with your actual App Group ID (e.g., "group.com.yourname.beans")
        let appGroupIdentifier: String? = "group.co.boringsoftware.beans"
        
        let modelConfiguration: ModelConfiguration
        if let groupID = appGroupIdentifier, !inMemory {
             let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)!
                .appendingPathComponent("default.store")
             modelConfiguration = ModelConfiguration(schema: schema, url: url)
        } else {
             modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        }
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Beans Error: Could not create ModelContainer with configuration: \(error)")
            // Fallback to in-memory so the app/extension doesn't hard crash
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Beans Critical Error: Could not even create an in-memory ModelContainer: \(error)")
            }
        }
    }
    
    @MainActor
    static let preview: PersistenceService = {
        let result = PersistenceService(inMemory: true)
        let viewContext = result.container.mainContext
        
        // Seed data for previews
        let sampleArticle = Article(
            url: "https://example.com/swift",
            originalURL: "https://example.com/swift",
            title: "The Future of Swift",
            content: "<h1>Swift is great.</h1><p>It is type-safe and fast.</p>",
            author: "John Doe",
            readingTimeMinutes: 5,
            savedDate: Date(),
            status: .inProgress
        )
        
        viewContext.insert(sampleArticle)
        
        return result
    }()
    
    @MainActor
    func seedTutorialData() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "hasSeededTutorial") { return }
        
        let context = container.mainContext
        
        // Card 1: Swipe Right
        let card1 = Article(
            url: "beans://tutorial/1",
            originalURL: "beans://tutorial/1",
            title: "Swipe Right to Read",
            content: "<h1>Reading is Simple</h1><p>See something you like? Swipe right to brew it. The article will open immediately for a distraction-free read.</p>",
            author: "Your friendly neighbourhood barista",
            readingTimeMinutes: 1,
            savedDate: Date(), // Card 1 (Top)
            status: .toRead
        )
        card1.excerpt = "Found something interesting? Swipe right to start reading immediately."
        card1.siteName = "Tutorial"
        card1.imageURL = "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80" // Coffee/Book image
        
        // Card 2: Swipe Left
        let card2 = Article(
            url: "beans://tutorial/2",
            originalURL: "beans://tutorial/2",
            title: "Swipe Left to Skip",
            content: "<h1>Pass on it</h1><p>Not interested? Swipe left to skip. We won't show it again.</p>",
            author: "Your friendly neighbourhood barista",
            readingTimeMinutes: 1,
            savedDate: Date().addingTimeInterval(1), // Card 2 (Middle)
            status: .toRead
        )
        card2.excerpt = "Not your cup of tea? Swipe left to dismiss an article forever."
        card2.siteName = "Tutorial"
        card2.imageURL = "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=800&q=80" // Wind/Nature image
        
        // Card 3: Try a Blend (New)
        let card3 = Article(
            url: "beans://tutorial/try-blend",
            originalURL: "beans://tutorial/try-blend",
            title: "Try a blend",
            content: "<h1>Brew your own</h1><p>Found a great article on the web? You can brew it right here.</p><p>Tap this card to try adding a link now.</p>",
            author: "Your friendly neighbourhood barista",
            readingTimeMinutes: 1,
            savedDate: Date().addingTimeInterval(2),
            status: .toRead
        )
        card3.excerpt = "Tap here to see how easy it is to add an article to your library."
        card3.siteName = "Tutorial"
        card3.imageURL = "beans://asset/tutorial_coffee_grinder"
        
        // Card 4: Finish
        let card4 = Article(
            url: "beans://tutorial/finish",
            originalURL: "beans://tutorial/finish",
            title: "Start brewing",
            content: """
            <h1>Welcome to beans</h1>
            <p>You've mastered the basics! beans is designed to be your cozy corner of the internet.</p>
            <p>We believe reading should be:</p>
            <ul>
            <li><strong>Focused:</strong> No distracting ads or popups.</li>
            <li><strong>Private:</strong> Your data stays on your device.</li>
            <li><strong>Beautiful:</strong> Typography that treats your eyes well.</li>
            </ul>
            <p>Go ahead, finish this article to earn your first milestone!</p>
            """,
            author: "Your friendly neighbourhood barista",
            readingTimeMinutes: 1,
            savedDate: Date().addingTimeInterval(3), // Card 4 (Bottom)
            status: .toRead
        )
        card4.excerpt = "Ready to dive in? Add your favourite articles and enjoy a distraction-free experience."
        card4.siteName = "Tutorial"
        card4.imageURL = "beans://asset/tutorial_coffee_sketch" // Reusing sketch for consistency
        
        context.insert(card1)
        context.insert(card2)
        context.insert(card3)
        context.insert(card4)
        
        try? context.save()
        defaults.set(true, forKey: "hasSeededTutorial")
    }
}
