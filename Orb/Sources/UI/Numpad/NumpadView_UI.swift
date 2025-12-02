import SwiftUI

enum NumpadValue_UI {
    case number(String)
    case backspace
}

struct NumpadView_UI: View {
    @Binding var value: String
    
    enum DecimalsDisplayMode: Equatable {
        case none
        case limited(Int)
        case noLimits
    }
    
    let decimals: DecimalsDisplayMode
    
    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: .init(.flexible(), spacing: 0),
                count: 3
            )
        ){
            ForEach(1...9, id: \.self) { index in
                keyboardButtonView(.number("\(index)")) {
                    if value.count == 1, value == "0" {
                        switch decimals {
                        case .none:
                            value.removeAll()
                        case .limited:
                            break
                        case .noLimits:
                            break
                        }
                    }
                    
                    if value.contains(".") {
                        switch decimals {
                        case .none:
                            break
                        case let .limited(int):
                            let string = value.components(separatedBy: ".").last ?? ""
                            if (string + "\(index)").count > int {
                                return
                            }
                            value.append("\(index)")
                        case .noLimits:
                            value.append("\(index)")
                        }
                    } else {
                        value.append("\(index)")
                    }
                }
            }
            
            switch decimals {
            case .none:
                Rectangle()
                    .fill(.clear)
                    .frame(maxWidth: .infinity, minHeight: 60)
            case .limited:
                keyboardButtonView(.number(".")) {
                    guard value.contains(".") == false else { return }
                    guard value.isEmpty == false else {
                        value = "0."
                        return
                    }
                    value.append(".")
                }
            case .noLimits:
                keyboardButtonView(.number(".")) {
                    guard value.contains(".") == false else { return }
                    if value.isEmpty {
                        value.append("0")
                    }
                    value.append(".")
                }
            }
            
            keyboardButtonView(.number("0")) {
                if value.count == 1, value == "0" { return }
                
                if value.contains(".") {
                    switch decimals {
                    case .none:
                        break
                    case let .limited(int):
                        let string = value.components(separatedBy: ".").last ?? ""
                        if (string + "0").count > int {
                            return
                        }
                        value.append("0")
                    case .noLimits:
                        value.append("0")
                    }
                    return
                }
                
                switch value {
                case "":
                    if decimals == .none {
                        return
                    } else {
                        value = "0."
                    }
                default:
                    value.append("0")
                }
            }
            
            keyboardButtonView(.backspace) {
                if value.isEmpty == false {
                    value.removeLast()
                }
            }
        }
    }
    
    @ViewBuilder
    private func keyboardButtonView(
        _ value: NumpadValue_UI,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            ZStack {
                switch value {
                case let .number(string):
                    Text(string)
                        .font(.system(size: 27, weight: .regular))
                        .foregroundStyle(Color.tokens.invertedTextPrimary)
                case .backspace:
                    Image(systemName: "delete.left")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(Color.tokens.invertedTextPrimary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.responsive(.default))
    }
}

#Preview {
    struct NumpadPreview: View {
        @State var value: String = ""
        
        var body: some View {
            VStack {
                Text(value.isEmpty ? "Empty" : value)
                    .font(.system(size: 40, weight: .bold))
                    .padding()
                
                NumpadView_UI(value: $value, decimals: .limited(2))
                    .padding()
            }
        }
    }
    
    return NumpadPreview()
}

