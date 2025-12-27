import SwiftUI

struct CoachMarkBubble: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(BeansTheme.favoriteYellow)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(BeansTheme.primaryText)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BeansTheme.cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .overlay(alignment: .topTrailing) {
            // Arrow pointing to the + button
            Triangle()
                .fill(BeansTheme.cardBackground)
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(0))
                .offset(x: 10, y: -5)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        BeansTheme.background.ignoresSafeArea()
        CoachMarkBubble(message: "Tap + to paste a link,\nor use Share in Safari.")
    }
}
