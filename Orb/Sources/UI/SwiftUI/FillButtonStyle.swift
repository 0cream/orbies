import SwiftUI

struct FillButton: Equatable {
    struct Style: Equatable {
        let foregroundColor: Color
        let backgroundColor: Color
        
        static func primaryIdle(accentColor: Color) -> Self {
            Self(
                foregroundColor: Color(rgb: 0xFFFFFF),
                backgroundColor: accentColor
            )
        }
        
        static let primaryIdle = Self(
            foregroundColor: Color(rgb: 0xFFFFFF),
            backgroundColor: Color(rgb: 0x343434)
        )
        
        static let primaryDisabled = Self(
            foregroundColor: Color(rgb: 0xBCBBBB),
            backgroundColor: Color(rgb: 0xF8F8F7)
        )
        
        static let secondaryIdle = Self(
            foregroundColor: Color(rgb: 0x1A1A1A),
            backgroundColor: Color(rgb: 0xEAEAEA)
        )
        
        static let secondaryDisabled = Self(
            foregroundColor: Color(rgb: 0xBCBBBB),
            backgroundColor: Color(rgb: 0xEAEAEA)
        )
    }
    
    let font: Font
    let idle: Style
    let disabled: Style
    
    init(
        font: Font,
        idle: Style,
        disabled: Style
    ) {
        self.font = font
        self.idle = idle
        self.disabled = disabled
    }
    
    static let primary = Self(
        font: .system(size: 20, weight: .semibold),
        idle: .primaryIdle,
        disabled: .primaryDisabled
    )
    
    static let secondary = Self(
        font: .system(size: 20, weight: .semibold),
        idle: .secondaryIdle,
        disabled: .secondaryDisabled
    )
}

struct FillButtonStyle: ButtonStyle {
    enum State: String, Equatable {
        case loading
        case idle
    }
    
    private let button: FillButton
    private let state: State
    
    init(_ button: FillButton, state: State = .idle) {
        self.button = button
        self.state = state
    }
    
    func makeBody(configuration: Configuration) -> some View {
        Button(
            configuration: configuration,
            state: state,
            button: button
        )
    }
    
    fileprivate struct Button: View {

        // MARK: - Private Properties

        @Environment(\.isEnabled) private var isEnabled: Bool

        // MARK: - Properties

        let configuration: ButtonStyle.Configuration
        let state: State
        let button: FillButton

        // MARK: - Private Properties

        private var foregroundColor: Color {
            isEnabled
                ? button.idle.foregroundColor
                : button.disabled.foregroundColor
        }

        private var backgroundColor: Color {
            isEnabled
                ? button.idle.backgroundColor
                : button.disabled.backgroundColor
        }

        // MARK: - UI

        var body: some View {
            let foregroundStyle = foregroundColor.opacity(configuration.isPressed ? 0.75 : 1)
            let background = backgroundColor.opacity(configuration.isPressed ? 0.75 : 1)
            
            label
                .font(button.font)
                .multilineTextAlignment(.center)
                .foregroundStyle(foregroundStyle)
                .frame(maxWidth: .infinity)
                .frame(height: 66)
                .padding(.horizontal, 0)
                .background(background)
                .clipShape(.capsule)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
                .haptic(isPressed: configuration.isPressed)
        }
        
        var label: some View {
            ZStack {
                switch state {
                case .loading:
                    ProgressView()
                        .tint(foregroundColor)
                        .progressViewStyle(.circular)
                        .transition(.blurReplacement())
                    
                case .idle:
                    configuration.label
                        .transition(.blurReplacement())
                }
            }
        }
    }
}

extension ButtonStyle where Self == FillButtonStyle {
    static var primaryFill: Self {
        FillButtonStyle(.primary, state: .idle)
    }
    
    static var secondaryFill: Self {
        FillButtonStyle(.secondary, state: .idle)
    }
    
    static func primaryFill(state: FillButtonStyle.State) -> Self {
        FillButtonStyle(.primary, state: state)
    }
    
    static func secondaryFill(state: FillButtonStyle.State) -> Self {
        FillButtonStyle(.secondary, state: state)
    }
}

#Preview {
    struct ContentPreview: View {
        @State var isSelected = false
        @State var isLoading = false
        
        var body: some View {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    Button("Primary Loading") {
                        isLoading.toggle()
                    }
                    .buttonStyle(.primaryFill(state: isLoading ? .loading : .idle))
                    
                    Button("Primary") {}
                        .buttonStyle(.primaryFill)
                    
                    Button("Primary Disabled") {}
                        .buttonStyle(.primaryFill)
                        .disabled(true)
                    
                    Button("Secondary") {}
                        .buttonStyle(.secondaryFill)
                    
                    Button("Secondary Disabled 1") {}
                        .buttonStyle(.secondaryFill)
                        .disabled(true)
                }
                .padding(24)
            }
        }
    }
    
    return ContentPreview()
}
