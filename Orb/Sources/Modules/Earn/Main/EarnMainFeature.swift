import ComposableArchitecture
import Dependencies
import Foundation

@Reducer
struct EarnMainFeature {
    
    @Dependency(\.earnService) var earnService
    @Dependency(\.userService) var userService
    @Dependency(\.walletService) var walletService
    @Dependency(\.hapticFeedbackGenerator) var hapticFeedback
    
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
    
    // MARK: - View Actions
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didAppear:
            guard !state.hasLoadedInitialData else { return .none }
            
            state.hasLoadedInitialData = true
            return .merge(
                .send(.reducer(.loadStakingInfo)),
                .send(.reducer(.loadAvailableBalance)),
                .send(.reducer(.loadStakingProducts))
            )
            
        case .didTapClose:
            return .merge(
                .run { _ in await hapticFeedback.light(intensity: 1.0) },
                .send(.delegate(.didRequestClose))
            )
            
        case .didTapDeposit:
            return .run { _ in
                await hapticFeedback.medium(intensity: 1.0)
                // TODO: Navigate to deposit/stake flow
            }
            
        case .didTapWithdraw:
            return .run { _ in
                await hapticFeedback.medium(intensity: 1.0)
                // TODO: Navigate to withdraw/unstake flow
            }
            
        case let .didTapStakingProduct(product):
            return .run { _ in
                await hapticFeedback.light(intensity: 1.0)
                // TODO: Navigate to staking product details
                print("💰 Tapped staking product: \(product.name)")
            }
            
        case let .didTapActiveStake(stake):
            return .run { _ in
                await hapticFeedback.light(intensity: 1.0)
                // TODO: Navigate to stake details
                print("💰 Tapped active stake: \(stake.validatorName)")
            }
        }
    }
    
    // MARK: - Reducer Actions
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case .loadStakingInfo:
            state.isLoadingStakingInfo = true
            
            return .run { send in
                do {
                    // Get wallet address
                    let walletAddress = try await walletService.getPublicKey()
                    
                    guard !walletAddress.isEmpty else {
                        await send(.reducer(.loadingFailed("No wallet address found")))
                        return
                    }
                    
                    print("💰 EarnMainFeature: Loading staking info for wallet: \(walletAddress)")
                    
                    // Fetch staking summary and SOL price
                    let summary = try await earnService.getStakingSummary(walletAddress: walletAddress)
                    let solPrice = await userService.getCurrentPrice(for: "So11111111111111111111111111111111111111112")
                    
                    await send(.reducer(.stakingInfoLoaded(summary: summary, solPrice: solPrice)))
                } catch {
                    print("❌ EarnMainFeature: Failed to load staking info: \(error)")
                    await send(.reducer(.loadingFailed(error.localizedDescription)))
                }
            }
            
        case let .stakingInfoLoaded(summary, solPrice):
            state.isLoadingStakingInfo = false
            
            state.validatorStakedUSD = summary.totalStaked * solPrice // Convert to USD
            state.activeStake = summary.activeStake
            state.activatingStake = summary.activatingStake
            state.deactivatingStake = summary.deactivatingStake
            state.estimatedAPY = summary.estimatedAPY
            state.estimatedYearlyEarnings = summary.estimatedYearlyEarnings
            
            // Convert stake accounts to active stakes with USD values
            state.activeValidators = summary.stakeAccounts.map { account in
                ActiveStake(
                    id: account.id,
                    validatorName: account.validatorName,
                    validatorAddress: account.validatorAddress,
                    amount: account.totalStake,
                    status: account.status,
                    apy: account.estimatedAPY,
                    valueUSD: account.totalStake * solPrice
                )
            }
            
            print("💰 EarnMainFeature: Loaded staking info - Validator staked: \(summary.totalStaked) SOL ($\(state.validatorStakedUSD))")
            print("💰 EarnMainFeature: Total balance: $\(state.totalStaked)")
            return .none
            
        case .loadAvailableBalance:
            return .run { [userService] send in
                // Get SOL balance
                let balance = await userService.getSolanaBalance()
                await send(.reducer(.availableBalanceLoaded(balance.SOL)))
                
                // Get hSOL balance (mint: he1iusmfkpAdwvxLNGV8Y1iSbj4rUy6yMhEA3fotn9A)
                let hsolMint = "he1iusmfkpAdwvxLNGV8Y1iSbj4rUy6yMhEA3fotn9A"
                let hsolToken = await userService.getTokenBalance(tokenId: hsolMint)
                let hsolAmount = Double(hsolToken.value) / Double(Token.fractional.precision)
                
                // Get hSOL token holdings to extract image URL
                let holdings = await userService.getTokenHoldings()
                let hsolHolding = holdings.first { $0.address == hsolMint }
                let imageURL = hsolHolding?.imageURL
                
                // Get hSOL price from UserService (which fetches from Helius)
                let hsolPrice = await userService.getCurrentPrice(for: hsolMint)
                let hsolValueUSD = hsolAmount * hsolPrice
                
                print("💰 EarnMainFeature: hSOL amount=\(hsolAmount), price=$\(hsolPrice), value=$\(hsolValueUSD)")
                
                await send(.reducer(.hsolBalanceLoaded(amount: hsolAmount, valueUSD: hsolValueUSD, imageURL: imageURL)))
            }
            
        case let .availableBalanceLoaded(balance):
            state.availableBalance = balance
            print("💰 EarnMainFeature: Available balance: \(balance) SOL")
            return .none
            
        case let .hsolBalanceLoaded(amount, valueUSD, imageURL):
            state.hsolBalance = amount
            state.hsolValueUSD = valueUSD
            state.hsolImageURL = imageURL
            
            print("💰 EarnMainFeature: hSOL balance: \(amount) hSOL ($\(valueUSD))")
            print("💰 EarnMainFeature: Total balance: $\(state.totalStaked)")
            return .none
            
        case .loadStakingProducts:
            state.isLoadingProducts = true
            
            return .run { send in
                // Get recommended validators
                let validators = await earnService.getRecommendedValidators()
                
                let products = validators.enumerated().map { index, validator in
                    StakingProduct(
                        id: validator.address,
                        name: validator.name,
                        apy: validator.apy,
                        description: index == 0 
                            ? "Deposit your SOL with \(validator.name) to earn yield from optimized staking vaults."
                            : "Swap SOL for hSOL to earn staking rewards while maintaining liquidity.",
                        validatorAddress: validator.address,
                        logoName: nil, // TODO: Add logo asset
                        commission: validator.commission,
                        totalStaked: validator.totalStaked,
                        productType: index == 0 ? .staking : .liquidStaking
                    )
                }
                
                await send(.reducer(.stakingProductsLoaded(products)))
            }
            
        case let .stakingProductsLoaded(products):
            state.isLoadingProducts = false
            state.recommendedValidators = products
            print("💰 EarnMainFeature: Loaded \(products.count) staking products")
            return .none
            
        case let .loadingFailed(error):
            state.isLoadingStakingInfo = false
            state.isLoadingProducts = false
            state.errorMessage = error
            print("❌ EarnMainFeature: Loading failed - \(error)")
            return .none
        }
    }
}

