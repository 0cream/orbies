import SwiftUI
import NukeUI

/// Simplified transaction row using ProcessedTransaction
struct SimpleTransactionRow: View {
    let transaction: ProcessedTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Token icons
            tokenIcons
            
            // Transaction details
            if transaction.type.uppercased().contains("SWAP") {
                // Swaps: No text, just amounts on the right
                Spacer()
            } else {
                // Transfers: Show title only
                VStack(alignment: .leading, spacing: 4) {
                    Text(transactionTitle)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)
                }
            }
            
            Spacer()
            
            // Amounts (right side)
            amountsView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Amounts View
    
    @ViewBuilder
    private var amountsView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Show received amount (green, +)
            if let received = transaction.receivedAmount {
                Text("+\(received.formatted)")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.green)
            }
            
            // Show spent amount (red, -)
            if let spent = transaction.spentAmount {
                Text("-\(spent.formatted)")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.red)
            }
        }
    }
    
    // MARK: - Token Icons
    
    @ViewBuilder
    private var tokenIcons: some View {
        ZStack(alignment: .leading) {
            if transaction.type.uppercased().contains("SWAP"),
               let received = transaction.receivedAmount,
               let spent = transaction.spentAmount {
                // Swap: Show token icons with arrow
                HStack(spacing: 8) {
                    TokenImageView(
                        iconURL: spent.iconURL,
                        fallbackText: spent.symbol,
                        size: 40
                    )
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    TokenImageView(
                        iconURL: received.iconURL,
                        fallbackText: received.symbol,
                        size: 40
                    )
                }
            } else if let received = transaction.receivedAmount {
                // Transfer: Single icon (received)
                TokenImageView(
                    iconURL: received.iconURL,
                    fallbackText: received.symbol,
                    size: 40
                )
            } else if let spent = transaction.spentAmount {
                // Transfer: Single icon (spent)
                TokenImageView(
                    iconURL: spent.iconURL,
                    fallbackText: spent.symbol,
                    size: 40
                )
            } else {
                // Fallback
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.gray)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var transactionTitle: String {
        let type = transaction.type.uppercased()
        
        if type.contains("SWAP"),
           let received = transaction.receivedAmount,
           let spent = transaction.spentAmount {
            return "\(spent.symbol) → \(received.symbol)"
        } else if type.contains("TRANSFER") {
            return transaction.receivedAmount?.symbol ?? transaction.spentAmount?.symbol ?? "Transfer"
        } else if type.contains("STAKE") {
            return type.contains("UNSTAKE") ? "Unstake" : "Stake"
        }
        
        return transaction.description ?? "Transaction"
    }
    
    private var transactionSubtitle: String {
        let source = formatSource(transaction.source)
        return source
    }
    
    private func formatSource(_ source: String) -> String {
        if source == "UNKNOWN" || source == "SYSTEM_PROGRAM" {
            return "System"
        }
        return source.split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
}

