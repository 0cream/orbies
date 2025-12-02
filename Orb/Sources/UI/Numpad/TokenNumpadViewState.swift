import SwiftUI

protocol TokenNumpadStateToViewStateTransformerProtocol {
    associatedtype State
    
    func transform(_ state: State) -> TokenNumpadViewState
}

struct TokenNumpadViewState: Equatable {
    let title: String
    let input: String
    let inputDecimalsLimit: Int
    let inputShakeIdentifier: UUID
    let inputDoubleValue: Double
    let inputStringValue: String
    let inputFooter: TokenNumpadViewFooterState?
    let toolbar: TokenNumpadToolbarViewState
    let actionButton: TokenNumpadActionButtonState
}

// MARK: - Helpers

struct TokenNumpadViewFooterState: Equatable {
    let leadingText: String
    let leadingTextDouble: Double
    let trailingText: String?
}

struct TokenNumpadActionButtonState: Equatable {
    let id: String
    let title: String
    let titleDouble: Double
    let isEnabled: Bool
    let isLoading: Bool
}

struct TokenNumpadToolbarViewItem: Equatable {
    let id: String
    let title: String
}

struct TokenNumpadToolbarViewState: Equatable {
    let title: String
    let subtitle: String
    let subtitleShakeId: UUID?
    let secondaryButton: String?
    let secondaryItems: [TokenNumpadToolbarViewItem]?
    let style: TokenNumpadToolbarViewStyle
    let isVisible: Bool
}

struct TokenNumpadToolbarViewStyle: Equatable {
    let titleForegroundColor: Color
    let subtitleForegroundColor: Color
    
    static let idle = Self(
        titleForegroundColor: Color.tokens.invertedTextSecondary.opacity(0.6),
        subtitleForegroundColor: Color.tokens.invertedTextSecondary
    )
    
    static let negative = Self(
        titleForegroundColor: Color.tokens.red.opacity(0.5),
        subtitleForegroundColor: Color.tokens.red
    )
}

enum TokenNumpadViewAction {
    case onAppear
    case didChangeValue(String)
    case didTapToolbarSecondaryButton
    case didTapToolbarItem(id: String)
    case didTapActionButton
}

