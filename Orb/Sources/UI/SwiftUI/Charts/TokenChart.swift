import SwiftUI

struct OptimizedChart<Label: View>: View {
    let dataProvider: TokenLineChartDataProvider
    let accentColor: Color
    let numberOfLabels: Int
    let axisLabel: (Double) -> Label
    let useSmoothedSelection: Bool
    let onHighlightChange: (LineChartValue?) -> Void
    @State var highlightedValue: LineChartValue?
    
    private let chartHeight: CGFloat = 120
    private let labelHeight: CGFloat = 20
    private let topPadding: CGFloat = 8
    private let bottomPadding: CGFloat = 8
    private let snapThreshold: CGFloat = 10
    
    @State private var lastSnappedValue: LineChartValue?
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    ChartContent(
                        dataProvider: dataProvider,
                        accentColor: accentColor,
                        highlightedValue: $highlightedValue,
                        topPadding: topPadding,
                        bottomPadding: bottomPadding
                    )
                    .drawingGroup()
                    
                    HighlightOverlay(
                        dataProvider: dataProvider,
                        accentColor: accentColor,
                        highlightedValue: $highlightedValue,
                        topPadding: topPadding,
                        bottomPadding: bottomPadding
                    )
                    .drawingGroup()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateHighlightedValue(at: value.location, in: geometry)
                        }
                        .onEnded { _ in
                            highlightedValue = nil
                            lastSnappedValue = nil
                            onHighlightChange(nil)
                        }
                )
            }
            .frame(height: chartHeight)
            
            ChartLabels(
                dataProvider: dataProvider,
                numberOfLabels: numberOfLabels,
                axisLabel: axisLabel
            )
            .frame(height: labelHeight)
            .padding(.top, 12)
        }
        .frame(height: chartHeight + labelHeight)
        .onAppear {
            lightImpact.prepare()
            mediumImpact.prepare()
        }
    }
    
    private func updateHighlightedValue(at location: CGPoint, in geometry: GeometryProxy) {
        let chartRect = CGRect(
            x: 0,
            y: topPadding,
            width: geometry.size.width,
            height: geometry.size.height - topPadding - bottomPadding
        )
        var newValue: LineChartValue?
        
        if useSmoothedSelection {
            newValue = findClosestValueOnLine(at: location, in: chartRect)
        } else {
            newValue = findClosestDataValue(at: location, in: chartRect)
        }
        
        if var newValue = newValue {
            let data = dataProvider.data()
            if let snappedValue = ChartUtilities.findNearestDataPoint(
                to: newValue,
                in: data,
                threshold: snapThreshold / geometry.size.width
            ) {
                newValue = snappedValue
                if snappedValue != lastSnappedValue {
                    mediumImpact.impactOccurred()
                    lastSnappedValue = snappedValue
                }
            } else {
                if useSmoothedSelection {
                    lightImpact.impactOccurred()
                }
                lastSnappedValue = nil
            }
        }
        
        highlightedValue = newValue
        onHighlightChange(newValue)
    }
    
    private func findClosestDataValue(at location: CGPoint, in chartRect: CGRect) -> LineChartValue? {
        let data = dataProvider.data()
        return data.min(by: {
            abs(ChartUtilities.xPosition(for: $0, in: chartRect, data: data) - location.x) <
            abs(ChartUtilities.xPosition(for: $1, in: chartRect, data: data) - location.x)
        })
    }
    
    private func findClosestValueOnLine(at location: CGPoint, in chartRect: CGRect) -> LineChartValue? {
        let data = dataProvider.data()
        guard let firstValue = data.first, let lastValue = data.last else { return nil }
        
        let minX = ChartUtilities.xPosition(for: firstValue, in: chartRect, data: data)
        let maxX = ChartUtilities.xPosition(for: lastValue, in: chartRect, data: data)
        let clampedX = max(minX, min(maxX, location.x))
        
        let normalizedX = (clampedX - minX) / (maxX - minX)
        let interpolatedX = firstValue.x + normalizedX * (lastValue.x - firstValue.x)
        
        let interpolatedY = ChartUtilities.interpolateYValue(at: interpolatedX, data: data)
        
        return LineChartValue(x: interpolatedX, y: interpolatedY)
    }
}

struct ChartContent: View {
    let dataProvider: TokenLineChartDataProvider
    let accentColor: Color
    @Binding var highlightedValue: LineChartValue?
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let chartRect = CGRect(
                x: 0,
                y: topPadding,
                width: geometry.size.width,
                height: geometry.size.height - topPadding - bottomPadding
            )
            let data = dataProvider.data()
            
