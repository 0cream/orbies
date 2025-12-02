import ComposableArchitecture

extension EarnMainFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didTapClose
            case didTapDeposit
            case didTapWithdraw
            case didTapStakingProduct(StakingProduct)
            case didTapActiveStake(ActiveStake)
        }
        
        enum Reducer {
            case loadStakingInfo
            case stakingInfoLoaded(summary: StakingSummary, solPrice: Double)
            case loadAvailableBalance
            case availableBalanceLoaded(Double)
            case hsolBalanceLoaded(amount: Double, valueUSD: Double, imageURL: String?)
            case loadStakingProducts
            case stakingProductsLoaded([StakingProduct])
            case loadingFailed(String)
        }
        
        enum Delegate {
            case didRequestClose
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
}

