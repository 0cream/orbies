import ComposableArchitecture
import CoreGraphics
import Foundation

extension WalletReceiveFeature {
    @ObservableState
    struct State: Equatable {
        var walletAddress: String = ""
        var qrCodeImage: CGImage?
        var isLoading: Bool = true
    }
}

