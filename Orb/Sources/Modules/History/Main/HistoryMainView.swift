import SwiftUI
import ComposableArchitecture
import SFSafeSymbols

@ViewAction(for: HistoryMainFeature.self)
struct HistoryMainView: View {
    
    let store: StoreOf<HistoryMainFeature>
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if store.transactions.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemSymbol: .clockFill)
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No transactions yet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Your transaction history will appear here")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Transaction list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header with logo
                        HStack(spacing: 8) {
                            Image("orb_small_orange")
                                .resizable()
                                .frame(width: 28, height: 28)
                            
                            Text("Activity")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                        
                        // Grouped transactions by date
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(store.groupedTransactions, id: \.0) { dateHeader, transactions in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Date header
                                    Text(dateHeader)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .padding(.horizontal, 24)
                                    
                                    // Transactions for this date
                                    VStack(spacing: 0) {
                                        ForEach(transactions) { transaction in
                                            SimpleTransactionRow(transaction: transaction)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    send(.didTapTransaction(transaction))
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .onAppear {
            send(.didAppear)
        }
        .onDisappear {
            send(.didDisappear)
        }
    }
}
