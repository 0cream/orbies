import ComposableArchitecture

@Reducer
struct ExploreCoordinator {
    var body: some ReducerOf<Self> {
        Scope(state: \.main, action: \.main) {
            ExploreMainFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .main(.delegate(.didRequestTokenDetails(let jupiterToken))):
                // Map JupiterVerifiedToken to TokenItem with real data
                let volume24h: Double? = {
                    if let buyVol = jupiterToken.stats24h?.buyVolume,
                       let sellVol = jupiterToken.stats24h?.sellVolume {
                        return buyVol + sellVol
                    }
                    return nil
                }()
                
                let tokenItem = TokenItem(
                    id: jupiterToken.id,
                    name: jupiterToken.name,
                    ticker: jupiterToken.symbol,
                    imageName: jupiterToken.icon ?? "", // Will use TokenImageView instead
                    decimals: jupiterToken.decimals,
                    price: jupiterToken.usdPrice ?? 0.0,
                    priceChange: jupiterToken.stats24h?.priceChange ?? 0.0,
                    marketCap: jupiterToken.mcap,
                    liquidity: jupiterToken.liquidity,
                    volume24h: volume24h
                )
                
                state.path.append(.tokenDetails(TokenDetailsCoordinator.State(
                    root: TokenDetailsFeature.State(token: tokenItem)
                )))
                return .none
                
            case .path(.element(_, .tokenDetails(.delegate(.didFinish)))):
                state.path.removeLast()
                return .none
                
            case .path:
                return .none
                
            case .main:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

