import SwiftUI

struct GlassContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(40)
            .background(
                ZStack {
                    // 🌫️ Frosted glass material background
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.white)
                        .opacity(0.1) // makes it a bit more visible
                    
                    // ✨ Gradient border for subtle glow
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    // Add subtle border colors if desired
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: Color.white.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ZStack {
        // Background with gradient
        LinearGradient(
            colors: [
                Color(red: 0.3, green: 0.4, blue: 1),
                Color(red: 0.6, green: 0.3, blue: 0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        GlassContainer {
            VStack(spacing: 20) {
                Text("this is a liquid glass container")
                    .font(.custom("DMSans-ExtraLight", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("it matches the style of your glass buttons")
                    .font(.custom("DMSans-ExtraLight", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 30)
    }
}
