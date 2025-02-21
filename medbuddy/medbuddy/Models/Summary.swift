import Foundation

struct Summary: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    
    init(text: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
    }
} 