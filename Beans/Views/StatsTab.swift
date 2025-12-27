import SwiftUI
import SwiftData

struct StatsTab: View {
    @Query private var articles: [Article]
    
    private var readCount: Int {
        articles.filter { $0.status == .read }.count
    }
    
    private var totalMinutes: Int {
        articles.filter { $0.status == .read }.reduce(0) { $0 + $1.readingTimeMinutes }
    }
    
    private var streak: Int {
        MilestoneService.shared.currentStreak
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                BeansTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Stats cards
                        HStack(spacing: 16) {
                            StatCard(icon: "book.fill", value: "\(readCount)", label: "Articles Read")
                            StatCard(icon: "clock.fill", value: "\(totalMinutes)", label: "Minutes Read")
                            StatCard(icon: "flame.fill", value: "\(streak)", label: "Day Streak", color: .orange)
                        }
                        .padding(.horizontal, 24)
                        
                        // Weekly Recap Card
                        WeeklyRecapCard(articles: articles)
                            .padding(.horizontal, 24)
                        
                        // Milestone badges section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Milestones")
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(BeansTheme.primaryText)
                                .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                MilestoneBadge(icon: "1.circle.fill", title: "First Sip", earned: readCount >= 1)
                                MilestoneBadge(icon: "5.circle.fill", title: "Getting Started", earned: readCount >= 5)
                                MilestoneBadge(icon: "10.circle.fill", title: "Bookworm", earned: readCount >= 10)
                                MilestoneBadge(icon: "25.circle.fill", title: "Scholar", earned: readCount >= 25)
                                MilestoneBadge(icon: "50.circle.fill", title: "Bibliophile", earned: readCount >= 50)
                                MilestoneBadge(icon: "star.circle.fill", title: "Centurion", earned: readCount >= 100)
                                MilestoneBadge(icon: "flame.circle.fill", title: "3-Day Streak", earned: streak >= 3)
                                MilestoneBadge(icon: "flame.circle.fill", title: "7-Day Streak", earned: streak >= 7)
                                MilestoneBadge(icon: "flame.circle.fill", title: "30-Day Streak", earned: streak >= 30)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = BeansTheme.cremaBeige
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.custom("Georgia-Bold", size: 24))
                .foregroundColor(BeansTheme.primaryText)
            Text(label)
                .font(.caption)
                .foregroundColor(BeansTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BeansTheme.cardBackground)
        )
    }
}

struct MilestoneBadge: View {
    let icon: String
    let title: String
    let earned: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? BeansTheme.accent.opacity(0.2) : BeansTheme.cardBackground)
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(earned ? BeansTheme.accent : BeansTheme.secondaryText.opacity(0.3))
                    .scaleEffect(isAnimating && earned ? 1.1 : 1.0)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(earned ? BeansTheme.primaryText : BeansTheme.secondaryText.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .opacity(earned ? 1.0 : 0.5)
        .onAppear {
            if earned {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
}

// Weekly Recap Card
struct WeeklyRecapCard: View {
    let articles: [Article]
    @State private var isExpanded = false
    
    private var thisWeekArticles: [Article] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return articles.filter { 
            $0.status == .read && ($0.lastReadDate ?? Date.distantPast) > weekAgo
        }
    }
    
    private var weeklyMinutes: Int {
        thisWeekArticles.reduce(0) { $0 + $1.readingTimeMinutes }
    }
    
    private var motivationalMessage: String {
        switch thisWeekArticles.count {
        case 0: return "Start your week with a fresh brew! ☕"
        case 1...2: return "Great start! Keep the momentum going."
        case 3...5: return "You're on fire this week! 🔥"
        case 6...10: return "Incredible reading pace! 📚"
        default: return "You're a reading machine! 🏆"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.custom("Georgia-Bold", size: 18))
                        .foregroundColor(BeansTheme.primaryText)
                    Text(motivationalMessage)
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(BeansTheme.secondaryText)
                }
                
                Spacer()
                
                // Coffee cup with steam animation
                ZStack {
                    Text("☕")
                        .font(.system(size: 30))
                    
                    if thisWeekArticles.count > 0 {
                        Text("✨")
                            .font(.system(size: 14))
                            .offset(x: 15, y: -15)
                    }
                }
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("\(thisWeekArticles.count)")
                        .font(.custom("Georgia-Bold", size: 28))
                        .foregroundColor(BeansTheme.accent)
                    Text("articles")
                        .font(.caption)
                        .foregroundColor(BeansTheme.secondaryText)
                }
                
                VStack(alignment: .leading) {
                    Text("\(weeklyMinutes)")
                        .font(.custom("Georgia-Bold", size: 28))
                        .foregroundColor(BeansTheme.accent)
                    Text("minutes")
                        .font(.caption)
                        .foregroundColor(BeansTheme.secondaryText)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(BeansTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(BeansTheme.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    StatsTab()
        .modelContainer(PersistenceService.preview.container)
}
