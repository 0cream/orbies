import SwiftUI
import ComposableArchitecture
import NukeUI

@ViewAction(for: TransactionDetailFeature.self)
struct TransactionDetailView: View {
    
    let store: StoreOf<TransactionDetailFeature>
    
    var body: some View {
        let transaction = store.transaction
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        send(.didTapClose)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Swap details
                        if transaction.type.uppercased().contains("SWAP"),
                           let spent = transaction.spentAmount,
                           let received = transaction.receivedAmount {
                            
                            swapDetailRow(
                                label: "Paid",
                                tokenSymbol: spent.symbol,
                                address: spent.mint,
                                iconURL: spent.iconURL
                            )
                            
                            swapDetailRow(
                                label: "Got",
                                tokenSymbol: received.symbol,
                                address: received.mint,
                                iconURL: received.iconURL
                            )
                        }
                        
                        // Date
                        detailRow(label: "Date", value: formattedDate(transaction.date))
                        
                        // Fees
                        detailRow(label: "Fees", value: String(format: "%.9f", transaction.originalTransaction.feeInSOL))
                        
                        // Orb link
                        detailRow(
                            label: "Orb",
                            value: "https://orb.helius.dev/tx/...",
                            isLink: true,
                            url: "https://orb.helius.dev/tx/\(transaction.signature)?advanced=true&tab=summary"
                        )
                        
                        // Close button
                        Button {
                            send(.didTapClose)
                        } label: {
                            Text("Close")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
        }
    }
    
    // MARK: - Detail Row Views
    
    @ViewBuilder
    private func swapDetailRow(label: String, tokenSymbol: String, address: String, iconURL: String?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(tokenSymbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(shortenAddress(address))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                TokenImageView(
                    iconURL: iconURL,
                    fallbackText: tokenSymbol,
                    size: 40
                )
            }
        }
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func detailRow(label: String, value: String, isLink: Bool = false, url: String? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            if isLink, let urlString = url, let url = URL(string: urlString) {
                Link(destination: url) {
                    Text(value)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.blue)
                        .multilineTextAlignment(.trailing)
                }
            } else {
                Text(value)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 12)
    }
    
    private func shortenAddress(_ address: String) -> String {
        guard address.count > 20 else { return address }
        return "\(address.prefix(4))...\(address.suffix(4))"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy\nHH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Amount Card

struct AmountCard: View {
    let label: String
    let amount: String
    let symbol: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(isPositive ? "+" : "-")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isPositive ? .green : .red)
                
                Text(amount)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    var copyable: String?
    var onCopy: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
                
                if let copyable = copyable {
                    Button {
                        UIPasteboard.general.string = copyable
                        onCopy?()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

