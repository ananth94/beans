import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    @State private var appear = false
    @State private var liquidFill: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            BeansTheme.espressoBlack.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Typography Section
                VStack(spacing: 16) {
                    Image("onboarding_app_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(appear ? 1 : 0.5)
                        .opacity(appear ? 1 : 0)
                        .padding(.bottom, 10)
                        
                    Text("beans")
                        .font(.custom("Georgia-Bold", size: 64))
                        .foregroundColor(BeansTheme.cremaBeige)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                    
                    Text("Your personal coffee break\nfor the internet.")
                        .font(.custom("Georgia-Italic", size: 24))
                        .foregroundColor(BeansTheme.cremaBeige.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                }
                
                Spacer()
                
                // Action Button
                Button {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        liquidFill = 1.0
                    }
                    
                    // Delay dismissal to let animation play
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation {
                            isPresented = false
                        }
                        PersistenceService.shared.seedTutorialData()
                    }
                } label: {
                    ZStack(alignment: .bottom) {
                        // Creating a "cup" button
                        RoundedRectangle(cornerRadius: 100)
                            .fill(BeansTheme.cremaBeige.opacity(0.1))
                            .frame(height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(BeansTheme.cremaBeige, lineWidth: 1)
                            )
                        
                        // Liquid fill
                        RoundedRectangle(cornerRadius: 100)
                            .fill(BeansTheme.accent)
                            .frame(height: 60)
                            .scaleEffect(y: liquidFill, anchor: .bottom)
                            .clipShape(RoundedRectangle(cornerRadius: 100))
                        
                        Text("Brew my first cup")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(liquidFill > 0.5 ? .white : BeansTheme.cremaBeige)
                            .padding()
                    }
                    .frame(width: 280)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                appear = true
            }
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
