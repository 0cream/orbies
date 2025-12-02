import Foundation

@attached(accessor, names: arbitrary)
@attached(peer, names: arbitrary)
public macro Dependency<T>(
  _ keyPath: KeyPath<DependencyValues, T> & Sendable
) = #externalMacro(module: "DependencyMacros", type: "DependencyMacro")

