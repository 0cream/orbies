import Foundation
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftDiagnostics
import XCTest
@testable import DependencyMacros

private let dependencyInjectionMacros: [String: Macro.Type] = [
  "Dependency": DependencyMacro.self
]

final class AnalyticsEventMacroTests: XCTestCase {
  func testDependencyWithInstanceProperty() {
    assertMacroExpansion(
        """
        struct Service {
          @Dependency(\\.dependencyServiceKeyPath)
          private var dependencyService: DependencyService
        }
        """,
      expandedSource:
        """
        struct Service {
          private var dependencyService: DependencyService {
              get {
                  _dependencyService.wrappedValue
              }
          }

          private let _dependencyService = DependencyPropertyWrapper(\\.dependencyServiceKeyPath)
        }
        """,
      macros: dependencyInjectionMacros
    )
  }
  
  func testDependencyWithStaticProperty() {
    assertMacroExpansion(
        """
        struct Service {
          @Dependency(\\.dependencyServiceKeyPath)
          private static var dependencyService: DependencyService
        }
        """,
      expandedSource:
        """
        struct Service {
          private static var dependencyService: DependencyService {
              get {
                  _dependencyService.wrappedValue
              }
          }

          private static let _dependencyService = DependencyPropertyWrapper(\\.dependencyServiceKeyPath)
        }
        """,
      macros: dependencyInjectionMacros
    )
  }
}
