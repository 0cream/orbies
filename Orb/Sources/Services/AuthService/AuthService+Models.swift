enum AuthProvider: String, Sendable, Equatable {
    case email
}

enum AuthState: Sendable {
    case authenticated
    case notReady
    case authenticatedUnverified
    case unauthenticated
}

struct User: Sendable, Equatable {
    let id: String
    let wallets: [UserWallet]
    let createdAt: Date?
}

struct UserWallet: Sendable, Equatable {
    let address: String
    let network: BlockchainNetwork
}

enum BlockchainNetwork: Sendable, Equatable {
    case solana
}

// MARK: - Helpers

import PrivySDK

extension PrivySDK.AuthState {
    var asLocalAuthState: AuthState  {
        get throws {
            switch self {
            case .authenticated:
                return .authenticated
            case .notReady:
                return .notReady
            case .authenticatedUnverified:
                return .authenticatedUnverified
            case .unauthenticated:
                return .unauthenticated
            @unknown default:
                throw AppError(message: "Unsupported Privy auth state: \(self)")
            }
        }
    }
}
