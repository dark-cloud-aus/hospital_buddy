import Foundation

class SummariesStore: ObservableObject {
    static let shared = SummariesStore()
    
    @Published private(set) var summaries: [Summary] = []
    private let defaults = UserDefaults.standard
    private let summariesKey = "stored_summaries"
    
    private init() {
        loadSummaries()
    }
    
    func addSummary(_ text: String) {
        let summary = Summary(text: text)
        summaries.insert(summary, at: 0) // Add to beginning of array
        saveSummaries()
    }
    
    private func loadSummaries() {
        if let data = defaults.data(forKey: summariesKey),
           let decoded = try? JSONDecoder().decode([Summary].self, from: data) {
            summaries = decoded.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    private func saveSummaries() {
        if let encoded = try? JSONEncoder().encode(summaries) {
            defaults.set(encoded, forKey: summariesKey)
        }
    }
} 
