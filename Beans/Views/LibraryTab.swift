import SwiftUI
import SwiftData

enum LibraryFilter: String, CaseIterable {
    case all = "All"
    case toRead = "To Read"
    case inProgress = "Reading"
    case read = "Read"
    case favorites = "Favorites"
    case highlights = "Highlights"
    
    var icon: String {
        switch self {
        case .all: return "tray.full.fill"
        case .toRead: return "book.closed.fill"
        case .inProgress: return "book.fill"
        case .read: return "checkmark.circle.fill"
        case .favorites: return "star.fill"
        case .highlights: return "quote.bubble.fill"
        }
    }
}

struct LibraryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Article.savedDate, order: .reverse) private var allArticles: [Article]
    
    @State private var selectedFilter: LibraryFilter = .all
    @State private var searchText = ""
    @State private var showingAddURL = false
    @State private var newURLString = ""
    @State private var isSaving = false
    @State private var showFavoriteBurst = false
    @AppStorage("hasSeenLibraryNudge") private var hasSeenLibraryNudge = false
    @State private var showCoachMark = false
    
    private var filteredArticles: [Article] {
        var articles = allArticles
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .toRead:
            articles = articles.filter { $0.status == .toRead }
        case .inProgress:
            articles = articles.filter { $0.status == .inProgress }
        case .read:
            articles = articles.filter { $0.status == .read }
        case .favorites:
            articles = articles.filter { $0.isFavorite }
        case .highlights:
            articles = articles.filter { !$0.highlights.isEmpty }
        }
        
        // Apply search
        if !searchText.isEmpty {
            articles = articles.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.siteName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return articles
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                BeansTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Library")
                            .font(.custom("Georgia-Bold", size: 32))
                            .foregroundColor(BeansTheme.primaryText)
                        Spacer()
                        
                        Button(action: { showingAddURL = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(BeansTheme.accent)
                        }
                        .overlay(alignment: .bottomLeading) {
                            if showCoachMark {
                                CoachMarkBubble(message: "Tap + to paste a link,\nor use Share in Safari.")
                                    .offset(x: -180, y: 50)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(LibraryFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    title: filter.rawValue,
                                    icon: filter.icon,
                                    isSelected: selectedFilter == filter,
                                    count: countFor(filter: filter)
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 12)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(BeansTheme.cremaBeige.opacity(0.5))
                        TextField("", text: $searchText, prompt: Text("Search articles...").foregroundColor(BeansTheme.cremaBeige.opacity(0.5)))
                            .foregroundColor(BeansTheme.primaryText)
                            .tint(BeansTheme.accent)
                    }
                    .padding(12)
                    .background(BeansTheme.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    // Content - Either Highlights or Articles
                    if selectedFilter == .highlights {
                        // Show dedicated Highlights view
                        HighlightsListView()
                            .padding(.horizontal, 8)
                    } else if filteredArticles.isEmpty {
                        Spacer()
                        emptyFilterState
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredArticles) { article in
                                ZStack {
                                    // Hidden NavigationLink to keep the custom card design
                                    NavigationLink(destination: ReaderView(article: article)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    ArticleRow(article: article)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            
                            // Bottom padding for tab bar
                            Color.clear
                                .frame(height: 100)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            // Optional: Add pull to refresh logic here if needed
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddURL) {
                AddBrewSheet(
                    isPresented: $showingAddURL,
                    urlString: $newURLString,
                    onBrew: { saveArticle() }
                )
            }
            .overlay {
                if isSaving {
                    blendingOverlay
                }
            }
            .overlay {
                if showFavoriteBurst {
                    FavoriteStarBurst()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showFavorite)) { _ in
                showFavoriteBurst = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showFavoriteBurst = false
                }
            }
            .task {
                await parseUnprocessedArticles()
                
                // Show coach mark only once if library is empty
                if allArticles.isEmpty && !hasSeenLibraryNudge {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.5)) {
                            showCoachMark = true
                        }
                    }
                }
            }
            .onChange(of: showingAddURL) { _, newValue in
                // Dismiss coach mark when sheet is opened
                if newValue && showCoachMark {
                    hasSeenLibraryNudge = true
                    withAnimation {
                        showCoachMark = false
                    }
                }
            }
        }
    }
    
    private func countFor(filter: LibraryFilter) -> Int {
        switch filter {
        case .all: return allArticles.count
        case .toRead: return allArticles.filter { $0.status == .toRead }.count
        case .inProgress: return allArticles.filter { $0.status == .inProgress }.count
        case .read: return allArticles.filter { $0.status == .read }.count
        case .favorites: return allArticles.filter { $0.isFavorite }.count
        case .highlights: return allArticles.filter { !$0.highlights.isEmpty }.count
        }
    }
    
    private var emptyFilterState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter.icon)
                .font(.system(size: 50))
                .foregroundColor(BeansTheme.cremaBeige.opacity(0.2))
            
            Text("No \(selectedFilter.rawValue.lowercased()) articles")
                .font(.custom("Georgia", size: 18))
                .foregroundColor(BeansTheme.secondaryText)
        }
    }
    
    
    private var blendingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 24) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                
                Text("Blending beans...")
                    .font(.custom("Georgia-Italic", size: 20))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func saveArticle() {
        guard let url = URL(string: newURLString) else { return }
        
        isSaving = true
        let service = ArticleService(modelContext: modelContext)
        
        Task {
            do {
                try await service.saveArticle(from: url)
                newURLString = ""
                
                // Play pour sound and check for milestone
                SoundService.shared.playPourSound()
                if let milestone = MilestoneService.shared.articleSaved() {
                    NotificationCenter.default.post(name: .showCelebration, object: milestone)
                }
            } catch {
                print("Error: \(error)")
            }
            isSaving = false
        }
    }
    
    private func parseUnprocessedArticles() async {
        let unparsed = allArticles.filter { $0.content.isEmpty && !$0.isDownloaded }
        guard !unparsed.isEmpty else { return }
        
        let parser = ContentParser()
        
        for article in unparsed {
            guard let url = URL(string: article.url) else { continue }
            
            do {
                let parsed = try await parser.parse(url: url)
                article.title = parsed.title
                article.content = parsed.content
                article.author = parsed.byline
                article.siteName = parsed.siteName
                article.excerpt = parsed.excerpt
                article.imageURL = parsed.imageURL  // Extract hero image!
                article.readingTimeMinutes = max(1, (parsed.textContent.components(separatedBy: .whitespacesAndNewlines).count / 200))
                article.isDownloaded = true
                try? modelContext.save()
            } catch {
                print("Failed to parse \(url): \(error)")
            }
        }
    }
}

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.2) : BeansTheme.accent.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? BeansTheme.accent : BeansTheme.cardBackground)
            .foregroundColor(isSelected ? .white : BeansTheme.primaryText)
            .cornerRadius(20)
        }
    }
}

