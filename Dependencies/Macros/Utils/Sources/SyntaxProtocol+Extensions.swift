import Foundation
import SwiftSyntax

public extension SyntaxProtocol {
  var asCode: String { "\(self)".trimmingCharacters(in: .whitespacesAndNewlines) }
}

