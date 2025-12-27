import SwiftUI
import SwiftData

struct CardStackView: View {
    let articles: [Article]
    var onSelect: (Article) -> Void
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var showFavoriteBurst = false
    @State private var entranceOffset: CGFloat = 300
    @State private var sessionSipCount = 0
    @State private var showSipToast = false
    @State private var heartbeatTimer: Timer?
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        ZStack { // Root container
            ZStack { // Active card stack
                ForEach(Array(visibleCards.enumerated().reversed()), id: \.element.id) { index, article in
                    if index > 0 {
                        ArticleCard(article: article, isTop: false)
                            .scaleEffect(1 - CGFloat(index) * 0.05)
                            .offset(y: CGFloat(index) * 8)
                            .allowsHitTesting(false)
                    }
                }
                
                // Top card (interactive)
                if let topArticle = visibleCards.first {
                    let shadowOpacity = 0.4 + min(0.3, abs(dragOffset.height) / 500)
                    let shadowRadius = 20 + min(CGFloat(20), abs(dragOffset.height) / 10)
                    let shadowY = 10 + min(CGFloat(15), abs(dragOffset.height) / 20)
                    
                    ArticleCard(article: topArticle, isTop: true)
                        .id("\(topArticle.id)-\(topArticle.imageURL ?? "")")
                        .offset(dragOffset)
                        .rotationEffect(.degrees(cardRotation))
                        // Dynamic shadow lift effect
                        .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
                        // 3D Parallax tilt effect
                        .rotation3DEffect(
                            .degrees(Double(dragOffset.width) / 15),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )
                        .rotation3DEffect(
                            .degrees(Double(-dragOffset.height) / 30),
                            axis: (x: 1, y: 0, z: 0),
                            perspective: 0.5
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Light haptic on first drag
                                    if dragOffset == .zero {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                    dragOffset = value.translation
                                    cardRotation = Double(value.translation.width / 20)
                                }
                                .onEnded { value in
                                    // Special handling for "Try a blend" tutorial card
                                    if topArticle.url == "beans://tutorial/try-blend" {
                                        handleTutorialSwipe(value.translation, article: topArticle)
                                    } else {
                                        handleSwipe(value.translation, article: topArticle)
                                    }
                                }
                        )
                        .onTapGesture {
                            // Enable Tap for "Try a blend" tutorial card
                            if topArticle.url == "beans://tutorial/try-blend" {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                onSelect(topArticle)
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                            if isPressing {
                                // Start haptic heartbeat
                                startHapticHeartbeat()
                            } else {
                                stopHapticHeartbeat()
                            }
                        }, perform: {})
                        .overlay(alignment: .topLeading) {
                            // Skip indicator
                            if dragOffset.width < -30 {
                                Text("LATER")
                                    .font(.headline)
                                    .fontWeight(.black)
                                    .foregroundColor(.orange)
                                    .padding(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.orange, lineWidth: 3)
                                    )
                                    .rotationEffect(.degrees(-15))
                                    .padding(24)
                                    .opacity(min(1, abs(dragOffset.width) / swipeThreshold))
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            // Read indicator
                            if dragOffset.width > 30 {
                                Text("READ")
                                    .font(.headline)
                                    .fontWeight(.black)
                                    .foregroundColor(.green)
                                    .padding(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.green, lineWidth: 3)
                                    )
                                    .rotationEffect(.degrees(15))
                                    .padding(24)
                                    .opacity(min(1, abs(dragOffset.width) / swipeThreshold))
                            }
                        }
                        .overlay(alignment: .top) {
                            // Favorite indicator
                            if dragOffset.height < -30 {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text("FAVORITE")
                                }
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(BeansTheme.favoriteYellow)
                                .padding(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(BeansTheme.favoriteYellow, lineWidth: 3)
                                )
                                .padding(.top, 24)
                                .opacity(min(1, abs(dragOffset.height) / swipeThreshold))
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Enforce width constraint on cards container
            .padding(.vertical, 20)
            .overlay {
                if showFavoriteBurst {
                    FavoriteStarBurst()
                }
            }
            .overlay(alignment: .top) {
                // Session sip count toast
                if showSipToast {
                    HStack(spacing: 8) {
                        Image(systemName: "cup.and.saucer.fill")
                        Text("\(sessionSipCount) articles sipped this session!")
                    }
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(BeansTheme.cremaBeige)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(BeansTheme.cardBackground)
                            .shadow(color: .black.opacity(0.3), radius: 10)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 20)
                }
            }
            .offset(y: entranceOffset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    entranceOffset = 0
                }
            }
            
            // Show exhausted state when all cards swiped but articles exist
            if visibleCards.isEmpty && !articles.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    ZStack {
                        BreathingCoffeeCup()
                        
                        // Animated Steam
                        HStack(spacing: 8) {
                            ExhaustedSteamWisp(delay: 0)
                            ExhaustedSteamWisp(delay: 0.3)
                            ExhaustedSteamWisp(delay: 0.6)
                        }
                        .offset(y: -50)
                    }
                    
                    Text("You've explored all brews!")
                        .font(.custom("Georgia-Bold", size: 24))
                        .foregroundColor(BeansTheme.primaryText)
                    
                    Text("Want to go through them again?")
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(BeansTheme.secondaryText)
                    
                    Button {
                        withAnimation(.spring()) {
                            currentIndex = 0
                        }
                    } label: {
                        Text("Start Over")
                            .fontWeight(.bold)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                            .background(BeansTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var visibleCards: [Article] {
        let startIndex = currentIndex
        let endIndex = min(currentIndex + 3, articles.count)
        guard startIndex < articles.count else { return [] }
        return Array(articles[startIndex..<endIndex])
    }
    
    private func handleSwipe(_ translation: CGSize, article: Article) {
        let horizontalSwipe = abs(translation.width) > abs(translation.height)
        
        if horizontalSwipe && translation.width > swipeThreshold {
            // Swipe Right → Open Reader
            swipeRight(article: article)
        } else if horizontalSwipe && translation.width < -swipeThreshold {
            // Swipe Left → Skip (move to back)
            swipeLeft(article: article)
        } else if !horizontalSwipe && translation.height < -swipeThreshold {
            // Swipe Up → Favorite
            swipeUp(article: article)
        } else {
            // Reset
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                dragOffset = .zero
                cardRotation = 0
            }
        }
    }
    
    private func handleTutorialSwipe(_ translation: CGSize, article: Article) {
        let horizontalSwipe = abs(translation.width) > abs(translation.height)
        
        if horizontalSwipe && translation.width > swipeThreshold {
            // Swipe Right → Trigger article creation via onSelect
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = CGSize(width: 500, height: 0)
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dragOffset = .zero
                cardRotation = 0
                onSelect(article)
            }
        } else if horizontalSwipe && translation.width < -swipeThreshold {
            // Swipe Left → Standard skip (move to back)
            swipeLeft(article: article)
        } else {
            // Reset
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                dragOffset = .zero
                cardRotation = 0
            }
        }
    }
    
