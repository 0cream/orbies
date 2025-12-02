import Dependencies
import Foundation

// MARK: - Protocol

protocol EarnService: Actor {
    
    // MARK: - Setup
    
    func setup() async throws
    
    // MARK: - Staking Info
    
    /// Get all stake accounts for a wallet address
    /// Returns information about staked SOL including validators, amounts, and status
    func getStakeAccounts(walletAddress: String) async throws -> [StakeAccount]
    
    /// Get total staked balance for a wallet
    func getTotalStakedBalance(walletAddress: String) async throws -> Double
    
    /// Get staking summary with all relevant information
    func getStakingSummary(walletAddress: String) async throws -> StakingSummary
    
    // MARK: - Staking History
    
    /// Get historical staking rewards
    func getStakingRewards(walletAddress: String, limit: Int) async throws -> [StakingReward]
    
    // MARK: - Validators
    
    /// Get information about a specific validator
    func getValidatorInfo(validatorAddress: String) async throws -> ValidatorInfo
    
    /// Get list of recommended validators (Helius validator)
    func getRecommendedValidators() async -> [ValidatorInfo]
}

// MARK: - Live Implementation

actor LiveEarnService: EarnService {
    
    // MARK: - Dependencies
    
    @Dependency(\.heliusService)
    private var heliusService: HeliusService
    
    // MARK: - Constants
    
    // Helius validator address (6.59% APY)
    private let heliusValidatorAddress = "He1iusmfkpABUL8jxBbaJh1yr9yfKKdv2LuqPQkRmJfk"
    private let heliusValidatorName = "Helius"
    private let heliusValidatorAPY = 6.59
    private let heliusValidatorFee = 0.0
    
    // Stake program ID
    private let stakeProgramId = "Stake11111111111111111111111111111111111111"
    
    // MARK: - Setup
    
    func setup() async throws {
        print("💰 EarnService: Setup complete")
        print("   Default validator: \(heliusValidatorName)")
        print("   APY: \(heliusValidatorAPY)%")
    }
    
    // MARK: - Staking Info
    
    func getStakeAccounts(walletAddress: String) async throws -> [StakeAccount] {
        print("💰 EarnService: Fetching stake accounts for \(walletAddress)")
        
        // Get all accounts owned by wallet
        let response = try await heliusService.searchAssets(
            walletAddress: walletAddress,
            tokenType: "all",
            showZeroBalance: false
        )
        
        // Get stake accounts using getProgramAccounts equivalent
        // Note: Helius DAS API doesn't directly expose stake accounts, 
        // so we need to use RPC method getStakeActivation
        
        // For now, we'll use a different approach - get all accounts and filter for stake accounts
        let stakeAccounts = try await fetchStakeAccountsViaRPC(walletAddress: walletAddress)
        
        print("💰 EarnService: Found \(stakeAccounts.count) stake accounts")
        return stakeAccounts
    }
    
    func getTotalStakedBalance(walletAddress: String) async throws -> Double {
        let accounts = try await getStakeAccounts(walletAddress: walletAddress)
        let total = accounts.reduce(0.0) { $0 + $1.activeStake + $1.activatingStake }
        print("💰 EarnService: Total staked: \(total) SOL")
        return total
    }
    
    func getStakingSummary(walletAddress: String) async throws -> StakingSummary {
        print("💰 EarnService: Fetching staking summary for \(walletAddress)")
        
        let accounts = try await getStakeAccounts(walletAddress: walletAddress)
        
        let totalActive = accounts.reduce(0.0) { $0 + $1.activeStake }
        let totalActivating = accounts.reduce(0.0) { $0 + $1.activatingStake }
        let totalDeactivating = accounts.reduce(0.0) { $0 + $1.deactivatingStake }
        let totalInactive = accounts.reduce(0.0) { $0 + $1.inactiveStake }
        
        // Calculate estimated APY (weighted average based on validators)
        let estimatedAPY = accounts.isEmpty ? heliusValidatorAPY : calculateWeightedAPY(accounts: accounts)
        
        // Estimate yearly earnings based on active stake
        let estimatedYearlyEarnings = totalActive * (estimatedAPY / 100.0)
        
        let summary = StakingSummary(
            totalStaked: totalActive + totalActivating,
            activeStake: totalActive,
            activatingStake: totalActivating,
            deactivatingStake: totalDeactivating,
            inactiveStake: totalInactive,
            estimatedAPY: estimatedAPY,
            estimatedYearlyEarnings: estimatedYearlyEarnings,
            numberOfValidators: Set(accounts.map { $0.validatorAddress }).count,
            stakeAccounts: accounts
        )
        
        print("💰 EarnService: Summary - Total: \(summary.totalStaked) SOL, APY: \(summary.estimatedAPY)%")
        return summary
    }
    
    // MARK: - Staking History
    
    func getStakingRewards(walletAddress: String, limit: Int = 10) async throws -> [StakingReward] {
        print("💰 EarnService: Fetching staking rewards for \(walletAddress)")
        
        // Fetch transactions related to staking
        // Look for transactions with the stake program
        let transactions = try await heliusService.getEnhancedTransactions(
            address: walletAddress,
            before: nil,
            limit: limit,
            type: nil,
            source: nil
        )
        
        // Filter for stake-related transactions and extract rewards
        var rewards: [StakingReward] = []
        
        for tx in transactions {
            // Check if transaction involves stake program
            // Stake rewards are typically shown in account balance changes
            if let accountData = tx.accountData {
                for account in accountData {
                    if let tokenChanges = account.tokenBalanceChanges {
                        for change in tokenChanges {
                            // If there's a positive SOL balance change, it might be a reward
                            // This is a simplified approach - in production you'd want more sophisticated parsing
                            if let rawAmount = Double(change.rawTokenAmount.tokenAmount) {
                                let amount = rawAmount / 1_000_000_000 // Convert lamports to SOL
                                if amount > 0 {
                                    let reward = StakingReward(
                                        date: Date(timeIntervalSince1970: TimeInterval(tx.timestamp)),
                                        amount: amount,
                                        validator: "Unknown", // Would need to parse from transaction
                                        transactionSignature: tx.signature
                                    )
                                    rewards.append(reward)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        print("💰 EarnService: Found \(rewards.count) staking rewards")
        return rewards
    }
    
    // MARK: - Validators
    
    func getValidatorInfo(validatorAddress: String) async throws -> ValidatorInfo {
        // For now, return Helius validator if it matches, otherwise generic info
        if validatorAddress == heliusValidatorAddress {
            return ValidatorInfo(
                address: heliusValidatorAddress,
                name: heliusValidatorName,
                apy: heliusValidatorAPY,
                commission: heliusValidatorFee,
                totalStaked: 14_540_000, // Example: 14.54M SOL
                isActive: true,
                website: "https://helius.xyz"
            )
        }
        
        // For other validators, return generic info
        // In production, you'd query validator info from the network
        return ValidatorInfo(
            address: validatorAddress,
            name: "Validator \(validatorAddress.prefix(8))...",
            apy: 6.0,
            commission: 5.0,
            totalStaked: 0,
            isActive: true,
            website: nil
        )
    }
    
    func getRecommendedValidators() async -> [ValidatorInfo] {
        // Return Helius as primary and Liquid Staking as secondary
        return [
            ValidatorInfo(
                address: heliusValidatorAddress,
                name: heliusValidatorName,
                apy: heliusValidatorAPY,
                commission: heliusValidatorFee,
                totalStaked: 14_540_000,
                isActive: true,
                website: "https://helius.xyz"
            ),
            ValidatorInfo(
                address: "liquid_staking_pool",
                name: "Helius",
                apy: 6.32,
                commission: 0.0,
                totalStaked: 8_200_000,
                isActive: true,
                website: nil
            )
        ]
    }
    
    // MARK: - Private Helpers
    
    private func fetchStakeAccountsViaRPC(walletAddress: String) async throws -> [StakeAccount] {
        print("💰 EarnService: Fetching stake accounts via RPC for \(walletAddress)")
        
        // Use getProgramAccounts to find all stake accounts for this wallet
        let filters: [[String: Any]] = [
            [
                "memcmp": [
                    "offset": 12,
                    "bytes": walletAddress
                ]
            ]
        ]
        
        do {
            let response = try await heliusService.getProgramAccountsV2(
                programId: stakeProgramId,
                filters: filters,
                limit: 100
            )
            
            print("💰 EarnService: Found \(response.accounts.count) stake accounts")
            
            var stakeAccounts: [StakeAccount] = []
            
            // Get current epoch to determine activation status
            let epochInfo = try await heliusService.getEpochInfo()
            let currentEpoch = epochInfo.epoch
            
            for account in response.accounts {
                // Parse the stake info from jsonParsed data
                guard let stakeInfo = account.account.data.parsed.info.stake else {
                    print("⚠️ EarnService: Skipping account \(account.pubkey) - no stake info (uninitialized)")
                    continue
                }
                
                let delegation = stakeInfo.delegation
                let validatorAddress = delegation.voter
                
                // Convert stake amount from string to SOL
                guard let stakeLamports = Double(delegation.stake) else {
                    print("⚠️ EarnService: Invalid stake amount for account \(account.pubkey)")
                    continue
                }
                let totalStakeSol = stakeLamports / 1_000_000_000
                
                // Parse activation and deactivation epochs as strings first
                let activationEpochStr = delegation.activationEpoch
                let deactivationEpochStr = delegation.deactivationEpoch
                
                // Try to parse as Int, or use safe values for very large numbers
                let activationEpoch = Int(activationEpochStr) ?? 0
                
                // For deactivation epoch, check if it's the max u64 value (means never/not deactivating)
                // If string is very long or can't parse, assume it's "never"
                let deactivationEpoch: Int
                if deactivationEpochStr.count > 10 || Int(deactivationEpochStr) == nil {
                    // This is likely the max u64 value, meaning stake is not being deactivated
                    deactivationEpoch = Int.max
                } else {
                    deactivationEpoch = Int(deactivationEpochStr) ?? Int.max
                }
                
                print("💰 EarnService: Epochs - Activation: \(activationEpoch), Deactivation: \(deactivationEpoch == Int.max ? "never" : "\(deactivationEpoch)"), Current: \(currentEpoch)")
                
                // Determine status based on epochs
                let (status, activeStake, activatingStake, deactivatingStake, inactiveStake) = determineStakeStatus(
                    currentEpoch: currentEpoch,
                    activationEpoch: activationEpoch,
                    deactivationEpoch: deactivationEpoch,
                    totalStake: totalStakeSol
                )
                
                // Determine validator name and APY
                let isHeliusValidator = validatorAddress == heliusValidatorAddress || validatorAddress.contains("He1ius")
                let validatorName = isHeliusValidator ? heliusValidatorName : "Validator"
                let apy = isHeliusValidator ? heliusValidatorAPY : 6.0
                
                print("💰 EarnService: Stake account \(account.pubkey.prefix(8))... - Status: \(status), Total: \(totalStakeSol) SOL, Validator: \(validatorName), APY: \(apy)%")
                
                let stakeAccount = StakeAccount(
                    id: account.pubkey,
                    validatorAddress: validatorAddress,
                    validatorName: validatorName,
                    activeStake: activeStake,
                    activatingStake: activatingStake,
                    deactivatingStake: deactivatingStake,
                    inactiveStake: inactiveStake,
                    status: status,
                    estimatedAPY: apy
                )
                
                stakeAccounts.append(stakeAccount)
            }
            
            return stakeAccounts
            
        } catch {
            print("❌ EarnService: Failed to fetch stake accounts: \(error)")
            // Return empty array on error - user will see "No active stakes"
            return []
        }
    }
    
    private func determineStakeStatus(
        currentEpoch: Int,
        activationEpoch: Int,
        deactivationEpoch: Int,
        totalStake: Double
    ) -> (status: StakeStatus, active: Double, activating: Double, deactivating: Double, inactive: Double) {
        
        // Check if stake has been deactivated (deactivationEpoch == Int.max means never)
        if deactivationEpoch != Int.max && deactivationEpoch < 1_000_000_000 {
            if currentEpoch >= deactivationEpoch {
                // Fully deactivated
                return (.inactive, 0, 0, 0, totalStake)
            } else {
                // Currently deactivating
                return (.deactivating, 0, 0, totalStake, 0)
            }
        }
        
        // Check activation status (activationEpoch == Int.max or 0 means not activated)
        if activationEpoch > 0 && activationEpoch < 1_000_000_000 {
            // Stake is in process of activation or already active
            // Typically takes 1-2 epochs to fully activate
            let epochsSinceActivation = currentEpoch - activationEpoch
            
            if epochsSinceActivation >= 2 {
                // Fully activated (after warmup period)
                return (.active, totalStake, 0, 0, 0)
            } else {
                // Still activating (warmup period)
                return (.activating, 0, totalStake, 0, 0)
            }
        }
        
        // Not activated yet
        return (.inactive, 0, 0, 0, totalStake)
    }
    
    private func calculateWeightedAPY(accounts: [StakeAccount]) -> Double {
        let totalStake = accounts.reduce(0.0) { $0 + $1.activeStake }
        guard totalStake > 0 else { return heliusValidatorAPY }
        
        let weightedAPY = accounts.reduce(0.0) { sum, account in
            let weight = account.activeStake / totalStake
            return sum + (weight * account.estimatedAPY)
        }
        
        return weightedAPY
    }
}

// MARK: - Models

struct StakeAccount: Codable, Equatable, Identifiable {
    let id: String // Stake account address
    let validatorAddress: String
    let validatorName: String
    let activeStake: Double // SOL
    let activatingStake: Double // SOL being activated
    let deactivatingStake: Double // SOL being deactivated
    let inactiveStake: Double // SOL not yet active
    let status: StakeStatus
    let estimatedAPY: Double
    
    var totalStake: Double {
        activeStake + activatingStake + deactivatingStake + inactiveStake
    }
}

enum StakeStatus: String, Codable, Equatable {
    case active
    case activating
    case deactivating
    case inactive
}

struct StakingSummary: Equatable {
    let totalStaked: Double // Total SOL staked
    let activeStake: Double // Currently earning rewards
    let activatingStake: Double // Being activated (takes ~2 epochs)
    let deactivatingStake: Double // Being deactivated
    let inactiveStake: Double // Not earning rewards
    let estimatedAPY: Double // Weighted average APY
    let estimatedYearlyEarnings: Double // Estimated SOL earned per year
    let numberOfValidators: Int // Number of validators delegated to
    let stakeAccounts: [StakeAccount] // All stake accounts
}

struct StakingReward: Codable, Equatable, Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double // SOL
    let validator: String
    let transactionSignature: String
}

struct ValidatorInfo: Codable, Equatable, Identifiable {
    let address: String
    let name: String
    let apy: Double
    let commission: Double
    let totalStaked: Double // Total SOL staked with this validator
    let isActive: Bool
    let website: String?
    
    var id: String { address }
}

// MARK: - Errors

enum EarnServiceError: Error, LocalizedError {
    case notInitialized
    case invalidWalletAddress
    case noStakeAccounts
    case validatorNotFound
    case stakingDisabled
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Earn service not initialized. Call setup() first."
        case .invalidWalletAddress:
            return "Invalid wallet address provided"
        case .noStakeAccounts:
            return "No stake accounts found for this wallet"
        case .validatorNotFound:
            return "Validator not found"
        case .stakingDisabled:
            return "Staking is currently disabled"
        }
    }
}

// MARK: - Dependency

extension DependencyValues {
    var earnService: EarnService {
        get { self[EarnServiceKey.self] }
        set { self[EarnServiceKey.self] = newValue }
    }
}

private enum EarnServiceKey: DependencyKey {
    static let liveValue: EarnService = LiveEarnService()
    static let testValue: EarnService = { fatalError("EarnService not mocked for tests") }()
}

