import SFSafeSymbols
import SwiftUI

extension SFSymbol {
    var image: Image {
        Image(systemName: rawValue)
    }
    
    var uiImage: UIImage {
        UIImage(systemSymbol: self)
    }
}
