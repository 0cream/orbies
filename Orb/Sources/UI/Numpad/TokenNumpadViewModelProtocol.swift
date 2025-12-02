import SwiftUI

protocol TokenNumpadViewModelProtocol: ObservableObject {
    associatedtype State
    
    var state: State { get }
    
    func send(_ action: TokenNumpadViewAction, animation: Animation?)
}

// MARK: - Helpers

extension TokenNumpadViewModelProtocol {
    func send(_ action: TokenNumpadViewAction) {
        send(action, animation: nil)
    }
}

