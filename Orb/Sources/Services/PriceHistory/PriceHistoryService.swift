import Dependencies
import Foundation

protocol PriceHistoryService: Actor {
    func setup() async
    func getPriceHistory(for tokenId: String) async -> [PricePoint]
    func appendPrice(for tokenId: String, price: Double, timestamp: Date?) async
}

actor LivePriceHistoryService: PriceHistoryService {
    
    // MARK: - Private Properties
    
    private var priceHistories: [String: [PricePoint]] = [:]
    
    // MARK: - Methods
    
    func setup() async {
        // Price histories are now fetched from backend via PortfolioHistoryService
        // This service only manages real-time WebSocket price updates
        print("📊 PriceHistoryService: Ready (using real price data from backend)")
    }
    
    func getPriceHistory(for tokenId: String) async -> [PricePoint] {
        return priceHistories[tokenId] ?? []
    }
    
    func appendPrice(for tokenId: String, price: Double, timestamp: Date? = nil) async {
        let timestamp = timestamp ?? Date()
        let calendar = Calendar.current
        
        // Get or create history for this token
        var history = priceHistories[tokenId] ?? []
        
        // Check if we should update the last point or add a new one
        if let lastPoint = history.last {
            // Get second components for both timestamps
            let lastSecond = calendar.component(.second, from: lastPoint.timestamp)
            let currentSecond = calendar.component(.second, from: timestamp)
            let lastMinute = calendar.component(.minute, from: lastPoint.timestamp)
            let currentMinute = calendar.component(.minute, from: timestamp)
            let lastHour = calendar.component(.hour, from: lastPoint.timestamp)
            let currentHour = calendar.component(.hour, from: timestamp)
            let lastDay = calendar.component(.day, from: lastPoint.timestamp)
            let currentDay = calendar.component(.day, from: timestamp)
            
            // If we're still in the same second, update the last point
            if lastSecond == currentSecond && lastMinute == currentMinute && lastHour == currentHour && lastDay == currentDay {
                history[history.count - 1] = PricePoint(timestamp: timestamp, price: price)
            } else {
                // New second, add new point
                history.append(PricePoint(timestamp: timestamp, price: price))
            }
        } else {
            // No history yet, add first point
            history.append(PricePoint(timestamp: timestamp, price: price))
        }
        
        // Keep only last day of data
        let cutoff = timestamp.addingTimeInterval(-86400)
        history.removeAll { $0.timestamp < cutoff }
        
        priceHistories[tokenId] = history
    }
    
    // MARK: - Private Methods
    
    private func generateInitialPriceHistory(currentPrice: Double) -> [PricePoint] {
        var history: [PricePoint] = []
        let now = Date()
        
        // Start from a price slightly different from current (±20%)
        var price = currentPrice * Double.random(in: 0.8...1.2)
        
        // Generate with granular data for recent times, sparse for older
        // Total: ~400 points (performant and smooth)
        
        // 1. Day ago to hour ago: every 10 minutes (~138 points)
        let dayAgo = now.addingTimeInterval(-86400) // 24 hours
        let hourAgo = now.addingTimeInterval(-3600) // 1 hour
        var currentTime = dayAgo
        
        while currentTime < hourAgo {
            let change = price * Double.random(in: -0.005...0.005)
            price += change
            price = max(currentPrice * 0.5, min(currentPrice * 1.5, price))
            history.append(PricePoint(timestamp: currentTime, price: price))
            currentTime = currentTime.addingTimeInterval(600) // 10 minutes
        }
        
        // 2. Last hour to last minute: every minute, gradually converge to currentPrice (~59 points)
        let minuteAgo = now.addingTimeInterval(-60) // 1 minute ago
        currentTime = hourAgo
        var minuteCount = 0
        let totalMinutes = 59
        
        while currentTime < minuteAgo {
            // Gradually blend towards currentPrice
            let progress = Double(minuteCount) / Double(totalMinutes)
            let targetPrice = price * (1 - progress) + currentPrice * progress
            
            // Add small random fluctuation
            let fluctuation = targetPrice * Double.random(in: -0.002...0.002)
            price = targetPrice + fluctuation
            
            history.append(PricePoint(timestamp: currentTime, price: price))
            currentTime = currentTime.addingTimeInterval(60) // 1 minute
            minuteCount += 1
        }
        
        // 3. Last minute: every second, gradually converge to currentPrice (60 points)
        currentTime = minuteAgo
        var secondCount = 0
        let totalSeconds = 60
        
        while currentTime <= now {
            // Gradually blend towards currentPrice
            let progress = Double(secondCount) / Double(totalSeconds)
            let targetPrice = price * (1 - progress) + currentPrice * progress
            
            // Add tiny random fluctuation
            let fluctuation = targetPrice * Double.random(in: -0.001...0.001)
            price = targetPrice + fluctuation
            
            history.append(PricePoint(timestamp: currentTime, price: price))
            currentTime = currentTime.addingTimeInterval(1) // 1 second
            secondCount += 1
        }
        
        // Ensure the last point is exactly the current price at current time
        if let lastPoint = history.last, lastPoint.timestamp < now {
            history.append(PricePoint(timestamp: now, price: currentPrice))
        } else if history.last?.price != currentPrice {
            history[history.count - 1] = PricePoint(timestamp: now, price: currentPrice)
        }
        
        return history
    }
}

struct PricePoint: Equatable {
    let timestamp: Date
    let price: Double
}

// MARK: - Dependency

extension DependencyValues {
    var priceHistoryService: PriceHistoryService {
        get { self[PriceHistoryServiceKey.self] }
        set { self[PriceHistoryServiceKey.self] = newValue }
    }
}

private enum PriceHistoryServiceKey: DependencyKey {
    static let liveValue: PriceHistoryService = LivePriceHistoryService()
}

