import ComposableArchitecture
import Dependencies
import UIKit

@Reducer
struct WalletReceiveFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.walletService)
    private var walletService: WalletService
    
    @Dependency(\.qrCodeService)
    private var qrCodeService: QRCodeService
    
    @Dependency(\.hapticFeedbackGenerator)
    private var hapticFeedbackGenerator: HapticFeedbackGenerator
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case let .reducer(action):
                return reduce(state: &state, action: action)
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - View Reducer
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didAppear:
            return .send(.reducer(.loadWalletAddress))
            
        case .didTapClose:
            return .send(.delegate(.didClose))
            
        case .didTapCopy:
            UIPasteboard.general.string = state.walletAddress
            return .run { _ in
                await hapticFeedbackGenerator.success()
            }
            
        case .didTapShare:
            // Share will be handled in View via UIActivityViewController
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 1.0)
            }
        }
    }
    
    // MARK: - Reducer
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case .loadWalletAddress:
            return .run { send in
                do {
                    let address = try await walletService.getPublicKey()
                    
                    // Load orb logo for QR code center
                    let logo = UIImage(named: "orb_small_orange")
                    
                    // Generate QR code
                    let qrImage = qrCodeService.generateCode(for: address, logo: logo)
                    
                    await send(.reducer(.walletAddressLoaded(address, qrImage)))
                } catch {
                    print("❌ Failed to load wallet address: \(error)")
                }
            }
            
        case let .walletAddressLoaded(address, qrImage):
            state.walletAddress = address
            state.qrCodeImage = qrImage
            state.isLoading = false
            return .none
        }
    }
}

