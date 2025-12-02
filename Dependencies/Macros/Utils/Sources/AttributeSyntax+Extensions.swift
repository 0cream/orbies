import Foundation
import SwiftSyntax

extension AttributeSyntax {
  public var argumentsList: [String: String] {
    var args: [String: String] = [:]
    arguments?.as(LabeledExprListSyntax.self)?.forEach {
      guard let name = $0.label?.text,
            let value = $0.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text else {
        return
      }
      args[name] = value
    }
    return args
  }
  
  public func argument<T: LiteralExpressable>(withName name: String) -> T? {
    arguments?.argument(withName: name)
  }
  
  public func argument<T: LiteralExpressable>(atIndex index: Int) -> T? {
    arguments?.argument(atIndex: index)
  }
}