    private func startHapticHeartbeat() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            generator.impactOccurred(intensity: 0.5)
        }
    }
    
    private func stopHapticHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func swipeRight(article: Article) {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: 500, height: 0)
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Mark as in-progress and navigate
            article.status = .inProgress
            article.lastReadDate = Date()
            try? modelContext.save()
            
            // If this is the final tutorial card, mark all tutorial articles as read
            if article.url == "beans://tutorial/finish" {
                let tutorialURLs = ["beans://tutorial/1", "beans://tutorial/2", "beans://tutorial/finish"]
                let descriptor = FetchDescriptor<Article>(predicate: #Predicate { tutorialURLs.contains($0.url) })
                if let tutorials = try? modelContext.fetch(descriptor) {
                    for tutorial in tutorials {
                        tutorial.status = .read
                    }
                    try? modelContext.save()
                }
            }
            
            // Increment session sip count
            sessionSipCount += 1
            if sessionSipCount % 5 == 0 {
                withAnimation(.spring()) {
                    showSipToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showSipToast = false
                    }
                }
            }
            
            // Reset state (card removed from stack via status change)
            dragOffset = .zero
            cardRotation = 0
            // currentIndex stays 0 because list shifted
            
            onSelect(article)
        }
    }
    
    private func swipeLeft(article: Article) {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: -500, height: 0)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // If this is the final tutorial card, mark all tutorial articles as read
            if article.url == "beans://tutorial/finish" {
                let tutorialURLs = ["beans://tutorial/1", "beans://tutorial/2", "beans://tutorial/finish"]
                let descriptor = FetchDescriptor<Article>(predicate: #Predicate { tutorialURLs.contains($0.url) })
                if let tutorials = try? modelContext.fetch(descriptor) {
                    for tutorial in tutorials {
                        tutorial.status = .read
                    }
                    try? modelContext.save()
                }
            }
            
            // Move to end of queue (update savedDate to be newest)
            article.savedDate = Date()
            try? modelContext.save()
            
            dragOffset = .zero
            cardRotation = 0
            // currentIndex stays 0 because list shifted
        }
    }
    
    private func swipeUp(article: Article) {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: 0, height: -500)
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            article.isFavorite = true
            try? modelContext.save()
            
            // Trigger star burst animation
            showFavoriteBurst = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showFavoriteBurst = false
            }
            
            dragOffset = .zero
            cardRotation = 0
            currentIndex += 1
        }
    }
}

