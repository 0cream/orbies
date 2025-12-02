import ComposableArchitecture
import Foundation

extension HistoryMainFeature {
    @ObservableState
    struct State {
        var transactions: [ProcessedTransaction] = []
        
        var currentDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: Date())
        }
        
        var groupedTransactions: [(String, [ProcessedTransaction])] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            
            var groups: [String: [ProcessedTransaction]] = [:]
            
            for transaction in transactions {
                let txDate = calendar.startOfDay(for: transaction.date)
                
                let header: String
                if txDate == today {
                    header = "Today"
                } else if txDate == yesterday {
                    header = "Yesterday"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "d MMMM"
                    header = formatter.string(from: transaction.date)
                }
                
                groups[header, default: []].append(transaction)
            }
            
            // Sort groups by date (newest first)
            return groups.sorted { lhs, rhs in
                if lhs.key == "Today" { return true }
                if rhs.key == "Today" { return false }
                if lhs.key == "Yesterday" { return true }
                if rhs.key == "Yesterday" { return false }
                
                // Compare actual dates
                guard let lhsDate = lhs.value.first?.date,
                      let rhsDate = rhs.value.first?.date else {
                    return false
                }
                return lhsDate > rhsDate
            }
        }
    }
}

