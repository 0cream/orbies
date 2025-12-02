import SwiftUI

struct LineChartValue: Equatable, Hashable {
    let x: Double
    let y: Double
}

struct ChartUtilities {
    static func xPosition(for value: LineChartValue, in rect: CGRect, data: [LineChartValue]) -> CGFloat {
        guard let minX = data.map({ $0.x }).min(), let maxX = data.map({ $0.x }).max(), minX != maxX else {
            return rect.minX
        }
        
        let normalizedX = (value.x - minX) / (maxX - minX)
        return rect.minX + CGFloat(normalizedX) * rect.width
    }
    
    static func yPosition(for value: LineChartValue, in rect: CGRect, data: [LineChartValue], topPadding: CGFloat, bottomPadding: CGFloat) -> CGFloat {
        guard let minY = data.map({ $0.y }).min(), let maxY = data.map({ $0.y }).max(), minY != maxY else {
            return rect.midY
        }
        
        let availableHeight = rect.height - topPadding - bottomPadding
        let normalizedY = (value.y - minY) / (maxY - minY)
        return rect.maxY - bottomPadding - (CGFloat(normalizedY) * availableHeight)
    }
    
    static func interpolateYValue(at x: Double, data: [LineChartValue]) -> Double {
        for i in 0..<(data.count - 1) {
            let currentValue = data[i]
            let nextValue = data[i + 1]
            
            if x >= currentValue.x && x <= nextValue.x {
                let progress = (x - currentValue.x) / (nextValue.x - currentValue.x)
                return currentValue.y + progress * (nextValue.y - currentValue.y)
            }
        }
        
        return 0
    }
    
    static func findNearestDataPoint(to value: LineChartValue, in data: [LineChartValue], threshold: CGFloat) -> LineChartValue? {
        return data.min { (a, b) in
            abs(a.x - value.x) < abs(b.x - value.x)
        }.flatMap { nearest in
            abs(nearest.x - value.x) <= threshold ? nearest : nil
        }
    }
}

