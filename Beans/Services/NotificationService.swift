import Foundation
import UserNotifications
import SwiftData

@MainActor
public class NotificationService {
    public static let shared = NotificationService()
    
    private let defaults = UserDefaults.standard
    private let dailyBrewTimeKey = "beans.notifications.dailyBrewTime"
    private let dailyBrewEnabledKey = "beans.notifications.dailyBrewEnabled"
    
    var isDailyBrewEnabled: Bool {
        get { defaults.bool(forKey: dailyBrewEnabledKey) }
        set { 
            defaults.set(newValue, forKey: dailyBrewEnabledKey)
            if newValue {
                scheduleDailyBrew()
            } else {
                cancelDailyBrew()
            }
        }
    }
    
    var dailyBrewHour: Int {
        get { defaults.object(forKey: dailyBrewTimeKey) as? Int ?? 7 }
        set { 
            defaults.set(newValue, forKey: dailyBrewTimeKey)
            if isDailyBrewEnabled {
                scheduleDailyBrew()
            }
        }
    }
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Daily Brew
    
    func scheduleDailyBrew() {
        let center = UNUserNotificationCenter.current()
        
        // Cancel existing
        center.removePendingNotificationRequests(withIdentifiers: ["dailyBrew"])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Your morning brew is ready ☕️"
        content.body = "Tap to discover today's reading"
        content.sound = .default
        content.badge = 1
        
        // Schedule for configured hour daily
        var dateComponents = DateComponents()
        dateComponents.hour = dailyBrewHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyBrew", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily brew: \(error)")
            }
        }
    }
    
    func scheduleDailyBrewWithArticle(title: String, readingTime: Int) {
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: ["dailyBrew"])
        
        let content = UNMutableNotificationContent()
        content.title = "Your morning brew is ready ☕️"
        content.body = "\"\(title)\" - \(readingTime) min read"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = dailyBrewHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "dailyBrew", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily brew: \(error)")
            }
        }
    }
    
    func cancelDailyBrew() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyBrew"])
    }
    
    // MARK: - Article Selection
    
    func selectArticleForDailyBrew(from articles: [Article]) -> Article? {
        // Filter to unread articles
        let unread = articles.filter { $0.status == .toRead }
        guard !unread.isEmpty else { return nil }
        
        // Priority 1: Oldest article (FIFO)
        let oldest = unread.min { $0.savedDate < $1.savedDate }
        
        return oldest
    }
    
    public func checkAndScheduleDailyBrew(from articles: [Article]) {
        guard isDailyBrewEnabled else { return }
        
        if let article = selectArticleForDailyBrew(from: articles) {
            scheduleDailyBrewWithArticle(title: article.title, readingTime: article.readingTimeMinutes)
        } else {
            scheduleDailyBrew() // fallback to generic
        }
    }
    
    // MARK: - Weekly Summary
    
    public func scheduleWeeklySummary(articlesRead: Int, minutesRead: Int) {
        let center = UNUserNotificationCenter.current()
        
        // Cancel existing
        center.removePendingNotificationRequests(withIdentifiers: ["weeklySummary"])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Brew ☕️"
        
        if articlesRead > 0 {
            content.body = "This week: \(articlesRead) articles, \(minutesRead) min read. Keep brewing!"
        } else {
            content.body = "Start brewing! You have articles waiting for you."
        }
        content.sound = .default
        
        // Schedule for Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklySummary", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Weekly summary notification error: \(error)")
            }
        }
    }
    
    public func calculateWeeklyStats(from articles: [Article]) -> (articlesRead: Int, minutesRead: Int) {
        let calendar = Calendar.current
        let now = Date()
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let recentlyRead = articles.filter { article in
            article.status == .read &&
            article.lastReadDate != nil &&
            article.lastReadDate! >= oneWeekAgo
        }
        
        let articlesCount = recentlyRead.count
        let minutesTotal = recentlyRead.reduce(0) { $0 + $1.readingTimeMinutes }
        
        return (articlesCount, minutesTotal)
    }
    
    public func checkAndScheduleWeeklySummary(from articles: [Article]) {
        let stats = calculateWeeklyStats(from: articles)
        scheduleWeeklySummary(articlesRead: stats.articlesRead, minutesRead: stats.minutesRead)
    }
}
