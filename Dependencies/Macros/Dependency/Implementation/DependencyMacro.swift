import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Utils

enum DependencyMacro { }

// MARK: - Private methods

private extension DependencyMacro {
  static func parseDeclaration(
    node: AttributeSyntax,
    declaration: some DeclSyntaxProtocol
  ) throws(DependencyMacroError) -> Declaration {
    guard let attributeArgument: RawExpression = node.argument(atIndex: 0) else { throw .keyPathArgumentIsMissing }
    guard let variableDecl = declaration.as(VariableDeclSyntax.self) else { throw .declarationIsNotAVariable }
    guard let variableName = variableDecl.identifier?.text else { throw .variableHasNoIdentifier }
    guard variableDecl.isStored else { throw .variableIsNotAStoredOne }
    guard variableDecl.isRawStored else { throw .variableHasSideEffects }
    guard !variableDecl.hasInitialValue else { throw .variableHasInitialValue }
    guard !variableDecl.isLet else { throw .variableIsALetConstant }
    return Declaration(variableName: variableName, isStaticVariable: variableDecl.isStatic, attributeArgument: attributeArgument)
  }
}

// MARK: - AccessorMacro

extension DependencyMacro: AccessorMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    let declaration = try parseDeclaration(node: node, declaration: declaration)
    return [
        """
        get { _\(raw: declaration.variableName).wrappedValue }
        """
    ]
  }
}

// MARK: - PeerMacro

extension DependencyMacro: PeerMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax] {
    let declaration = try parseDeclaration(node: node, declaration: declaration)
    let staticModifier = declaration.isStaticVariable ? "static " : ""
    return [
        """
        private \(raw: staticModifier)let _\(raw: declaration.variableName) = \(raw: Constants.underlyingObject)(\(raw: declaration.attributeArgument.expression))
        """
    ]
  }
}

// MARK: - Nested types

private extension DependencyMacro {
  struct Declaration {
    let variableName: String
    let isStaticVariable: Bool
    let attributeArgument: RawExpression
  }
  
  enum DependencyMacroError: Error, CustomDebugStringConvertible {
    case keyPathArgumentIsMissing
    case declarationIsNotAVariable
    case variableHasNoIdentifier
    case variableIsNotAStoredOne
    case variableHasSideEffects
    case variableHasInitialValue
    case variableIsALetConstant
    
    var debugDescription: String {
      switch self {
       case .keyPathArgumentIsMissing:
           return "Required KeyPath argument is missing."
       case .declarationIsNotAVariable:
           return "The declaration must be a variable."
       case .variableHasNoIdentifier:
           return "The variable declaration lacks an identifier."
       case .variableIsNotAStoredOne:
           return "The variable is not a stored property."
       case .variableHasSideEffects:
           return "The variable contains side effect similar to `willSet` or `didSet`"
       case .variableHasInitialValue:
           return "The variable cannot have an initial value."
        case .variableIsALetConstant:
        return "The variable cannot be declared as a let constant"
       }
    }
  }
}

// MARK: - Constants

private extension DependencyMacro {
  enum Constants {
    static var underlyingObject: String { "DependencyPropertyWrapper" }
  }
}
