import SwiftUI

struct ActivityPopupView: View {
    let value: ActivityPopupValue?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                VStack(spacing: .zero) {
                    ZStack(alignment: .top) {
                        if let value {
                            HStack(alignment: .top, spacing: .zero) {
                                HStack(spacing: 6) {
                                    Text(value.emoji)
                                        .font(.system(size: 16))
                                    
                                    Text(value.text)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.tokens.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(white: 0.95))
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, geometry.safeAreaInsets.top + 16)
                            .zIndex(100)
                            .transition(
                                .asymmetric(
                                    insertion: .smoothMove(
                                        x: 0,
                                        y: -25,
                                        blur: 2,
                                        scale: 0.85,
                                        opacity: 0,
                                        animation: .easeOut(duration: 0.4)
                                    ),
                                    removal: .smoothMove(
                                        x: 0,
                                        y: -25,
                                        blur: 2,
                                        scale: 0.85,
                                        opacity: 0,
                                        animation: .easeOut(duration: 0.4)
                                    )
                                )
                            )
                            .id(value.text)
                        }
                    }
                    
                    Spacer()
                }
            }
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

