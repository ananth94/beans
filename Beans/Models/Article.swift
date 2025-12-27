import Foundation
import SwiftData

public enum ArticleStatus: String, Codable, CaseIterable {
    case toRead
    case inProgress
    case read
}

@Model
public final class Article {
    @Attribute(.unique) public var id: UUID
    public var url: String
    public var originalURL: String
    public var title: String
    public var content: String // Stores the parsed HTML
    public var author: String?
    public var siteName: String?
    public var domain: String?
    public var excerpt: String?
    public var faviconURL: String?
    
    public var readingTimeMinutes: Int
    public var imageURL: String?
    public var imageLocalPath: String?
    
    public var publishedDate: Date?
    public var savedDate: Date
    public var lastReadDate: Date?
    
    public var readingProgress: Double
    public var status: ArticleStatus
    public var isDownloaded: Bool
    public var isFavorite: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Highlight.article)
    public var highlights: [Highlight] = []
    
    public init(
        id: UUID = UUID(),
        url: String,
        originalURL: String,
        title: String,
        content: String,
        author: String? = nil,
        siteName: String? = nil,
        domain: String? = nil,
        excerpt: String? = nil,
        faviconURL: String? = nil,
        readingTimeMinutes: Int = 0,
        imageURL: String? = nil,
        publishedDate: Date? = nil,
        savedDate: Date = Date(),
        status: ArticleStatus = .toRead,
        isDownloaded: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.url = url
        self.originalURL = originalURL
        self.title = title
        self.content = content
        self.author = author
        self.siteName = siteName
        self.domain = domain
        self.excerpt = excerpt
        self.faviconURL = faviconURL
        self.readingTimeMinutes = readingTimeMinutes
        self.imageURL = imageURL
        self.publishedDate = publishedDate
        self.savedDate = savedDate
        self.status = status
        self.isDownloaded = isDownloaded
        self.isFavorite = isFavorite
        self.readingProgress = 0.0
    }
}
