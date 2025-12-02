import ComposableArchitecture

extension HistoryMainFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didDisappear
            case didTapTransaction(ProcessedTransaction)
        }
        
        enum Reducer {
            case transactionsLoaded([ProcessedTransaction])
        }
        
        enum Delegate {
            case didRequestOpenTransactionDetail(ProcessedTransaction)
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
}

