import SwiftUI

// MARK: - Favorite Star Burst Animation
struct FavoriteStarBurst: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: animate ? 8 : 16))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0)) // BeansTheme.favoriteYellow
                    .opacity(animate ? 0 : 1)
                    .offset(
                        x: animate ? cos(CGFloat(index) * .pi / 6) * 100 : 0,
                        y: animate ? sin(CGFloat(index) * .pi / 6) * 100 : 0
                    )
                    .rotationEffect(.degrees(animate ? Double(index) * 30 : 0))
            }
            
            // Central star
            Image(systemName: "star.fill")
                .font(.system(size: animate ? 40 : 20))
                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                .opacity(animate ? 0 : 1)
                .scaleEffect(animate ? 2.0 : 1.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animate = true
            }
        }
    }
}
