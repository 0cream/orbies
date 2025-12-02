import Foundation

/// A processed transaction with clean, ready-to-display data
struct ProcessedTransaction: Identifiable, Sendable {
    let id: String
    let signature: String
    let type: String
    let source: String
    let date: Date
    let description: String?
    
    // Amounts
    let receivedAmount: TokenAmount?
    let spentAmount: TokenAmount?
    
    // Original transaction for details
    let originalTransaction: HeliusEnhancedTransaction
    
    struct TokenAmount: Sendable {
        let value: Double
        let symbol: String
        let mint: String
        let iconURL: String?  // Jupiter token icon URL
        
        var formatted: String {
            let decimals = value < 1 ? 6 : (value < 10 ? 4 : 0)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = decimals
            formatter.groupingSeparator = ","
            let amountStr = formatter.string(from: NSNumber(value: value)) ?? "0"
            return "\(amountStr) \(symbol)"
        }
    }
}

// MARK: - Transaction Processor

enum TransactionProcessor {
    
    /// Process a transaction to extract clean display data
    static func process(_ transaction: HeliusEnhancedTransaction, jupiterService: JupiterService) async -> ProcessedTransaction {
        let (received, spent) = await extractAmounts(from: transaction, jupiterService: jupiterService)
        
        return ProcessedTransaction(
            id: transaction.signature,
            signature: transaction.signature,
            type: transaction.type,
            source: transaction.source,
            date: transaction.date,
            description: transaction.description,
            receivedAmount: received,
            spentAmount: spent,
            originalTransaction: transaction
        )
    }
    
