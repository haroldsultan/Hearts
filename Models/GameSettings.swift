import Foundation
import Combine

// MARK: - GameSettings Manager
class GameSettings {
    static let shared = GameSettings()
    private let userDefaults = UserDefaults.standard
    
    private let playerNameKey = "HeartsPlayerName"
    private let difficultyKey = "HeartsDifficultyLevel"
    private let backgroundMusicEnabledKey = "HeartsBackgroundMusicEnabled"
    private let soundEffectsEnabledKey = "HeartsSoundEffectsEnabled"
    private let musicVolumeKey = "HeartsMusicVolume"
    private let sfxVolumeKey = "HeartsSFXVolume"
    
    private init() {}
    
    // MARK: - Player Name
    var playerName: String {
        get {
            return userDefaults.string(forKey: playerNameKey) ?? "You"
        }
        set {
            let oldName = playerName
            userDefaults.set(newValue, forKey: playerNameKey)
            
            if oldName != newValue && oldName != "You" {
                migrateStats(from: oldName, to: newValue)
            } else if oldName == "You" && newValue != "You" {
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
            return .medium
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: difficultyKey)
        }
    }
    
    // MARK: - Audio Settings
    var isBackgroundMusicEnabled: Bool {
        get {
            // Default to true if not set
            if userDefaults.object(forKey: backgroundMusicEnabledKey) == nil {
                return true
            }
            return userDefaults.bool(forKey: backgroundMusicEnabledKey)
        }
        set {
            userDefaults.set(newValue, forKey: backgroundMusicEnabledKey)
            // Apply immediately
            if newValue {
                SoundManager.shared.startBackgroundMusic()
            } else {
                SoundManager.shared.stopBackgroundMusic()
            }
        }
    }
    
    var areSoundEffectsEnabled: Bool {
        get {
            if userDefaults.object(forKey: soundEffectsEnabledKey) == nil {
                return true
            }
            return userDefaults.bool(forKey: soundEffectsEnabledKey)
        }
        set {
            userDefaults.set(newValue, forKey: soundEffectsEnabledKey)
        }
    }
    
    var musicVolume: Float {
        get {
            if userDefaults.object(forKey: musicVolumeKey) == nil {
                return 0.3 // Default 30%
            }
            return userDefaults.float(forKey: musicVolumeKey)
        }
        set {
            let clampedValue = max(0.0, min(1.0, newValue))
            userDefaults.set(clampedValue, forKey: musicVolumeKey)
            SoundManager.shared.setMusicVolume(clampedValue)
        }
    }
    
    var sfxVolume: Float {
        get {
            if userDefaults.object(forKey: sfxVolumeKey) == nil {
                return 1.0 // Default 100%
            }
            return userDefaults.float(forKey: sfxVolumeKey)
        }
        set {
            let clampedValue = max(0.0, min(1.0, newValue))
            userDefaults.set(clampedValue, forKey: sfxVolumeKey)
            SoundManager.shared.setSFXVolume(clampedValue)
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
        guard let oldData = userDefaults.data(forKey: "HeartsPlayerStats_\(oldName)"),
              var stats = try? JSONDecoder().decode(PlayerStats.self, from: oldData) else {
            return
        }
        
        stats.playerName = newName
        
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults.set(encoded, forKey: "HeartsPlayerStats_\(newName)")
        }
        
        userDefaults.removeObject(forKey: "HeartsPlayerStats_\(oldName)")
    }
}
