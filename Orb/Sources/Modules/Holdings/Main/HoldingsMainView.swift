import ComposableArchitecture
import SFSafeSymbols
import SwiftUI

@ViewAction(for: HoldingsMainFeature.self)
struct HoldingsMainView: View {
    @Bindable var store: StoreOf<HoldingsMainFeature>
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Navigation bar
                    NavigationBarView(
                        configuration: NavigationBarConfiguration(
                            title: store.title,
                            subtitle: nil,
                            showTrailingButton: false
                        ),
                        action: { action in
                            switch action {
                            case .didTapLeading:
                                send(.didTapBack)
                            case .didTapTrailing:
                                break
                            }
                        }
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    
                    // Token list
                    if store.tokenHoldings.isEmpty {
                        emptyState
                    } else {
                        tokenList
                    }
                    
                    Spacer()
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .onAppear {
            send(.didAppear)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemSymbol: .chartLineUptrendXyaxis)
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("No Holdings")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
            
            Text("Your token holdings will appear here")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 120)
    }
    
    private var tokenList: some View {
        LazyVStack(spacing: 12) {
            ForEach(store.tokenHoldings) { item in
                Button {
                    send(.didTapToken(item))
                } label: {
                    PortfolioTokenRow(item: item)
                        .padding(.horizontal, 24)
                }
                .buttonStyle(.responsive(.default))
            }
        }
        .padding(.bottom, 24)
    }
}

