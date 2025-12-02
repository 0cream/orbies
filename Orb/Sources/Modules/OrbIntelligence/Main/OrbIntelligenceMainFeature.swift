import ComposableArchitecture
import Dependencies
import Foundation

@Reducer
struct OrbIntelligenceMainFeature {
    
    @Dependency(\.walletService)
    private var walletService: WalletService
    
    @Dependency(\.orbIntelligenceService)
    private var orbIntelligenceService: OrbIntelligenceService
    
    @Dependency(\.orbIntelligenceSuggestService)
    private var orbIntelligenceSuggestService: OrbIntelligenceSuggestService
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case let .reducer(action):
                return reduce(state: &state, action: action)
                
            case .delegate, .binding:
                return .none
            }
        }
    }
    
    // MARK: - Reducer
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .onAppear:
            if state.preInput == nil {
                state.focusedField = .input
                
                return .run { send in
                    await send(.reducer(.setupObservers))
                    try await Task.sleep(for: .seconds(1))
                    try await orbIntelligenceService.setup()
                }
            } else {
                return .run { send in
                    await send(.reducer(.setupObservers))
                    try await Task.sleep(for: .seconds(0.75))
                    await send(.reducer(.didRequestPreInput))
                }
            }
            
        case .didTapSend:
            let text = state.input
            
            state.input = ""
            state.focusedField = nil
            state.isInputEnabled = false
            
            return .run { send in
                do {
                    try await orbIntelligenceService.send(message: text)
                } catch {
                    print("OrbIntelligence Error: \(error.localizedDescription)")
                }
                
                await send(.reducer(.didFinishSendMessage))
            }
            
        case let .didChangeInput(newValue):
            state.input = newValue
            return .none
            
        case let .didTapSuggest(suggest):
            orbIntelligenceSuggestService.used()
            
            state.input = ""
            state.focusedField = nil
            state.isInputEnabled = false
            
            return .run { send in
                do {
                    try await orbIntelligenceService.send(message: suggest)
                } catch {
                    print("OrbIntelligence Error: \(error.localizedDescription)")
                }
                
                await send(.reducer(.didFinishSendMessage))
            }
        }
    }
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case .setupObservers:
            return .merge(
                .run { send in
                    for await events in orbIntelligenceService.observe() {
                        await send(.reducer(.didUpdateMessages(events)))
                    }
                }
                .cancellable(id: CancelID.messagesObserver),
                .run { send in
                    for await suggests in orbIntelligenceSuggestService.observe() {
                        await send(.reducer(.didUpdateSuggests(suggests)), animation: .easeOut(duration: 0.15))
                    }
                }
                .cancellable(id: CancelID.suggestsObserver)
            )
            
        case .didRequestPreInput:
            guard let preInput = state.preInput else {
                return .none
            }
            
            state.input = ""
            state.focusedField = nil
            state.isInputEnabled = false
            
            return .run { send in
                do {
                    try await orbIntelligenceService.send(message: preInput)
                } catch {
                    print("OrbIntelligence Error: \(error.localizedDescription)")
                }
                
                await send(.reducer(.didFinishSendMessage))
            }
            
        case let .didUpdateMessages(events):
            state.events = events
            state.scrollTo = state.events.last?.id
            return .none
            
        case let .didUpdateSuggests(suggests):
            state.suggests = suggests
            return .none
            
        case .didFinishSendMessage:
            state.isInputEnabled = true
            return .none
        }
    }
    
    private struct CancelID {
        static let messagesObserver = "OrbIntelligenceMainFeature.MessagesObserver"
        static let suggestsObserver = "OrbIntelligenceMainFeature.SuggestsObserver"
    }
}

