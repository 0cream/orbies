import ComposableArchitecture

extension TransactionDetailFeature {
    @ObservableState
    struct State {
        let transaction: ProcessedTransaction
    }
}

