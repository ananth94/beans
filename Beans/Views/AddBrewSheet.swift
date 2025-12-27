import SwiftUI
import SwiftData

struct AddBrewSheet: View {
    @Binding var isPresented: Bool
    @Binding var urlString: String
    var onBrew: () -> Void
    
    var body: some View {
        ZStack {
            BeansTheme.background.ignoresSafeArea()
            VStack(spacing: 30) {
                Text("Add New Brew")
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(BeansTheme.primaryText)
                
                TextField("", text: $urlString, prompt: Text("https://...").foregroundColor(BeansTheme.cremaBeige.opacity(0.5)))
                    .padding()
                    .background(BeansTheme.cardBackground)
                    .cornerRadius(12)
                    .foregroundColor(BeansTheme.primaryText)
                    .tint(BeansTheme.accent)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BeansTheme.cremaBeige.opacity(0.2), lineWidth: 1)
                    )
                
                HStack(spacing: 20) {
                    Button {
                        isPresented = false
                        urlString = ""
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .foregroundColor(BeansTheme.secondaryText)
                    
                    Button {
                        onBrew()
                        isPresented = false
                    } label: {
                        Text("Brew")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(BeansTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(30)
        }
        .presentationDetents([.medium])
    }
}
