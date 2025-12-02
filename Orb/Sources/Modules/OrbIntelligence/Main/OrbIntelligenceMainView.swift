import SwiftUI
import ComposableArchitecture
import Combine
import SFSafeSymbols

struct OrbIntelligenceConstants {
    static let endOfChatID = "END_OF_CHAT"
}

@ViewAction(for: OrbIntelligenceMainFeature.self)
struct OrbIntelligenceMainView: View {
    
    @Bindable var store: StoreOf<OrbIntelligenceMainFeature>
    @FocusState var focusedField: OrbIntelligenceMainFeature.State.Field?
    
    // MARK: - UI
    
    var body: some View {
        VStack(spacing: .zero) {
            // Header
            HStack(spacing: .zero) {
                Button {
                    
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(Color.white.opacity(0.6))
                        .font(.system(size: 18))
                }
                .frame(width: 44, height: 44)
                .opacity(0)
                
                Text("Orb Intelligence")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
            }
            .frame(height: 70)
            .padding(.horizontal, 14)
            .background(Color.black)
            
            ScrollViewReader { scrollViewReader in
                ScrollView {
                    VStack(spacing: .zero) {
                        content
                        .padding(.bottom, 16)
                        
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 1)
                            .id(OrbIntelligenceConstants.endOfChatID)
                        
                        Spacer()
                    }
                    .padding(.bottom, 12)
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .onChange(of: store.messages) { _, _ in
                    withAnimation(.easeOut(duration: 0.15)) {
                        scrollViewReader.scrollTo(OrbIntelligenceConstants.endOfChatID)
                    }
                }
                .allowsHitTesting(store.isInputEnabled)
            }
            
            if let suggests = store.suggests.nonEmpty {
                OrbIntelligenceSuggestsView(items: suggests) { suggest in
                    send(.didTapSuggest(suggest))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            
            // Input field
            HStack(spacing: .zero) {
                TextField(
                    "Ask me anything...",
                    text: $store.input
                )
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white)
                .focused($focusedField, equals: .input)
                .frame(height: 24)
                .padding(.leading, 16)
                .padding(.vertical, 12)
                
                Button {
                    send(.didTapSend)
                } label: {
                    SFSymbol.arrowUp.image
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color(red: 1.0, green: 0.3, blue: 0.2))
                        .clipShape(.circle)
                }
                .padding(8)
                .disabled(store.isInputEnabled == false)
            }
            .background {
                ZStack {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    
                    Capsule()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                        .foregroundColor(Color.white.opacity(0.15))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
            .bind($store.focusedField, to: $focusedField)
            .onAppear {
                send(.onAppear)
            }
        }
        .background(Color.black)
    }
    
    var content: some View {
        LazyVStack(spacing: 24) {
            ForEach(store.messages) { message in
                switch message.content {
                case let .loading(value):
                    HStack(alignment: .top, spacing: 12) {
                        ProgressView()
                            .tint(Color.white.opacity(0.6))
                            .progressViewStyle(CircularProgressViewStyle())
                        
                        Text(LocalizedStringKey(value))
                    }
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .transition(
                        .smoothMove(
                            blur: 4,
                            scale: 0.98,
                            opacity: 0,
                            animation: .easeOut(duration: 0.15)
                        )
                    )
                    
                case let .error(error):
                    Group {
                        Text(SFSymbol.exclamationmarkTriangleFill.image) + Text(" " + error)
                    }
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.tokens.systemRed)
                    .padding(8)
                    .background(Color.tokens.systemRed.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 64)
                    .padding(.leading, 24)
                    .transition(.opacity.animation(.easeOut(duration: 0.15)))
                    .id(message.id)
                    
                case let .text(value):
                    switch message.direction {
                    case .income:
                        Text(LocalizedStringKey(value))
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.trailing, 64)
                            .padding(.leading, 24)
                            .transition(
                                .smoothMove(
                                    blur: 0,
                                    opacity: 0,
                                    animation: .easeOut(duration: 0.15)
                                )
                            )
                            .id(message.id)
                        
                    case .outgoing:
                        Text(value)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.leading, 64)
                            .padding(.trailing, 24)
                            .transition(.opacity.animation(.easeOut(duration: 0.15)))
                            .id(message.id)
                    }
                }
            }
        }
    }
}

struct OrbIntelligenceSuggestsView: View {
    private let items: [String]
    private let action: (String) -> Void
    
    init(items: [String], action: @escaping (String) -> Void) {
        self.items = items
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(items, id: \.self) { item in
                Button {
                    action(item)
                } label: {
                    Text(item)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background {
                            ZStack {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                
                                Capsule()
                                    .stroke(style: StrokeStyle(lineWidth: 1))
                                    .foregroundColor(Color.white.opacity(0.15))
                            }
                        }
                        .contentShape(Rectangle())
                }
            }
        }
    }
}

