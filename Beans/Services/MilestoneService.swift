import Foundation
import SwiftUI

public enum CelebrationType {
    case hundredArticles
    case longArticle
    case weeklyStreak
    case firstOfDay
    case newStreakRecord
    
    public var title: String {
        switch self {
        case .hundredArticles: return "100 Cups Brewed! ☕️"
        case .longArticle: return "That was a big cup! 🏆"
        case .weeklyStreak: return "Perfect Week! 🔥"
        case .firstOfDay: return "Good Morning! ☀️"
        case .newStreakRecord: return "New Record! 🎉"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .hundredArticles: return "You've saved 100 articles to Beans"
        case .longArticle: return "You finished a 15+ minute read"
        case .weeklyStreak: return "You've read every day this week"
        case .firstOfDay: return "Your first brew of the day"
        case .newStreakRecord: return "You've beaten your all-time reading streak!"
        }
    }
    
    public var icon: String {
        switch self {
        case .hundredArticles: return "star.circle.fill"
        case .longArticle: return "trophy.fill"
        case .weeklyStreak: return "flame.fill"
        case .firstOfDay: return "sun.max.fill"
        case .newStreakRecord: return "crown.fill"
        }
    }
    
    public var iconColor: Color {
        switch self {
        case .hundredArticles: return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .longArticle: return .orange
        case .weeklyStreak: return .red
        case .firstOfDay: return .yellow
        case .newStreakRecord: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        }
    }
}

public class MilestoneService {
    public static let shared = MilestoneService()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private let totalArticlesSavedKey = "beans.milestones.totalArticlesSaved"
    private let totalArticlesReadKey = "beans.milestones.totalArticlesRead"
    private let lastReadDateKey = "beans.milestones.lastReadDate"
    private let currentStreakKey = "beans.milestones.currentStreak"
    private let highestStreakKey = "beans.milestones.highestStreak"
    private let celebratedMilestonesKey = "beans.milestones.celebrated"
    private let lastCelebrationDateKey = "beans.milestones.lastCelebrationDate"
    
    public init() {}
    
    // MARK: - Counted Milestones
    
    public var totalArticlesSaved: Int {
        get { defaults.integer(forKey: totalArticlesSavedKey) }
        set { defaults.set(newValue, forKey: totalArticlesSavedKey) }
    }
    
    public var totalArticlesRead: Int {
        get { defaults.integer(forKey: totalArticlesReadKey) }
        set { defaults.set(newValue, forKey: totalArticlesReadKey) }
    }
    
    public var currentStreak: Int {
        get { defaults.integer(forKey: currentStreakKey) }
        set { defaults.set(newValue, forKey: currentStreakKey) }
    }
    
    public var highestStreak: Int {
        get { defaults.integer(forKey: highestStreakKey) }
        set { defaults.set(newValue, forKey: highestStreakKey) }
    }
    
    public var lastReadDate: Date? {
        get { defaults.object(forKey: lastReadDateKey) as? Date }
        set { defaults.set(newValue, forKey: lastReadDateKey) }
    }
    
    private var lastCelebrationDate: Date? {
        get { defaults.object(forKey: lastCelebrationDateKey) as? Date }
        set { defaults.set(newValue, forKey: lastCelebrationDateKey) }
    }
    
    private var celebratedMilestones: Set<String> {
        get {
            let array = defaults.stringArray(forKey: celebratedMilestonesKey) ?? []
            return Set(array)
        }
        set {
            defaults.set(Array(newValue), forKey: celebratedMilestonesKey)
        }
    }
    
    // MARK: - Event Handlers
    
    public func articleSaved() -> CelebrationType? {
        totalArticlesSaved += 1
        
        // Check for 100 articles milestone
        if totalArticlesSaved == 100 && !hasCelebrated("100articles") {
            markCelebrated("100articles")
            return .hundredArticles
        }
        
        return nil
    }
    
    public func articleRead(readingTimeMinutes: Int) -> CelebrationType? {
        totalArticlesRead += 1
        
        // Update streak and check for new record
        if let streakCelebration = updateStreak() {
            return streakCelebration
        }
        
        // Check for long article (15+ minutes)
        if readingTimeMinutes >= 15 {
            return .longArticle
        }
        
        return nil
    }
    
