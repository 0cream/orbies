import Foundation
import SwiftSyntax

public protocol LiteralExpressable {
  associatedtype LiteralExpressionType: ExprSyntaxProtocol
  
  static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> Self?
}

// MARK: - Int

extension Int: LiteralExpressable {
  public typealias LiteralExpressionType = IntegerLiteralExprSyntax
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> Self? {
    Self(literalExpression.literal.text)
  }
}

// MARK: - UInt

extension UInt: LiteralExpressable {
  public typealias LiteralExpressionType = IntegerLiteralExprSyntax
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> Self? {
    Self(literalExpression.literal.text)
  }
}

// MARK: - Double

extension Double: LiteralExpressable {
  public typealias LiteralExpressionType = FloatLiteralExprSyntax
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> Self? {
    Self(literalExpression.literal.text)
  }
}

// MARK: - Float

extension Float: LiteralExpressable {
  public typealias LiteralExpressionType = FloatLiteralExprSyntax
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> Self? {
    Self(literalExpression.literal.text)
  }
}

// MARK: - Bool

extension Bool: LiteralExpressable {
  public typealias LiteralExpressionType = BooleanLiteralExprSyntax
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> Self? {
    switch ComparisonResult.orderedSame {
    case literalExpression.literal.text.caseInsensitiveCompare("true"):   true
    case literalExpression.literal.text.caseInsensitiveCompare("false"):  false
    default:                                                              nil
    }
  }
}

// MARK: - String

extension String: LiteralExpressable {
  public typealias LiteralExpressionType = StringLiteralExprSyntax
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> Self? {
    literalExpression.segments.reduce(into: "", { $0 += $1.as(StringSegmentSyntax.self)?.content.text ?? "" })
  }
}

// MARK: - MemberAccessExprSyntax

extension MemberAccessExprSyntax: LiteralExpressable {
  public typealias LiteralExpressionType = Self
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> LiteralExpressionType? {
    literalExpression
  }
}

// MARK: - DeclReferenceExprSyntax

extension DeclReferenceExprSyntax: LiteralExpressable {
  public typealias LiteralExpressionType = DeclReferenceExprSyntax
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> LiteralExpressionType? {
    literalExpression
  }
}

public struct RawExpression: LiteralExpressable {
  public typealias LiteralExpressionType = ExprSyntax
  
  public let expression: String
  
  public static func make(fromLiteralExpression literalExpression: LiteralExpressionType) -> RawExpression? {
    RawExpression(expression: literalExpression.asCode)
  }
}
