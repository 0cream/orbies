import Foundation

extension TokenSellFeature {
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
            case didUpdateTokenBalance(Token)
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
            case didRequestSell(
                tokenName: String,
                tokensAmount: Token,
                usdcAmount: Usdc,
                usdAmount: Usd,
                fee: Usdc
            )
            case didFinish(usdcAmount: Double, tokenTicker: String)
            case didFail(error: String)
        }
    }
}

