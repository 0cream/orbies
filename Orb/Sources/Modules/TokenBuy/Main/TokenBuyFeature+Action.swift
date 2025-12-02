import Foundation

extension TokenBuyFeature {
    enum Action {
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
        
        enum View {
            case onAppear
            case didChangeValue(String)
            case didTapToolbarSecondaryButton
            case didTapToolbarItem(id: String)
            case didTapActionButton
        }
        
        enum Reducer {
            case didUpdateBalance(Usdc)
            case didUpdateFee(FeeAmount)
            case didUpdateTokenReserves(TokenReserves?)
            case didUpdateSwapQuote(Result<JupiterUltraOrder, Error>)
            case refreshQuoteTimerTick
            case didSendTransaction(Result<String, Error>)
            case checkTransactionStatus
            case didUpdateTransactionStatus(Result<HeliusSignatureStatus?, Error>)
        }
        
        enum Delegate {
            case didRequestPurchase(
                tokenName: String,
                tokensAmount: Token,
                tokensAmountWithFee: Token,
                usdcAmount: Usdc,
                usdAmount: Usd,
                fee: Usdc
            )
            case didRequestTopUp(amount: Usdc?)
            case didFinish(tokenAmount: Double, tokenTicker: String)
            case didFail(error: String)
        }
    }
}

