import SwiftUI
import ComposableArchitecture
import SFSafeSymbols

@ViewAction(for: WalletImportFeature.self)
struct WalletImportView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<WalletImportFeature>
    
    // MARK: - UI
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            NavigationBarView(
                configuration: NavigationBarConfiguration(
                    title: "Restore backup",
                    subtitle: nil,
                    showTrailingButton: false
                ),
                action: { action in
                    switch action {
                    case .didTapLeading:
                        send(.didTapBack)
                    case .didTapTrailing:
                        break
                    }
                }
            )
            .padding(.top, 8)
            
            Spacer()
            
            // Centered text input area
            VStack(spacing: 16) {
                // Secure text input (password field with dots)
                SecureField(
                    "Your private key",
                    text: Binding(
                        get: { store.privateKey },
                        set: { send(.privateKeyChanged($0)) }
                    )
                )
                .font(.system(size: 17, weight: .medium))
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disabled(store.isImporting)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                
                // Error Message
                if let errorMessage = store.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemSymbol: .exclamationmarkTriangleFill)
                            .foregroundStyle(.red)
                        
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
            
            // Paste button (shown when empty) OR Next button (shown when not empty)
            if store.privateKey.isEmpty {
                // Paste button (white background, black text)
                Button {
                    if let clipboardString = UIPasteboard.general.string {
                        send(.privateKeyChanged(clipboardString))
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemSymbol: .squareOnSquare)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Paste")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            } else {
                // Next Button (white background, black text)
                Button {
                    send(.didTapNext)
                } label: {
                    HStack {
                        if store.isImporting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.black)
                        } else {
                            Text("Next")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(.black)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(store.isImporting)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .onAppear {
            send(.didAppear)
        }
    }
}

#Preview {
    WalletImportView(
        store: Store(
            initialState: WalletImportFeature.State()
        ) {
            WalletImportFeature()
        }
    )
}

