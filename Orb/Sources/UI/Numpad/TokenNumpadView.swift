import SwiftUI

/// Generic numpad view for sell & buy flows
struct TokenNumpadView<State, ViewModel, ViewStateTransformer>: View
/// Conditions to constraint usage only for suitable ViewModel & ViewStateTransformer pairs.
where ViewModel: TokenNumpadViewModelProtocol,
      ViewModel.State == State,
      ViewStateTransformer: TokenNumpadStateToViewStateTransformerProtocol,
      ViewStateTransformer.State == State {
    
    // MARK: - ViewModel
    
    @ObservedObject private var viewModel: ViewModel
    @Namespace private var inputViewTextAnimationNamespace
    
    // MARK: - Private Properties
    
    private let viewStateTransformer: ViewStateTransformer
    
    // MARK: - View State
    
    private var viewState: TokenNumpadViewState {
        viewStateTransformer.transform(viewModel.state)
    }
    
    // MARK: - Init
    
    init(
        viewModel: ViewModel,
        viewStateTransformer: ViewStateTransformer
    ) {
        self.viewModel = viewModel
        self.viewStateTransformer = viewStateTransformer
    }
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            // Dark background to match app theme
            Color.tokens.invertedLevelSurface
                .ignoresSafeArea()
            
            VStack(spacing: .zero) {
                Text(viewState.title)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.tokens.invertedTextPrimary)
                .padding(.top, 26)
            
            VStack(spacing: .zero) {
                VStack(spacing: .zero) {
                    Text(viewState.input)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Color.tokens.invertedTextPrimary)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .matchedGeometryEffect(id: "InputView.Text", in: inputViewTextAnimationNamespace)
                        .id(viewState.input)
                }
                .matchedGeometryEffect(id: "InputView", in: inputViewTextAnimationNamespace)
                .padding(.horizontal, 24)
                .id("InputView")
                
                if let inputFooter = viewState.inputFooter {
                    HStack(spacing: .zero) {
                        Text(inputFooter.leadingText)
                            .foregroundStyle(Color.tokens.invertedTextSecondary)
                            .contentTransition(.numericText())
                            .animation(.easeOut(duration: 0.15), value: inputFooter.leadingTextDouble)
                        
                        if let trailingText = inputFooter.trailingText {
                            Text(trailingText)
                                .foregroundStyle(Color.tokens.invertedTextSecondary.opacity(0.6))
                                .padding(.leading, 4)
                        }
                    }
                    .font(.system(size: 18, weight: .regular))
                    .padding(.top, 4)
                }
            }
            .frame(maxHeight: .infinity)
            .offset(y: 10)
            
            VStack(spacing: .zero) {
                HStack(spacing: .zero) {
                    VStack(spacing: .zero) {
                        Text(viewState.toolbar.title)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(viewState.toolbar.style.titleForegroundColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(viewState.toolbar.subtitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(viewState.toolbar.style.subtitleForegroundColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }
                    
                    if let secondaryButton = viewState.toolbar.secondaryButton {
                        Button { [weak viewModel] in
                            viewModel?.send(.didTapToolbarSecondaryButton)
                        } label: {
                            VStack(spacing: .zero) {
                                Text(secondaryButton)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .transition(.scale(scale: 0.5).combined(with: .opacity).animation(.easeOut(duration: 0.15)))
                                    .id(secondaryButton)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                ZStack {
                                    // Blur layer
                                    Capsule()
                                        .fill(Color.white.opacity(0.05))
                                        .blur(radius: 8)
                                    
                                    // Main background
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .background(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                }
                            )
                            .id("TokenNumpadView.ToolbarSecondaryButton.VStack")
                        }
                        .buttonStyle(.responsive(.default))
                        .id("TokenNumpadView.ToolbarSecondaryButton")
                    }
                }
                
                if let items = viewState.toolbar.secondaryItems, items.isEmpty == false {
                    HStack(spacing: 12) {
                        ForEach(items, id: \.id) { item in
                            Button { [weak viewModel] in
                                viewModel?.send(.didTapToolbarItem(id: item.id))
                            } label: {
                                Text(item.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.tokens.invertedTextPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11.5)
                                    .background(Color.tokens.invertedLevelElevation)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.responsive(.default))
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                }
            }
            .padding(.horizontal, 24)
            .opacity(viewState.toolbar.isVisible ? 1 : 0)
            
            Button { [weak viewModel] in
                viewModel?.send(.didTapActionButton)
            } label: {
                ZStack {
                    Text(viewState.actionButton.title)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.15), value: viewState.actionButton.titleDouble)
                        .id(viewState.actionButton.id)
                        .opacity(viewState.actionButton.isLoading ? 0 : 1)
                    
                    if viewState.actionButton.isLoading {
                        ProgressView()
                            .tint(.white)
                            .transition(.scale(scale: 0.75).combined(with: .opacity))
                    }
                }
                .id("TokenNumpadView.ActionButton")
            }
            .disabled(viewState.actionButton.isEnabled == false)
            .buttonStyle(.volumeLargeOrange)
            .padding(.top, 14)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            NumpadView_UI(
                value: Binding(
                    get: { viewState.inputStringValue },
                    set: { [weak viewModel] newValue in
                        viewModel?.send(.didChangeValue(newValue))
                    }
                ),
                decimals: .limited(viewState.inputDecimalsLimit)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            }
        }
        .onAppear { [weak viewModel] in
            viewModel?.send(.onAppear)
        }
    }
}

extension View {
    func disableAnimationBelowOsVersion17(animation: Animation) -> some View {
        transaction { transaction in
            if #available(iOS 17.0, *) {
                // do nothing
                transaction.animation = animation
            } else {
                transaction.animation = nil
            }
        }
    }
}

