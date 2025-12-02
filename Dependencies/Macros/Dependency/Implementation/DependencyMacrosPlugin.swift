import Foundation
import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct DependencyMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    DependencyMacro.self
  ]
}
