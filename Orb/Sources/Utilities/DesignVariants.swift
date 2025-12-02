import UIKit

/// Returns the value of one of the three design variant arguments based on the design variant of the current device.
func v<T>(m max: T, n normal: T, s small: T) -> T { vImpl(max, normal, small, small) }

/// Returns the value of one of the three design variant arguments based on the design variant of the current device.
func v<T>(mn maxNormal: T, s small: T) -> T { vImpl(maxNormal, maxNormal, small, small) }

/// Returns the value of one of the three design variant arguments based on the design variant of the current device.
func v<T>(m max: T, ns normalSmall: T) -> T { vImpl(max, normalSmall, normalSmall, normalSmall) }

/// Returns the value of one of the three design variant arguments based on the design variant of the current device.
func v<T>(x: T, v8: T, v4: T) -> T { vImpl(x, x, v8, v4) }

/// Returns the value of one of the two design variant arguments based on the design variant of the current device.
func v<T>(x8: T, v4: T) -> T { vImpl(x8, x8, x8, v4) }

/// Returns the value of one of the two design variant arguments based on the design variant of the current device.
func v<T>(x: T, v8v4: T) -> T { vImpl(x, x, v8v4, v8v4) }

/// Returns the value for the design variant of the current device, following the pattern: same value for the X
/// and 8 variants, and a 0.75x reduction for the 4 variant.
func v(x8: CGFloat) -> CGFloat { vImpl(x8, x8, x8, x8 * 0.75) }

/// Returns the value for the design variant of the current device, following the pattern most commonly used when
/// sizing UI elements: 0.85x reduction for 8 variant, and a 0.75x reduction for the 4 variant.
func v(x: CGFloat) -> CGFloat { vImpl(x, x, x * 0.85, x * 0.75) }

private func vImpl<T>(_ max: T, _ x: T, _ v8: T, _ v4: T) -> T {
    let screenSize = UIScreen.main.bounds.size
    
    // iPhone 5s, SE, 4s
    if screenSize.height <= 568 {
        return v4
    }
    
    // iPhone 6,+, 6s+, 7+, 8+, 6, 6s, 7, 8
    if screenSize.height <= 736 {
        return v8
    }
    
    if screenSize.height <= 896 {
        return x
    }
    
    return max
}

func vw(x: CGFloat) -> CGFloat { vwImpl(x, x, x * 0.85, x * 0.75) }

/// Returns the value of one of the three design variant arguments based on the width of the current device.
func vw<T>(m max: T, n normal: T, s small: T) -> T { vwImpl(max, normal, small, small) }
func vw<T>(m max: T, ns: T) -> T { vwImpl(max, ns, ns, ns) }

func vw<T>(x: T, v8v4: T) -> T { vwImpl(x, x, v8v4, v8v4) }

private func vwImpl<T>(_ max: T, _ x: T, _ v8: T, _ v4: T) -> T {
    let screenSize = UIScreen.main.bounds.size
    
    // iPhone 14 Plus, 14 Pro Max
    if screenSize.width >= 428 {
        return max
    }
    
    // iPhone 14, 14 Pro
    if screenSize.width >= 390 {
        return x
    }
    
    // iPhone XS, 8, 13 mini
    if screenSize.width >= 375 {
        return v8
    }
    
    return v4
}

/// Container for the values based on the width of the current device.
struct VW<T> {
    
    // MARK: - Properties
    
    let max: T
    let x: T
    let v8: T
    let v4: T
    
    // MARK: - Init
    
    init(max: T, normal: T, small: T) {
        self.max = max
        self.x = normal
        self.v8 = small
        self.v4 = small
    }
    
    // MARK: - Helpers
    
    var value: T {
        let screenSize = UIScreen.main.bounds.size
        
        // iPhone 14 Plus, 14 Pro Max
        if screenSize.width >= 428 {
            return max
        }
        
        // iPhone 14, 14 Pro
        if screenSize.width >= 390 {
            return x
        }
        
        // iPhone XS, 8, 13 mini
        if screenSize.width >= 375 {
            return v8
        }
        
        return v4
    }
}

