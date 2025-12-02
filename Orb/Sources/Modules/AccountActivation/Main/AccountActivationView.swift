import SwiftUI
import ComposableArchitecture
import SFSafeSymbols

@ViewAction(for: AccountActivationFeature.self)
struct AccountActivationView: View {
    let store: StoreOf<AccountActivationFeature>
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Content (message, privacy text)
            VStack(spacing: 0) {
                Spacer()
                
                // Card with success message
                VStack(spacing: 0) {
                    // Animated toggle
                    AccountActivationToggle(isOn: !store.isActivating)
                    
                    // Title
                    Text(store.isActivating ? "Activating account" : "Account activated")
                        .font(.system(size: 27, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                    
                    // Subtitle
                    Text("Your wallet has been created. Now we're preparing the app and tailoring the experience for you.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .padding(32)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Privacy text
                VStack(spacing: 4) {
                    Image(systemSymbol: .lockFill)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    Text("Orb is storing your private keys in\nsecure storage. They can not be\naccessed outside the app.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 58)
                .padding(.bottom, 110)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            send(.didAppear)
        }
    }
}

