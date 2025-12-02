import SwiftUI
import ComposableArchitecture
import Dependencies

@ViewAction(for: SplashFeature.self)
struct SplashView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<SplashFeature>
    @State private var heartbeatScale: CGFloat = 1.0
    @Dependency(\.hapticFeedbackGenerator) private var hapticFeedback
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.4),
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 100,
                            endRadius: 400
                        )
                    )
                    .frame(width: 800, height: 800)
                    .blur(radius: 50)
                
                // Glass circle with orange logo
                ZStack {
                    // Glass background with subtle tint
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                        }
                        .frame(width: 75, height: 75)
                    
                    // Subtle border
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 75, height: 75)
                    
                    // Orange logo
                    Image("orb_small_orange")
                .resizable()
                        .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                        .frame(width: 54, height: 54)
                }
                .shadow(color: Color.white.opacity(0.1), radius: 20, x: 0, y: 0)
                .scaleEffect(heartbeatScale)
            }
        }
        .task {
            // Heartbeat animation loop
            while !Task.isCancelled {
                // First beat (lub)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.1)) {
                        heartbeatScale = 1.05
                    }
                }
                await hapticFeedback.light(intensity: 0.5)
                try? await Task.sleep(for: .milliseconds(100))
                
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.1)) {
                        heartbeatScale = 1.0
                    }
                }
                try? await Task.sleep(for: .milliseconds(150))
                
                // Second beat (dub)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.1)) {
                        heartbeatScale = 1.03
                    }
                }
                await hapticFeedback.light(intensity: 0.4)
                try? await Task.sleep(for: .milliseconds(100))
                
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.1)) {
                        heartbeatScale = 1.0
                    }
                }
                
                // Pause before next cycle
                try? await Task.sleep(for: .milliseconds(800))
            }
        }
        .onAppear {
            send(.onAppear)
        }
    }
} 
