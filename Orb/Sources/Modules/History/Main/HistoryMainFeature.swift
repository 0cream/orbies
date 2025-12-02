import ComposableArchitecture
import Dependencies
import Foundation

@Reducer
struct HistoryMainFeature {
    
    @Dependency(\.hapticFeedbackGenerator) var hapticFeedback
    @Dependency(\.transactionHistoryService) var transactionHistoryService
    @Dependency(\.jupiterService) var jupiterService
    
    private enum CancelID { case transactionUpdates }
    
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
            return .run { [jupiterService] send in
                // Subscribe to transaction updates from the stream
                for await rawTransactions in await transactionHistoryService.transactionsStream() {
                    // Filter out NFT transactions and tiny SOL-only transfers
                    let fungibleTransactions = rawTransactions.filter { transaction in
                        let type = transaction.type.uppercased()
                        
                        // Filter out NFTs
                        guard !type.contains("NFT") && 
                               type != "NFT_MINT" && 
                               type != "NFT_LISTING" && 
                               type != "NFT_SALE" &&
                               type != "NFT_BID" &&
                               type != "COMPRESSED_NFT_MINT" &&
                               type != "COMPRESSED_NFT_TRANSFER" else {
                            return false
                        }
                        
                        // Filter out tiny SOL-only transfers (< 5 lamports = 0.000000005 SOL)
                        // But keep transactions with token transfers (they're not just tiny SOL moves)
                        if type.contains("TRANSFER") {
                            // If there's a token transfer, keep it regardless of SOL amount
                            if transaction.tokenTransfers?.isEmpty == false {
                                return true
                            }
                            // If there's only a native transfer, check if it's meaningful
                            if let nativeTransfer = transaction.nativeTransfers?.first {
                                return nativeTransfer.amount >= 5
                            }
                            // If labeled as transfer but has no transfers, filter it out
                            return false
                        }
                        
                        return true
                    }
                    
                    // Process transactions to extract clean display data with Jupiter icons
                    var processedTransactions: [ProcessedTransaction] = []
                    for transaction in fungibleTransactions {
                        let processed = await TransactionProcessor.process(transaction, jupiterService: jupiterService)
                        processedTransactions.append(processed)
                    }
                    
                    await send(.reducer(.transactionsLoaded(processedTransactions)))
                }
            }
            .cancellable(id: CancelID.transactionUpdates)
            
        case .didDisappear:
            // Cancel subscription when view disappears
            return .cancel(id: CancelID.transactionUpdates)
            
        case let .didTapTransaction(transaction):
            return .merge(
                .run { _ in
                    await hapticFeedback.light(intensity: 1.0)
                },
                .send(.delegate(.didRequestOpenTransactionDetail(transaction)))
            )
        }
    }
    
    // MARK: - Reducer Actions
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case let .transactionsLoaded(transactions):
            state.transactions = transactions
            return .none
        }
    }
}

