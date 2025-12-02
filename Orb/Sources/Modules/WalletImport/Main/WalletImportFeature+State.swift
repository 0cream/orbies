import ComposableArchitecture

extension WalletImportFeature {
    
    @ObservableState
    struct State {
        var privateKey: String = ""
        var isImporting: Bool = false
        var errorMessage: String?
    }
}


