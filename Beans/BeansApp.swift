//
//  BeansApp.swift
//  Beans
//
//  Created by Ananth Radhakrishnan on 25/12/2025.
//

import SwiftUI
import SwiftData

extension Notification.Name {
    static let showCelebration = Notification.Name("showCelebration")
    static let showFavorite = Notification.Name("showFavorite")
}

@main
struct BeansApp: App {
    @State private var showCelebration = false
    @State private var celebrationType: CelebrationType = .firstOfDay
    @State private var deepLinkArticle: Article?
    @AppStorage("hasSeededTutorial") private var isOnboardingComplete = false
    @State private var showOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                
                if showCelebration {
                    CelebrationView(type: celebrationType, isPresented: $showCelebration)
                }
                
                if showOnboarding {
                    OnboardingView(isPresented: $showOnboarding)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .fullScreenCover(item: $deepLinkArticle) { article in
                NavigationStack {
                    ReaderView(article: article)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    deepLinkArticle = nil
                                }
                            }
                        }
                }
            }
            .task {
                // Check if onboarding is needed
                if !isOnboardingComplete {
                    showOnboarding = true
                }
                
                // Request notification permission
                _ = await NotificationService.shared.requestPermission()
                
                // Check app opened milestone
                if let milestone = MilestoneService.shared.appOpened() {
                    celebrationType = milestone
                    showCelebration = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showCelebration)) { notification in
                if let type = notification.object as? CelebrationType {
                    celebrationType = type
                    showCelebration = true
                }
            }
            .onOpenURL { url in
                print("🔗 Deep link received: \(url)")
                if url.scheme == "beans", url.host == "open",
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let articleUrl = components.queryItems?.first(where: { $0.name == "url" })?.value {
                    
                    print("🔗 Looking for article with URL: \(articleUrl)")
                    let context = PersistenceService.shared.container.mainContext
                    let fetchDescriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.url == articleUrl })
                    
                    if let article = try? context.fetch(fetchDescriptor).first {
                        print("🔗 Found article: \(article.title)")
                        deepLinkArticle = article
                    } else {
                        print("🔗 Article not found in database")
                    }
                }
            }
        }
        .modelContainer(PersistenceService.shared.container)
    }
}
