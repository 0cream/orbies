import SwiftUI
import ComposableArchitecture

@ViewAction(for: WalletReceiveFeature.self)
struct WalletReceiveView: View {
    
    let store: StoreOf<WalletReceiveFeature>
    @State private var showShareSheet = false
    
    var maskedAddress: String {
        let address = store.walletAddress
        guard address.count > 8 else { return address }
        return "\(address.prefix(4))...\(address.suffix(4))".uppercased()
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .frame(width: 60, height: 8)
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                
                // Title
                Text("Receive")
                    .foregroundColor(.white)
                    .font(.system(size: 27, weight: .bold))
                
                // Address with copy button
                Button {
                    send(.didTapCopy)
                } label: {
                    HStack(spacing: 8) {
                        Text(maskedAddress)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // QR Code
                if let qrImage = store.qrCodeImage {
                    Image(uiImage: UIImage(cgImage: qrImage))
                        .resizable()
                        .interpolation(.none)
                        .padding(10)
                        .frame(width: 240, height: 240)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 42))
                        .overlay(
                            RoundedRectangle(cornerRadius: 42)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                } else if store.isLoading {
                    // Loading state
                    RoundedRectangle(cornerRadius: 42)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 240, height: 240)
                        .shimmer()
                }
                
                Spacer()
                
                // Share button
                Button {
                    showShareSheet = true
                    send(.didTapShare)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .regular))
                        
                        Text("Share Address")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .sheet(isPresented: $showShareSheet) {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        ActivityViewController(activityItems: [store.walletAddress])
                            .presentationDetents([.medium])
                    }
                }
                
                // Description
                VStack(spacing: 12) {
                    Image("orb_small_orange")
                        .resizable()
                        .frame(width: 36, height: 36)
                    
                    Text("Share this address to receive any assets on Solana")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 18, weight: .regular))
                }
                .padding(.horizontal, 72)
                .padding(.bottom, 32)
                .padding(.top, 32)
            }
        }
        .onAppear {
            send(.didAppear)
        }
    }
}

// MARK: - Activity View Controller

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

