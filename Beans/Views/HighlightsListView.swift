import SwiftUI
import SwiftData

struct HighlightsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Highlight.createdDate, order: .reverse) private var allHighlights: [Highlight]
    
    @State private var selectedHighlight: Highlight?
    @State private var showShareSheet = false
    @State private var shareText = ""
    
    var body: some View {
        ZStack {
            BeansTheme.background.ignoresSafeArea()
            
            if allHighlights.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(allHighlights) { highlight in
                            if let article = highlight.article {
                                NavigationLink(destination: ReaderView(article: article)) {
                                    HighlightCard(highlight: highlight)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        shareHighlight(highlight)
                                    } label: {
                                        Label("Share Quote", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button(role: .destructive) {
                                        deleteHighlight(highlight)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteHighlight(highlight)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        shareHighlight(highlight)
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(BeansTheme.accent)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Highlights")
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: shareText)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "highlighter")
                .font(.system(size: 50))
                .foregroundColor(BeansTheme.cremaBeige.opacity(0.3))
            
            Text("No Highlights Yet")
                .font(.custom("Georgia-Bold", size: 20))
                .foregroundColor(BeansTheme.primaryText)
            
            Text("Select text in any article and tap\n\"Highlight\" to save quotes here.")
                .font(.subheadline)
                .foregroundColor(BeansTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    private func shareHighlight(_ highlight: Highlight) {
        guard let article = highlight.article else { return }
        shareText = "\"\(highlight.text)\"\n\n— \(article.title)\n\(article.originalURL)"
        showShareSheet = true
    }
    
    private func deleteHighlight(_ highlight: Highlight) {
        modelContext.delete(highlight)
        try? modelContext.save()
    }
}

struct HighlightCard: View {
    let highlight: Highlight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote text (prominent)
            Text("\"\(highlight.text)\"")
                .font(.custom("Georgia-Italic", size: 16))
                .foregroundColor(BeansTheme.primaryText)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            // Article info (secondary)
            if let article = highlight.article {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(BeansTheme.secondaryText)
                    
                    Text(article.title)
                        .font(.caption)
                        .foregroundColor(BeansTheme.secondaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(highlight.createdDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(BeansTheme.secondaryText.opacity(0.7))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BeansTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BeansTheme.cremaBeige.opacity(0.2), lineWidth: 1)
        )
    }
}
