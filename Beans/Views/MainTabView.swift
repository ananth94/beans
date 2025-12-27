import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @Query private var articles: [Article]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoveryTab()
                .tabItem {
                    Label("Discovery", systemImage: "cup.and.saucer.fill")
                }
                .tag(0)
            
            LibraryTab()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(1)
            
            StatsTab()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .tint(BeansTheme.accent)
        .task {
            NotificationService.shared.checkAndScheduleDailyBrew(from: articles)
            NotificationService.shared.checkAndScheduleWeeklySummary(from: articles)
        }
        .onAppear {
            // Style the tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(BeansTheme.espressoBlack)
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(BeansTheme.cremaBeige.opacity(0.5))
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(BeansTheme.cremaBeige.opacity(0.5))]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(BeansTheme.accent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(BeansTheme.accent)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceService.preview.container)
}
