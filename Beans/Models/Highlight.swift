import Foundation
import SwiftData

@Model
public final class Highlight {
    public var highlightId: UUID = UUID()
    public var text: String
    public var createdDate: Date
    public var article: Article?
    
    public init(text: String, createdDate: Date = Date(), article: Article? = nil) {
        self.highlightId = UUID()
        self.text = text
        self.createdDate = createdDate
        self.article = article
    }
}