    /// Extract received and spent amounts from a transaction
    private static func extractAmounts(
        from transaction: HeliusEnhancedTransaction,
        jupiterService: JupiterService
    ) async -> (received: ProcessedTransaction.TokenAmount?, spent: ProcessedTransaction.TokenAmount?) {
        
        let userAccount = transaction.feePayer
        var received: ProcessedTransaction.TokenAmount?
        var spent: ProcessedTransaction.TokenAmount?
        
        // 1. Try events.swap first (cleanest data for swaps)
        if let swapEvent = transaction.events?.swap {
            // Received amount
            if let output = swapEvent.tokenOutputs?.first {
                let amount = Double(output.rawTokenAmount.tokenAmount) ?? 0
                let value = amount / pow(10, Double(output.rawTokenAmount.decimals))
                let symbol = getTokenSymbol(output.mint)
                let iconURL = await jupiterService.getTokenIcon(mint: output.mint)
                received = ProcessedTransaction.TokenAmount(value: value, symbol: symbol, mint: output.mint, iconURL: iconURL)
            } else if let nativeOutput = swapEvent.nativeOutput {
                let value = nativeOutput.amountDouble / 1_000_000_000
                let solMint = "So11111111111111111111111111111111111111112"
                let iconURL = await jupiterService.getTokenIcon(mint: solMint)
                received = ProcessedTransaction.TokenAmount(
                    value: value,
                    symbol: "SOL",
                    mint: solMint,
                    iconURL: iconURL
                )
            }
            
            // Spent amount
            if let input = swapEvent.tokenInputs?.first {
                let amount = Double(input.rawTokenAmount.tokenAmount) ?? 0
                let value = amount / pow(10, Double(input.rawTokenAmount.decimals))
                let symbol = getTokenSymbol(input.mint)
                let iconURL = await jupiterService.getTokenIcon(mint: input.mint)
                spent = ProcessedTransaction.TokenAmount(value: value, symbol: symbol, mint: input.mint, iconURL: iconURL)
            } else if let nativeInput = swapEvent.nativeInput {
                let value = nativeInput.amountDouble / 1_000_000_000
                let solMint = "So11111111111111111111111111111111111111112"
                let iconURL = await jupiterService.getTokenIcon(mint: solMint)
                spent = ProcessedTransaction.TokenAmount(
                    value: value,
                    symbol: "SOL",
                    mint: solMint,
                    iconURL: iconURL
                )
            }
        }
        
        // 2. Try tokenTransfers/nativeTransfers for simple transfers
        // Skip this for SWAP transactions as they need both amounts
        if received == nil && spent == nil && !transaction.type.uppercased().contains("SWAP") {
            if let tokenTransfer = transaction.tokenTransfers?.first {
                let symbol = getTokenSymbol(tokenTransfer.mint)
                let isOutgoing = transaction.feePayer == tokenTransfer.fromUserAccount
                let iconURL = await jupiterService.getTokenIcon(mint: tokenTransfer.mint)
                
                if isOutgoing {
                    spent = ProcessedTransaction.TokenAmount(
                        value: tokenTransfer.tokenAmount,
                        symbol: symbol,
                        mint: tokenTransfer.mint,
                        iconURL: iconURL
                    )
                } else {
                    received = ProcessedTransaction.TokenAmount(
                        value: tokenTransfer.tokenAmount,
                        symbol: symbol,
                        mint: tokenTransfer.mint,
                        iconURL: iconURL
                    )
                }
            } else if let nativeTransfer = transaction.nativeTransfers?.first {
                let isOutgoing = transaction.feePayer == nativeTransfer.fromUserAccount
                let solMint = "So11111111111111111111111111111111111111112"
                let iconURL = await jupiterService.getTokenIcon(mint: solMint)
                
                if isOutgoing {
                    spent = ProcessedTransaction.TokenAmount(
                        value: nativeTransfer.amountInSOL,
                        symbol: "SOL",
                        mint: solMint,
                        iconURL: iconURL
                    )
                } else {
                    received = ProcessedTransaction.TokenAmount(
                        value: nativeTransfer.amountInSOL,
                        symbol: "SOL",
                        mint: solMint,
                        iconURL: iconURL
                    )
                }
            }
        }
        
        // 3. Fallback to accountData for complex transactions
        if received == nil && spent == nil, let accountData = transaction.accountData {
            for account in accountData {
                // Check token balance changes
                if let changes = account.tokenBalanceChanges {
                    for change in changes {
                        guard change.userAccount == userAccount else { continue }
                        
                        let amount = Double(change.rawTokenAmount.tokenAmount) ?? 0
                        let value = amount / pow(10, Double(change.rawTokenAmount.decimals))
                        let symbol = getTokenSymbol(change.mint)
                        let iconURL = await jupiterService.getTokenIcon(mint: change.mint)
                        
                        if value > 0 {
                            received = ProcessedTransaction.TokenAmount(value: value, symbol: symbol, mint: change.mint, iconURL: iconURL)
                        } else if value < 0 {
                            spent = ProcessedTransaction.TokenAmount(value: abs(value), symbol: symbol, mint: change.mint, iconURL: iconURL)
                        }
                    }
                }
                
                // Check native (SOL) balance changes for user's account
                if account.account == userAccount {
                    let nativeChange = Double(account.nativeBalanceChange)
                    // Exclude small amounts (likely just rent/fees)
                    if abs(nativeChange) > 10_000_000 { // > 0.01 SOL
                        let solAmount = abs(nativeChange) / 1_000_000_000
                        let solMint = "So11111111111111111111111111111111111111112"
                        let iconURL = await jupiterService.getTokenIcon(mint: solMint)
                        
                        if nativeChange > 0 {
                            received = ProcessedTransaction.TokenAmount(
                                value: solAmount,
                                symbol: "SOL",
                                mint: solMint,
                                iconURL: iconURL
                            )
                        } else if nativeChange < 0 {
                            spent = ProcessedTransaction.TokenAmount(
                                value: solAmount,
                                symbol: "SOL",
                                mint: solMint,
                                iconURL: iconURL
                            )
                        }
                    }
                }
            }
        }
        
        return (received, spent)
    }
    
    private static func getTokenSymbol(_ mint: String) -> String {
        switch mint {
        case "So11111111111111111111111111111111111111112":
            return "SOL"
        case "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v":
            return "USDC"
        case "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB":
            return "USDT"
        case "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN":
            return "JUP"
        case "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263":
            return "BONK"
        default:
            return mint.prefix(4).uppercased()
        }
    }
}