struct ArticleRow: View {
    let article: Article
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            if let imageURL = article.imageURL {
                if imageURL.hasPrefix("beans://asset/") {
                    let assetName = String(imageURL.dropFirst("beans://asset/".count))
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                } else if let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            BeansTheme.espressoBlack
                        }
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                } else {
                     // Fallback for invalid URL string
                     fallbackThumbnail
                }
            } else {
                fallbackThumbnail
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if article.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(BeansTheme.favoriteYellow)
                            .font(.caption)
                    }
                    
                    if let site = article.siteName {
                        Text(site.uppercased())
                            .font(.caption2)
                            .fontWeight(.black)
                            .tracking(1)
                            .foregroundColor(BeansTheme.accent)
                    }
                }
                
                Text(article.title)
                    .font(.custom("Georgia-Bold", size: 17))
                    .foregroundColor(BeansTheme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 12) {
                    Label("\(article.readingTimeMinutes) min", systemImage: "clock")
                    
                    if article.readingProgress > 0 && article.readingProgress < 1 {
                        Text("•")
                        Text("\(Int(article.readingProgress * 100))%")
                    }
                }
                .font(.caption)
                .foregroundColor(BeansTheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(BeansTheme.secondaryText)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BeansTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        // Reading progress bar
        .overlay(alignment: .bottom) {
            if article.readingProgress > 0 && article.readingProgress < 1 {
                GeometryReader { geo in
                    Capsule()
                        .fill(BeansTheme.accent)
                        .frame(width: geo.size.width * article.readingProgress, height: 3)
                }
                .frame(height: 3)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .contextMenu {
            Text("Change Status")
            Button {
                article.status = .toRead
                article.readingProgress = 0  // Reset progress
                try? modelContext.save()
            } label: {
                Label("To Read", systemImage: "book.closed")
            }
            Button {
                article.status = .inProgress
                try? modelContext.save()
            } label: {
                Label("Reading", systemImage: "book")
            }
            Button {
                article.status = .read
                article.readingProgress = 1.0
                article.lastReadDate = Date()
                try? modelContext.save()
                
                // Play sound and check for milestone
                SoundService.shared.playSipSound()
                if let milestone = MilestoneService.shared.articleRead(readingTimeMinutes: article.readingTimeMinutes) {
                    // Post notification to show celebration
                    NotificationCenter.default.post(name: .showCelebration, object: milestone)
                }
            } label: {
                Label("Read", systemImage: "checkmark.circle")
            }
            Divider()
            Button {
                let wasFavorite = article.isFavorite
                article.isFavorite.toggle()
                try? modelContext.save()
                if !wasFavorite {
                    NotificationCenter.default.post(name: .showFavorite, object: nil)
                }
            } label: {
                Label(article.isFavorite ? "Unfavorite" : "Favorite",
                      systemImage: article.isFavorite ? "star.slash" : "star")
            }
            Divider()
            Button(role: .destructive) {
                modelContext.delete(article)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(article)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                let wasFavorite = article.isFavorite
                article.isFavorite.toggle()
                try? modelContext.save()
                if !wasFavorite {
                    NotificationCenter.default.post(name: .showFavorite, object: nil)
                }
            } label: {
                Label(article.isFavorite ? "Unfavorite" : "Favorite", 
                      systemImage: article.isFavorite ? "star.slash" : "star.fill")
            }
            .tint(BeansTheme.favoriteYellow)
        }
    }
    
    private var fallbackThumbnail: some View {
        ZStack {
            BeansTheme.cardBackground
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 20))
                .foregroundColor(BeansTheme.cremaBeige.opacity(0.3))
        }
        .frame(width: 60, height: 60)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    LibraryTab()
        .modelContainer(PersistenceService.preview.container)
}
