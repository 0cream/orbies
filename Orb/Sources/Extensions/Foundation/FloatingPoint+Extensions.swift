import Foundation

extension FloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(min(self, range.upperBound), range.lowerBound)
    }

    func normalized(to range: ClosedRange<Self>, clamping: Bool = false) -> Self {
        let normalized = (self - range.lowerBound) / (range.upperBound - range.lowerBound)
        return clamping ? normalized.clamped(to: Self(0)...Self(1)) : normalized
    }

    func denormalized(to range: ClosedRange<Self>) -> Self {
        range.lowerBound + self * (range.upperBound - range.lowerBound)
    }

    var signum: Self {
        if self > 0 { return 1 }
        else if self < 0 { return -1 }
        else { return 0 }
    }

    static func radians(_ degrees: Self) -> Self { degrees * .pi / 180 }
}

