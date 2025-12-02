import Foundation
import Dependencies
import ComposableArchitecture

@attached(accessor, names: arbitrary)
@attached(peer, names: arbitrary)
public macro DependencyMacro<T>(
    _ keyPath: KeyPath<Dependencies.DependencyValues, T> & Sendable
) = #externalMacro(module: "DependencyMacros", type: "DependencyMacro")

public typealias DependencyPropertyWrapper = ComposableArchitecture.Dependency