            ZStack {
                if let highlightedValue = highlightedValue {
                    let highlightX = ChartUtilities.xPosition(for: highlightedValue, in: chartRect, data: data)
                    
                    // Left gradient (accent color)
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor.opacity(0.3), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .mask(
                        gradientMask(in: chartRect, highlightX: highlightX, isLeft: true)
                    )
                    
                    // Right gradient (gray)
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .mask(
                        gradientMask(in: chartRect, highlightX: highlightX, isLeft: false)
                    )
                    
                    // Left line (accent color)
                    linePath(in: chartRect, highlightX: highlightX, isLeft: true)
                        .stroke(accentColor, lineWidth: 2)
                    
                    // Right line (gray)
                    linePath(in: chartRect, highlightX: highlightX, isLeft: false)
                        .stroke(Color.gray, lineWidth: 2)
                } else {
                    // Full gradient (accent color)
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor.opacity(0.3), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .mask(
                        gradientMask(in: chartRect, highlightX: nil, isLeft: true)
                    )
                    
                    // Full line (accent color)
                    linePath(in: chartRect, highlightX: nil, isLeft: true)
                        .stroke(accentColor, lineWidth: 2)
                }
            }
        }
    }
    
    private func gradientMask(in rect: CGRect, highlightX: CGFloat?, isLeft: Bool) -> Path {
        Path { path in
            let data = dataProvider.data()
            
            path.move(to: CGPoint(x: isLeft ? rect.minX : (highlightX ?? rect.maxX), y: rect.maxY))
            
            for value in data {
                let x = ChartUtilities.xPosition(for: value, in: rect, data: data)
                let y = ChartUtilities.yPosition(
                    for: value,
                    in: rect,
                    data: data,
                    topPadding: topPadding,
                    bottomPadding: bottomPadding
                )
                
                if let highlightX = highlightX {
                    if (isLeft && x <= highlightX) || (!isLeft && x >= highlightX) {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            if let highlightX = highlightX {
                path.addLine(to: CGPoint(x: isLeft ? highlightX : rect.maxX, y: rect.maxY))
            } else {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            path.closeSubpath()
        }
    }
    
    private func linePath(in rect: CGRect, highlightX: CGFloat?, isLeft: Bool) -> Path {
        Path { path in
            let data = dataProvider.data()
            
            var started = false
            for value in data {
                let x = ChartUtilities.xPosition(for: value, in: rect, data: data)
                let y = ChartUtilities.yPosition(
                    for: value,
                    in: rect,
                    data: data,
                    topPadding: topPadding,
                    bottomPadding: bottomPadding
                )
                
                if let highlightX = highlightX {
                    if (isLeft && x <= highlightX) || (!isLeft && x >= highlightX) {
                        if !started {
                            path.move(to: CGPoint(x: x, y: y))
                            started = true
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                } else {
                    if !started {
                        path.move(to: CGPoint(x: x, y: y))
                        started = true
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
        }
    }
}

struct HighlightOverlay: View {
    let dataProvider: TokenLineChartDataProvider
    let accentColor: Color
    @Binding var highlightedValue: LineChartValue?
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            if let highlightedValue = highlightedValue {
                let data = dataProvider.data()
                let chartRect = CGRect(
                    x: 0,
                    y: topPadding,
                    width: geometry.size.width,
                    height: geometry.size.height - topPadding - bottomPadding
                )
                let x = ChartUtilities.xPosition(for: highlightedValue, in: chartRect, data: data)
                let y = ChartUtilities.yPosition(
                    for: highlightedValue,
                    in: chartRect,
                    data: data,
                    topPadding: topPadding,
                    bottomPadding: bottomPadding
                )
                
                ZStack {
                    // Vertical line
                    Path { path in
                        path.move(to: CGPoint(x: x, y: chartRect.minY))
                        path.addLine(to: CGPoint(x: x, y: chartRect.maxY))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundColor(accentColor)
                    
                    // Highlight point
                    Circle()
                        .fill(accentColor)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .position(x: x, y: y)
                }
            }
        }
    }
}

struct ChartLabels<Label: View>: View {
    let dataProvider: TokenLineChartDataProvider
    let numberOfLabels: Int
    let axisLabel: (Double) -> Label
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(0..<numberOfLabels, id: \.self) { index in
                    let normalizedPosition = CGFloat(index) / CGFloat(numberOfLabels - 1)
                    let xValue = xValueForNormalizedPosition(normalizedPosition)
                    
                    axisLabel(xValue)
                        .position(
                            x: normalizedPosition * geometry.size.width,
                            y: 10
                        )
                }
            }
        }
        .frame(height: 20)
    }
    
    private func xValueForNormalizedPosition(_ position: CGFloat) -> Double {
        let data = dataProvider.data()
        guard let minX = data.map({ $0.x }).min(), let maxX = data.map({ $0.x }).max() else {
            return 0
        }
        
        return minX + (maxX - minX) * Double(position)
    }
}

