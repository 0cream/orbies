import Foundation
import SolanaSwift

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
    
    /// Determines if this is actually a swap based on the amounts
    /// Returns true if we have both received and spent amounts with different tokens
    var isSwap: Bool {
        guard let received = receivedAmount,
              let spent = spentAmount else {
            return false
        }
        // It's a swap if the tokens are different
        return received.mint != spent.mint
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
    
    /// Get expected token account address for a given wallet and mint
    private static func getExpectedTokenAccount(wallet: String, mint: String) -> String? {
        do {
            let walletPublicKey = try PublicKey(string: wallet)
            let mintPublicKey = try PublicKey(string: mint)
            let tokenAccount = try PublicKey.associatedTokenAddress(
                walletAddress: walletPublicKey,
                tokenMintAddress: mintPublicKey,
                tokenProgramId: TokenProgram.id
            )
            return tokenAccount.base58EncodedString
        } catch {
            print("❌ Failed to derive token account for wallet: \(wallet), mint: \(mint)")
            return nil
        }
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
                let symbol = await getTokenSymbol(output.mint, jupiterService: jupiterService)
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
                let symbol = await getTokenSymbol(input.mint, jupiterService: jupiterService)
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
        // Skip for SWAP transactions or multiple token transfers (likely swaps even if not labeled)
        let hasMultipleTokenTransfers = (transaction.tokenTransfers?.count ?? 0) > 1
        if received == nil && spent == nil && !transaction.type.uppercased().contains("SWAP") && !hasMultipleTokenTransfers {
            if let tokenTransfer = transaction.tokenTransfers?.first {
                let symbol = await getTokenSymbol(tokenTransfer.mint, jupiterService: jupiterService)
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
        
        // 3. Fallback to accountData for complex transactions (especially swaps)
        // Use two-pass approach: collect tokens first, then SOL with correct threshold
        if received == nil || spent == nil, let accountData = transaction.accountData {
            var positiveChanges: [(value: Double, symbol: String, mint: String, iconURL: String?)] = []
            var negativeChanges: [(value: Double, symbol: String, mint: String, iconURL: String?)] = []
            
            // PASS 1: Collect all token balance changes first
            for account in accountData {
                if let changes = account.tokenBalanceChanges {
                    for change in changes {
                        // Verify this token account belongs to the user
                        let belongsToUser = change.userAccount == userAccount ||
                            (getExpectedTokenAccount(wallet: userAccount, mint: change.mint) == change.tokenAccount)
                        
                        guard belongsToUser else { continue }
                        
                        let amount = Double(change.rawTokenAmount.tokenAmount) ?? 0
                        let value = amount / pow(10, Double(change.rawTokenAmount.decimals))
                        
                        guard abs(value) > 0.000001 else { continue }
                        
                        let symbol = await getTokenSymbol(change.mint, jupiterService: jupiterService)
                        let iconURL = await jupiterService.getTokenIcon(mint: change.mint)
                        
                        if value > 0 {
                            positiveChanges.append((value: value, symbol: symbol, mint: change.mint, iconURL: iconURL))
                        } else if value < 0 {
                            negativeChanges.append((value: abs(value), symbol: symbol, mint: change.mint, iconURL: iconURL))
                        }
                    }
                }
            }
            
            // PASS 2: Check native SOL changes with appropriate threshold
            // Lower threshold (0.001 SOL) for swaps, higher (0.01 SOL) for pure SOL transactions
            let hasTokenChanges = positiveChanges.count > 0 || negativeChanges.count > 0
            let solThreshold: Double = hasTokenChanges ? 1_000_000 : 10_000_000
            
            for account in accountData {
                if account.account == userAccount {
                    let nativeChange = Double(account.nativeBalanceChange)
                    
                    if abs(nativeChange) > solThreshold {
                        let solAmount = abs(nativeChange) / 1_000_000_000
                        let solMint = "So11111111111111111111111111111111111111112"
                        let iconURL = await jupiterService.getTokenIcon(mint: solMint)
                        
                        if nativeChange > 0 {
                            positiveChanges.append((value: solAmount, symbol: "SOL", mint: solMint, iconURL: iconURL))
                        } else if nativeChange < 0 {
                            negativeChanges.append((value: solAmount, symbol: "SOL", mint: solMint, iconURL: iconURL))
                        }
                    }
                }
            }
            
            // Select the largest changes for received/spent
            // This ensures we show the primary tokens in a swap, not small fee/rent amounts
            if received == nil && !positiveChanges.isEmpty {
                let largest = positiveChanges.max(by: { $0.value < $1.value })!
                received = ProcessedTransaction.TokenAmount(
                    value: largest.value,
                    symbol: largest.symbol,
                    mint: largest.mint,
                    iconURL: largest.iconURL
                )
            }
            
            if spent == nil && !negativeChanges.isEmpty {
                let largest = negativeChanges.max(by: { $0.value < $1.value })!
                spent = ProcessedTransaction.TokenAmount(
                    value: largest.value,
                    symbol: largest.symbol,
                    mint: largest.mint,
                    iconURL: largest.iconURL
                )
            }
        }
        
        return (received, spent)
    }
    
    /// Get token symbol - uses hardcoded major tokens, then Jupiter verified list, then mint prefix
    private static func getTokenSymbol(_ mint: String, jupiterService: JupiterService) async -> String {
        // Fast path: hardcoded major tokens
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
        case "he1iusmfkpAdwvxLNGV8Y1iSbj4rUy6yMhEA3fotn9A":
            return "hSOL"
        default:
            // Try Jupiter verified tokens (~7k tokens)
            if let symbol = await jupiterService.getTokenSymbol(mint: mint) {
                return symbol
            }
            
            // Fallback: first 4 characters of mint (for pump.fun and other unverified tokens)
            return String(mint.prefix(4).uppercased())
        }
    }
}

