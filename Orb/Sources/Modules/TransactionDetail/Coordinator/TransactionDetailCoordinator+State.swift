import ComposableArchitecture

extension TransactionDetailCoordinator {
    @ObservableState
    struct State {
        var root: TransactionDetailFeature.State
        
        init(transaction: ProcessedTransaction) {
            self.root = TransactionDetailFeature.State(transaction: transaction)
        }
    }
}

