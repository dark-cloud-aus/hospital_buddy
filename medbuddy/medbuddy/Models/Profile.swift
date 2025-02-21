import Foundation

struct Profile: Codable {
    var name: String
    var dateOfBirth: Date
    var phoneNumber: String
    
    static let empty = Profile(name: "", dateOfBirth: Date(), phoneNumber: "")
} 