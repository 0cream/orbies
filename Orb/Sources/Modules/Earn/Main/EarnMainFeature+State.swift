import ComposableArchitecture
import Foundation

extension EarnMainFeature {
    @ObservableState
    struct State: Equatable {
        // Balance
        var availableBalance: Double = 0.0 // Available SOL to stake
        var validatorStakedUSD: Double = 0.0 // USD value of validator staking
        var activeStake: Double = 0.0
        var activatingStake: Double = 0.0
        var deactivatingStake: Double = 0.0
        var hsolBalance: Double = 0.0 // hSOL token balance
        var hsolValueUSD: Double = 0.0 // USD value of hSOL
        var hsolImageURL: String? = nil // hSOL token image URL
        
        // Computed total staked (validator + hSOL)
        var totalStaked: Double {
            validatorStakedUSD + hsolValueUSD
        }
        
        // Earnings
        var lifetimeEarned: Double = 0.0
        var last7DaysEarned: Double = 0.0
        var estimatedAPY: Double = 6.59 // Default Helius APY
        var estimatedYearlyEarnings: Double = 0.0
        
        // Validators
        var recommendedValidators: [StakingProduct] = []
        var activeValidators: [ActiveStake] = []
        
        // Loading states
        var isLoadingStakingInfo: Bool = false
        var isLoadingProducts: Bool = false
        var hasLoadedInitialData: Bool = false
        
        // Error
        var errorMessage: String?
        
        // Computed properties
        var totalBalance: Double {
            availableBalance + totalStaked
        }
        
        var availableBalanceFormatted: String {
            String(format: "%.4f", availableBalance)
        }
        
        var totalStakedFormatted: String {
            String(format: "%.2f", totalStaked)
        }
        
        var lifetimeEarnedFormatted: String {
            String(format: "%.2f", lifetimeEarned)
        }
        
        var last7DaysEarnedFormatted: String {
            String(format: "%.2f", last7DaysEarned)
        }
        
        var estimatedAPYFormatted: String {
            String(format: "%.2f%%", estimatedAPY)
        }
    }
}

// MARK: - Models

enum StakingProductType: String, Equatable {
    case staking = "Staking"
    case liquidStaking = "Liquid Staking"
}

struct StakingProduct: Equatable, Identifiable {
    let id: String // Validator address
    let name: String
    let apy: Double
    let description: String
    let validatorAddress: String
    let logoName: String? // Asset name for logo
    let commission: Double
    let totalStaked: Double
    let productType: StakingProductType
    
    var apyFormatted: String {
        String(format: "%.2f%% APY", apy)
    }
    
    var productTypeTitle: String {
        productType.rawValue
    }
}

struct ActiveStake: Equatable, Identifiable {
    let id: String // Stake account address
    let validatorName: String
    let validatorAddress: String
    let amount: Double
    let status: StakeStatus
    let apy: Double
    let valueUSD: Double
    
    var amountFormatted: String {
        String(format: "%.4f SOL", amount)
    }
    
    var statusText: String {
        switch status {
        case .active:
            return "Active"
        case .activating:
            return "Activating"
        case .deactivating:
            return "Deactivating"
        case .inactive:
            return "Inactive"
        }
    }
    
    var statusColor: String {
        switch status {
        case .active:
            return "green"
        case .activating:
            return "orange"
        case .deactivating:
            return "orange"
        case .inactive:
            return "gray"
        }
    }
}

