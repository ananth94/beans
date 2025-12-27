import SwiftUI

/// Coffee-themed color palette used throughout the app
public struct BeansTheme {
    // Primary Colors
    public static let espressoBlack = Color(red: 0.1, green: 0.08, blue: 0.05)
    public static let cremaBeige = Color(red: 0.95, green: 0.9, blue: 0.8)
    public static let burntOrange = Color(red: 0.82, green: 0.41, blue: 0.12)
    public static let coffeeGrounds = Color(red: 0.15, green: 0.12, blue: 0.08)
    public static let latteLight = Color(red: 0.85, green: 0.78, blue: 0.68)
    
    // Semantic Colors
    public static let background = espressoBlack
    public static let cardBackground = coffeeGrounds
    public static let primaryText = cremaBeige
    public static let secondaryText = cremaBeige.opacity(0.6)
    public static let accent = burntOrange
    
    // Favorite Star
    public static let favoriteYellow = Color(red: 1.0, green: 0.8, blue: 0.2)
}