    public func appOpened() -> CelebrationType? {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if onboarding is complete
        let isOnboardingComplete = defaults.bool(forKey: "hasSeededTutorial")
        guard isOnboardingComplete else { return nil }
        
        // Check if we already showed a celebration today
        if let lastCelebration = lastCelebrationDate,
           calendar.isDate(lastCelebration, inSameDayAs: now) {
            return nil
        }
        
        // Check time window for "Good Morning" (5 AM - 12 PM)
        let hour = calendar.component(.hour, from: now)
        let isMorning = hour >= 5 && hour < 12
        
        // Check if this is first open of the day
        if let lastRead = lastReadDate {
            if !calendar.isDate(lastRead, inSameDayAs: now) && isMorning {
                // New day + Morning -> show celebration
                lastCelebrationDate = now
                lastReadDate = now
                return .firstOfDay
            }
        } else if isMorning {
            // First time ever opening the app (post-onboarding) + Morning
            lastCelebrationDate = now
            lastReadDate = now
            return .firstOfDay
        }
        
        return nil
    }
    
    private func updateStreak() -> CelebrationType? {
        let now = Date()
        let calendar = Calendar.current
        
        if let lastRead = lastReadDate {
            let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastRead), to: calendar.startOfDay(for: now)).day ?? 0
            
            if daysBetween == 0 {
                // Same day - ensure streak is at least 1
                if currentStreak == 0 {
                    currentStreak = 1
                }
            } else if daysBetween == 1 {
                // Consecutive day - extend streak
                currentStreak += 1
                
                // Check if this is a new record
                if currentStreak > highestStreak {
                    highestStreak = currentStreak
                    lastReadDate = now
                    return .newStreakRecord
                }
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            // First time ever reading
            currentStreak = 1
            if highestStreak == 0 {
                highestStreak = 1
            }
        }
        
        lastReadDate = now
        return nil
    }
    
    public func checkWeeklyStreak() -> CelebrationType? {
        if currentStreak >= 7 && !hasCelebrated("weeklyStreak\(currentStreak / 7)") {
            markCelebrated("weeklyStreak\(currentStreak / 7)")
            return .weeklyStreak
        }
        return nil
    }
    
    private func hasCelebrated(_ milestone: String) -> Bool {
        celebratedMilestones.contains(milestone)
    }
    
    private func markCelebrated(_ milestone: String) {
        var milestones = celebratedMilestones
        milestones.insert(milestone)
        celebratedMilestones = milestones
    }
}

// MARK: - Celebration UI

public struct CelebrationView: View {
    public let type: CelebrationType
    @Binding var isPresented: Bool
    
    public init(type: CelebrationType, isPresented: Binding<Bool>) {
        self.type = type
        self._isPresented = isPresented
    }
    
    @State private var showConfetti = false
    @State private var iconScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    
    public var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Confetti
            if showConfetti {
                ConfettiView()
            }
            
            // Content card with solid background
            VStack(spacing: 24) {
                Image(systemName: type.icon)
                    .font(.system(size: 80))
                    .foregroundColor(type.iconColor)
                    .scaleEffect(iconScale)
                
                Text(type.title)
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                
                Text(type.subtitle)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                
                Button("Continue") {
                    isPresented = false
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(Color(red: 0.82, green: 0.41, blue: 0.12))
                .foregroundColor(.white)
                .fontWeight(.bold)
                .cornerRadius(12)
                .opacity(textOpacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.12, green: 0.1, blue: 0.08))
                    .shadow(color: .black.opacity(0.5), radius: 30)
            )
            .padding(.horizontal, 24)
        }
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                iconScale = 1
                showConfetti = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1
            }
        }
    }
}

public struct ConfettiView: View {
    public init() {}
    @State private var particles: [ConfettiParticle] = []
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, Color(red: 0.82, green: 0.41, blue: 0.12)]
        
        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                velocity: CGPoint(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: 200...500)),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x * 0.016
                particles[i].position.y += particles[i].velocity.y * 0.016
                particles[i].velocity.y += 400 * 0.016 // Gravity
                particles[i].opacity -= 0.005
            }
            
            particles.removeAll { $0.opacity <= 0 }
            
            if particles.isEmpty {
                timer.invalidate()
            }
        }
    }
}

public struct ConfettiParticle: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var velocity: CGPoint
    public let color: Color
    public let size: CGFloat
    public var opacity: Double
    
    public init(position: CGPoint, velocity: CGPoint, color: Color, size: CGFloat, opacity: Double) {
        self.position = position
        self.velocity = velocity
        self.color = color
        self.size = size
        self.opacity = opacity
    }
}
