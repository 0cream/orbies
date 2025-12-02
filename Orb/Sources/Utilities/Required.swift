@propertyWrapper
struct Required<Value> {
    
    // MARK: - Properties
    
    var wrappedValue: Value {
        get {
            guard let value = value else {
                fatalError("Required value was accessed before being set")
            }
            return value
        }
        set {
            value = newValue
        }
    }
    
    // MARK: - Private Properties
    
    private var value: Value?
    
    // MARK: - Init
    
    init() {
        self.value = nil
    }
}