struct ArticleCard: View {
    let article: Article
    let isTop: Bool
    
    // Show skeleton if article hasn't been parsed yet
    private var needsSkeleton: Bool {
        article.content.isEmpty && !article.isDownloaded
    }
    
    var body: some View {
        Group {
            if needsSkeleton {
                SkeletonArticleCard()
            } else {
                parsedArticleCard
            }
        }
        .frame(width: UIScreen.main.bounds.width - 48) // Guaranteed margins
        .frame(height: 480)
        .clipped()
        .background(BeansTheme.espressoBlack)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var parsedArticleCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image
            ZStack {
                BeansTheme.cardBackground
                
                if let imageURL = article.imageURL {
                    if imageURL.hasPrefix("beans://asset/") {
                        // Load local asset
                        let assetName = String(imageURL.dropFirst("beans://asset/".count))
                        Image(assetName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let url = URL(string: imageURL) {
                        // Load remote URL
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(BeansTheme.cremaBeige)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_):
                                placeholderImage
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        placeholderImage
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(width: UIScreen.main.bounds.width - 48)
            .frame(height: 200)
            .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                // Site name
                if let site = article.siteName {
                    Text(site.uppercased())
                        .font(.caption)
                        .fontWeight(.black)
                        .tracking(2)
                        .foregroundColor(BeansTheme.accent)
                }
                
                // Title
                Text(article.title)
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(BeansTheme.primaryText)
                    .lineLimit(4) // Prioritize title visibility
                    .multilineTextAlignment(.leading)
                
                // Excerpt
                if let excerpt = article.excerpt, !excerpt.isEmpty {
                    Text(excerpt)
                        .font(.custom("Georgia", size: 15))
                        .foregroundColor(BeansTheme.secondaryText)
                        .lineLimit(2) // Reduced to make room for longer titles
                }
                
                Spacer()
                
                // Reading time
                HStack {
                    Image(systemName: "clock")
                    Text("\(article.readingTimeMinutes) min read")
                    
                    Spacer()
                    
                    if article.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(BeansTheme.favoriteYellow)
                    }
                }
                .font(.subheadline)
                .foregroundColor(BeansTheme.secondaryText)
            }
            .padding(24)
        }
        .frame(width: UIScreen.main.bounds.width - 48)
    }
    
    private var placeholderImage: some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: 60))
            .foregroundColor(BeansTheme.cremaBeige.opacity(0.1))
    }
}

// Animated steam wisp for exhausted state
struct ExhaustedSteamWisp: View {
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

// MARK: - Skeleton Card for Unparsed Articles
struct SkeletonArticleCard: View {
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Skeleton Hero Image
            ZStack {
                BeansTheme.cardBackground
                
                // Coffee cup with steam
                VStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 50))
                        .foregroundColor(BeansTheme.cremaBeige.opacity(0.15))
                    
                    Text("Brewing...")
                        .font(.custom("Georgia-Italic", size: 14))
                        .foregroundColor(BeansTheme.cremaBeige.opacity(0.3))
                }
            }
            .frame(width: UIScreen.main.bounds.width - 48)
            .frame(height: 200)
            .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                // Skeleton site name
                SkeletonLine(width: 80, height: 12)
                
                // Skeleton title (2 lines)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLine(width: .infinity, height: 20)
                    SkeletonLine(width: 200, height: 20)
                }
                
                // Skeleton excerpt
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonLine(width: .infinity, height: 14)
                    SkeletonLine(width: .infinity, height: 14)
                    SkeletonLine(width: 150, height: 14)
                }
                
                Spacer()
                
                // Skeleton reading time
                SkeletonLine(width: 100, height: 14)
            }
            .padding(24)
        }
        .overlay(
            // Shimmer overlay
            GeometryReader { geometry in
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.5)
                .offset(x: shimmerOffset * geometry.size.width)
                .mask(RoundedRectangle(cornerRadius: 24))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2
            }
        }
    }
}

struct SkeletonLine: View {
    let width: CGFloat
    let height: CGFloat
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(BeansTheme.cremaBeige.opacity(0.1))
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: height, maxHeight: height)
    }
}

// Breathing/pulsing coffee cup for empty states
struct BreathingCoffeeCup: View {
    @State private var isBreathing = false
    
    var body: some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: 60))
            .foregroundColor(BeansTheme.cremaBeige.opacity(0.3))
            .scaleEffect(isBreathing ? 1.05 : 1.0)
            .opacity(isBreathing ? 0.4 : 0.3)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    isBreathing = true
                }
            }
    }
}

#Preview {
    ZStack {
        BeansTheme.background.ignoresSafeArea()
        CardStackView(articles: [], onSelect: { _ in })
    }
    .modelContainer(PersistenceService.preview.container)
}
