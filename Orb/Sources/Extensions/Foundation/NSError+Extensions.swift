import Foundation

typealias AppError = NSError

extension NSError {
    convenience init(message: String) {
        self.init(domain: "com.yegrec.inventory", code: 9999, userInfo: ["message": message])
    }
}
