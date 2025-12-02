import Foundation
import SwiftSyntax

public extension AttributeSyntax.Arguments {
  func argument<T: LiteralExpressable>(withName name: String) -> T? {
    let literalExpression = self.as(LabeledExprListSyntax.self)?
      .first { $0.label?.text == name }?
      .expression.as(T.LiteralExpressionType.self)
    return literalExpression.flatMap(T.make(fromLiteralExpression:))
  }
  
  func argument<T: LiteralExpressable>(atIndex index: Int) -> T? {
    let literalExpression = self.as(LabeledExprListSyntax.self)?.enumerated()
      .first { $0.offset == index }?.element
      .expression.as(T.LiteralExpressionType.self)
    return literalExpression.flatMap(T.make(fromLiteralExpression:))
  }
}
