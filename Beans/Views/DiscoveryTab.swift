import SwiftUI
import SwiftData

struct DiscoveryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Article.savedDate, order: .forward) private var allArticles: [Article]
    
    private var toReadArticles: [Article] {
        allArticles.filter { $0.status == .toRead }
    }
    
    @State private var selectedArticle: Article?
    @State private var showingAddURL = false
    @State private var newURLString = ""
    @State private var isSaving = false
    @State private var showCelebration = false
    @State private var celebrationType: CelebrationType = .firstOfDay
    
    var body: some View {
        NavigationStack {
            ZStack {
                BeansTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Discovery")
                                .font(.custom("Georgia-Bold", size: 32))
                                .foregroundColor(BeansTheme.primaryText)
                            Text("\(toReadArticles.count) articles waiting")
                                .font(.subheadline)
                                .foregroundColor(BeansTheme.secondaryText)
                        }
                        Spacer()
                        
                        // Streak flame with pulse animation
                        if MilestoneService.shared.currentStreak >= 2 {
                            StreakFlame(streak: MilestoneService.shared.currentStreak)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    if toReadArticles.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        CardStackView(articles: toReadArticles) { article in
                            if article.url == "beans://tutorial/try-blend" {
                                // Tutorial Interception
                                newURLString = "https://beans.coffee/sample"
                                showingAddURL = true
                            } else {
                                selectedArticle = article
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedArticle) { article in
                ReaderView(article: article)
            }
            .task {
                await parseUnprocessedArticles()
            }
            .sheet(isPresented: $showingAddURL) {
                AddBrewSheet(
                    isPresented: $showingAddURL,
                    urlString: $newURLString,
                    onBrew: { saveArticle() }
                )
            }
            .overlay {
                if isSaving {
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
            }
            .overlay {
                if showCelebration {
                    CelebrationView(type: celebrationType, isPresented: $showCelebration)
                }
            }
        }
    }
    
    private func saveArticle() {
        guard let url = URL(string: newURLString) else { return }
        isSaving = true
        
        Task {
            // Mock Tutorial Logic
            if newURLString == "https://beans.coffee/sample" {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Fake network delay
                
                let dummy = Article(
                    url: "beans://sample/my-first-brew",
                    originalURL: "https://beans.coffee/sample",
                    title: "My First Brew",
                    content: "<h1>You did it!</h1><p>This is what a saved article looks like. Distraction-free, beautiful, and ready for you to read.</p><p>You can add any article from the web by pasting a link or using the Share Sheet in Safari.</p>",
                    author: "Your friendly neighbourhood barista",
                    readingTimeMinutes: 1,
                    savedDate: Date(),
                    status: .toRead
                )
                dummy.excerpt = "A sample article to show you how easy it is to brew your own content."
                dummy.siteName = "beans.coffee"
                dummy.imageURL = "beans://asset/tutorial_coffee_grinder"
                
                modelContext.insert(dummy)
                try? modelContext.save()
                
                // Remove the "Try a blend" tutorial card from the deck
                let tutorialURL = "beans://tutorial/try-blend"
                let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.url == tutorialURL })
                if let tutorialCard = try? modelContext.fetch(descriptor).first {
                    modelContext.delete(tutorialCard)
                    try? modelContext.save()
                }
                
                newURLString = ""
                SoundService.shared.playPourSound()
                // No celebration for sample article - keep flow smooth
                
                // Auto-open article after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    selectedArticle = dummy
                }
                
            } else {
                // Real Logic
                let service = ArticleService(modelContext: modelContext)
                do {
                    try await service.saveArticle(from: url)
                    newURLString = ""
                    SoundService.shared.playPourSound()
                } catch {
                    print("Error saving from Discovery: \(error)")
                }
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
                article.imageURL = parsed.imageURL
                article.readingTimeMinutes = max(1, (parsed.textContent.components(separatedBy: .whitespacesAndNewlines).count / 200))
                article.isDownloaded = true
                try? modelContext.save()
            } catch {
                print("Failed to parse from Discovery \(url): \(error)")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                // Coffee cup icon (same as all-seen state) with breathing animation
                BreathingCoffeeCup()
                
                // Animated Steam
                HStack(spacing: 8) {
                    SteamWisp(delay: 0)
                    SteamWisp(delay: 0.3)
                    SteamWisp(delay: 0.6)
                }
                .offset(y: -50)
            }
            
            Text("All caught up!")
                .font(.custom("Georgia-Bold", size: 24))
                .foregroundColor(BeansTheme.primaryText)
            
            Text("Enjoy the quiet. ☕️")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(BeansTheme.secondaryText)
        }
    }
}

// Animated steam wisp component
struct SteamWisp: View {
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        Capsule()
            .fill(BeansTheme.cremaBeige.opacity(animate ? 0.3 : 0.15))
            .frame(width: 4, height: animate ? 25 : 15)
            .offset(y: animate ? -15 : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

// Pulsing streak flame component
struct StreakFlame: View {
    let streak: Int
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .shadow(color: .orange.opacity(isPulsing ? 0.6 : 0.2), radius: isPulsing ? 8 : 2)
            Text("\(streak)")
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .font(.title3)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.orange.opacity(isPulsing ? 0.2 : 0.15))
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// Floating bean particles for ambient effect
struct FloatingBeans: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<8, id: \.self) { i in
                FloatingBean(index: i, bounds: geo.size)
            }
        }
    }
}

struct FloatingBean: View {
    let index: Int
    let bounds: CGSize
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    private var startX: CGFloat {
        CGFloat.random(in: 0...1) * bounds.width
    }
    
    private var startY: CGFloat {
        CGFloat.random(in: 0...1) * bounds.height
    }
    
    var body: some View {
        Text("☕")
            .font(.system(size: 12))
            .offset(x: startX + offset.width, y: startY + offset.height)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                let duration = Double.random(in: 8...15)
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.5)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -30...30),
                        height: CGFloat.random(in: -50...50)
                    )
                    rotation = Double.random(in: -20...20)
                }
            }
    }
}

#Preview {
    DiscoveryTab()
        .modelContainer(PersistenceService.preview.container)
}
