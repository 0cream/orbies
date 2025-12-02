import SwiftUI
import SFSafeSymbols

struct NavigationBarConfiguration: Equatable {
    let title: String
    let subtitle: String?
    let showTrailingButton: Bool
    
    init(title: String, subtitle: String? = nil, showTrailingButton: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.showTrailingButton = showTrailingButton
    }
}

enum NavigationBarAction {
    case didTapLeading
    case didTapTrailing
}

struct NavigationBarView: View {
    let configuration: NavigationBarConfiguration
    let action: (NavigationBarAction) -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: .zero) {
                Text(configuration.title)
                    .foregroundStyle(Color.white)
                    .font(.system(size: 18, weight: .semibold))
                
                if let subtitle = configuration.subtitle {
                    Text(subtitle)
                        .foregroundStyle(Color.white.opacity(0.5))
                        .font(.system(size: 14, weight: .medium))
                        .padding(.top, 2)
                }
            }
            
            HStack(spacing: .zero) {
                Button {
                    action(.didTapLeading)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemSymbol: .chevronLeft)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.responsive(.scale))
                
                Spacer()
                
                if configuration.showTrailingButton {
                    Button {
                        action(.didTapTrailing)
                    } label: {
                        Image(systemSymbol: .squareAndArrowUp)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.responsive(.scale))
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 60)
    }
}
