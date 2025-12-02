import SwiftUI
import ComposableArchitecture
import AuthenticationServices
import SFSafeSymbols

@ViewAction(for: AuthMainFeature.self)
struct AuthMainView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<AuthMainFeature>
    
    // Animated gradient state
    @State private var glowOffset1: CGFloat = 0
    @State private var glowOffset2: CGFloat = 0
    @State private var glowOffset3: CGFloat = 0
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Blurred orange gradient dots (animated)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.3),
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 40)
                    .position(x: geometry.size.width * 0.2 + glowOffset1, y: geometry.size.height * 0.3)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.3),
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 40)
                    .position(x: geometry.size.width * 0.7 + glowOffset2, y: geometry.size.height * 0.5)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.3),
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 40)
                    .position(x: geometry.size.width * 0.4 + glowOffset3, y: geometry.size.height * 0.7)
                
                // Content on top
                VStack(spacing: 0) {
                    // Orb text at top
                    Text("orb")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 80)
                    
                    Spacer()
                    
                    // Center orb logo
                    Image("orb_small_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                    
                    Spacer()
                    
                    // Auth Buttons
                    VStack(spacing: 12) {
                        // Continue with Email (white background, black text)
                        Button {
                            send(.didTapContinueWithEmail)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemSymbol: .envelopeFill)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.black)
                                
                                Text("Continue with email")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.black)
                            }
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // I have private key (no background, white text)
                        Button {
                            send(.didTapPrivateKey)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemSymbol: .keyViewfinder)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Text("I have private key")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Terms text
                    Text("By signing up, you agree to our\nTerms of Service and Privacy Policy.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startGlowAnimation()
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            glowOffset1 = 100
        }
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            glowOffset2 = -80
        }
        withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
            glowOffset3 = 120
        }
    }
} 
