import SwiftUI

// MARK: - Shimmer Effect

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}
import Dependencies

// MARK: - Equatable

extension View where Self: Equatable {
    public func equatable() -> EquatableView<Self> {
        return EquatableView(content: self)
    }
}

// MARK: - Calculate Size

extension View {
    @MainActor
    func calculateSize() -> CGSize? {
        let renderer = ImageRenderer(content: self)
        
        guard let image = renderer.uiImage else {
            return nil
        }
        
        return image.size
    }
}

// MARK: - Read Size

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(
                        key: SizePreferenceKey.self,
                        value: geometryProxy.size
                    )
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
    
    func readFrame(in coordinateSpace: CoordinateSpace, onChange: @escaping (CGRect) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(
                        key: FramePreferenceKey.self,
                        value: geometryProxy.frame(in: coordinateSpace)
                    )
            }
        )
        .onPreferenceChange(FramePreferenceKey.self, perform: onChange)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

struct FramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}

// MARK: - Conditions

extension View {
    @ViewBuilder
    func `if`<V: View>(
        _ condition: Bool,
        @ViewBuilder _ transform: (Self) -> V
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        @ViewBuilder _ ifTransform: (Self) -> TrueContent,
        @ViewBuilder else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    @ViewBuilder
    func if_let<V: View, T>(_ optionalValue: T?, @ViewBuilder _ transform: (Self, T) -> V) -> some View {
        if let value = optionalValue {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - View + HostingController

public extension View {
    func asHostingController() -> UIHostingController<Self> {
        UIHostingController(rootView: self)
    }
}

// MARK: - additionalSafeAreaInset

public extension View {
    func additionalSafeAreaInset(_ edge: VerticalEdge, _ inset: CGFloat? = nil) -> some View {
        if #available(*, iOS 17.0) {
            let edges: Edge.Set = switch edge {
            case .top: .top
            case .bottom: .bottom
            }
            return safeAreaPadding(edges, inset)
        } else {
            return safeAreaInset(edge: edge) {
                Color.clear
                    .frame(height: inset)
            }
        }
    }
}
