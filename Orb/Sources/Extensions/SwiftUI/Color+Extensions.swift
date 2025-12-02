import SwiftUI

extension Color {
    init(rgb: Int) {
        self.init(uiColor: UIColor(rgb: rgb))
    }
}
