import Foundation

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published private(set) var profile: Profile = Profile.empty
    private let defaults = UserDefaults.standard
    private let profileKey = "user_profile"
    
    private init() {
        loadProfile()
    }
    
    func updateProfile(_ newProfile: Profile) {
        profile = newProfile
        saveProfile()
    }
    
    private func loadProfile() {
        if let data = defaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(Profile.self, from: data) {
            profile = decoded
        }
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            defaults.set(encoded, forKey: profileKey)
        }
    }
} 