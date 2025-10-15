import Foundation
import Combine

// MARK: - GameSettings Manager
class GameSettings {
    static let shared = GameSettings()
    private let userDefaults = UserDefaults.standard
    
    private let playerNameKey = "HeartsPlayerName"
    private let difficultyKey = "HeartsDifficultyLevel"
    
    private init() {}
    
    // MARK: - Player Name
    var playerName: String {
        get {
            return userDefaults.string(forKey: playerNameKey) ?? "You"
        }
        set {
            let oldName = playerName
            userDefaults.set(newValue, forKey: playerNameKey)
            
            // If name changed and not first time, migrate stats
            if oldName != newValue && oldName != "You" {
                migrateStats(from: oldName, to: newValue)
            } else if oldName == "You" && newValue != "You" {
                // Migrating from default "You" to custom name
                migrateStats(from: "You", to: newValue)
            }
        }
    }
    
    // MARK: - Difficulty Level
    var difficulty: DifficultyLevel {
        get {
            if let rawValue = userDefaults.string(forKey: difficultyKey),
               let level = DifficultyLevel(rawValue: rawValue) {
                return level
            }
            return .medium // Default
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: difficultyKey)
        }
    }
    
    // MARK: - First Launch
    var isFirstLaunch: Bool {
        let hasLaunchedKey = "HeartsHasLaunched"
        let hasLaunched = userDefaults.bool(forKey: hasLaunchedKey)
        
        if !hasLaunched {
            userDefaults.set(true, forKey: hasLaunchedKey)
            return true
        }
        return false
    }
    
    // MARK: - Stats Migration
    private func migrateStats(from oldName: String, to newName: String) {
        // Load stats from old name
        guard let oldData = userDefaults.data(forKey: "HeartsPlayerStats_\(oldName)"),
              var stats = try? JSONDecoder().decode(PlayerStats.self, from: oldData) else {
            return
        }
        
        // Update the player name in the stats
        stats.playerName = newName
        
        // Save under new name
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults.set(encoded, forKey: "HeartsPlayerStats_\(newName)")
        }
        
        // Remove old stats
        userDefaults.removeObject(forKey: "HeartsPlayerStats_\(oldName)")
    }
}
