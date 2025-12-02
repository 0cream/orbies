import SwiftSyntax
import Foundation

extension VariableDeclSyntax {
  public var isStored: Bool {
    guard let binding = bindings.first, bindings.count == 1 else { return false }
    switch binding.accessorBlock?.accessors {
    case .none:
      return true

    case .getter:
      return false

    case let .accessors(node):
      for accessor in node {
        switch accessor.accessorSpecifier.tokenKind {
        case .keyword(.willSet), .keyword(.didSet):
          break
        default:
          return false
        }
      }

      return true
    }
  }

  /// Is stored property without any side effects (willSet/didSet blocks)
  public var isRawStored: Bool {
    guard let binding = bindings.first, bindings.count == 1 else { return false }
    switch binding.accessorBlock?.accessors {
    case .none:
      return true
    case .getter:
      return false
    case let .accessors(node):
      return node.isEmpty
    }
  }
  
  public var isStatic: Bool {
    modifiers.lazy.contains(where: { $0.name.tokenKind == .keyword(.static) }) == true
  }
  
  public var identifier: TokenSyntax? {
    bindings.lazy.compactMap { $0.pattern.as(IdentifierPatternSyntax.self) }.first?.identifier
  }
  
  public var isComputed: Bool { !isStored }
  public var isLet: Bool { bindingSpecifier.tokenKind == .keyword(.let) }
  public var isVar: Bool { bindingSpecifier.tokenKind == .keyword(.var) }
  public var hasInitialValue: Bool { bindings.first?.initializer != nil }
}
