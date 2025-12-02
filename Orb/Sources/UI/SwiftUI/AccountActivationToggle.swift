import SwiftUI
import SFSafeSymbols

// MARK: - Account Activation Toggle (animated)

struct AccountActivationToggle: View {
    let isOn: Bool
    
    var backgroundColor: Color {
        isOn ? Color(red: 0.2, green: 0.5, blue: 1.0) : Color(rgb: 0xEBEBEB)
    }
    
    var foregroundColor: Color {
        isOn ? Color(red: 0.2, green: 0.5, blue: 1.0) : .black
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isOn {
                Spacer()
            }
            
            ZStack {
                // Loading spinner (when activating)
                if !isOn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(0.8)
                }
                
                // Lock icon (when activated)
                Image(systemSymbol: .lockFill)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(foregroundColor)
                    .opacity(isOn ? 1 : 0)
                    .scaleEffect(isOn ? 1 : 0)
            }
            .frame(width: 40, height: 40)
            .background(Color.white)
            .clipShape(Circle())
            .padding(4)
            
            if !isOn {
                Spacer()
            }
        }
        .frame(width: 80, height: 48)
        .background(backgroundColor)
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.3), value: isOn)
    }
}


