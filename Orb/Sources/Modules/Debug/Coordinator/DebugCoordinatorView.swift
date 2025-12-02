import ComposableArchitecture
import SwiftUI

struct DebugCoordinatorView: View {
    
    @Bindable var store: StoreOf<DebugCoordinator>
    
    var body: some View {
        NavigationStack {
            DebugView(store: store.scope(state: \.root, action: \.root))
                .navigationTitle("Debug Menu")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            store.send(.view(.didTapClose))
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
        }
    }
}

