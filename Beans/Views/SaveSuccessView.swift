import SwiftUI

public struct SaveSuccessView: View {
    public var onDismiss: (() -> Void)?
    
    public init(onSipNow: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        // onSipNow is kept for API compatibility but no longer used
        self.onDismiss = onDismiss
    }
    
    @State private var appear = false
    
    public var body: some View {
        VStack {
            Spacer()
            
            // Toast notification
            HStack(spacing: 16) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(Color(red: 0.82, green: 0.41, blue: 0.12))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(appear ? 1.0 : 0.5)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved to Beans!")
                        .font(.custom("Georgia-Bold", size: 18))
                        .foregroundColor(.white)
                    
                    Text("Ready when you are ☕")
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.15, green: 0.12, blue: 0.08))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 5)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
            .offset(y: appear ? 0 : 100)
            .opacity(appear ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(appear ? 0.3 : 0))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appear = true
            }
            
            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    appear = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss?()
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) {
                appear = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss?()
            }
        }
    }
}

#Preview {
    SaveSuccessView()
}
