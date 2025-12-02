import ComposableArchitecture
import Dependencies
import Foundation

@Reducer
struct HistoryMainFeature {
    
    @Dependency(\.hapticFeedbackGenerator) var hapticFeedback
    @Dependency(\.transactionHistoryService) var transactionHistoryService
    
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
            return .run { send in
                // Subscribe to pre-processed transaction updates
                // Processing happens in TransactionHistoryService for better performance
                for await processedTransactions in await transactionHistoryService.processedTransactionsStream() {
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

