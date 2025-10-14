import Foundation

// MARK: - PlayerStats Model
struct PlayerStats: Codable {
    var playerName: String
    
    // Game-Level Stats
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalFinalScore: Int = 0  // Sum of all final scores
    var bestGame: Int? = nil       // Lowest final score
    var worstGame: Int? = nil      // Highest final score
    
    // Round-Level Stats
    var totalRoundsPlayed: Int = 0
    var roundsWon: Int = 0
    var cleanRounds: Int = 0       // Rounds with 0 points
    var totalRoundPoints: Int = 0  // Sum of all round points
    
    // Special Achievements
    var moonsShot: Int = 0
    var queensTaken: Int = 0
    
    // Computed Properties
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100.0
    }
    
    var averageFinalScore: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(totalFinalScore) / Double(gamesPlayed)
    }
    
    var averagePointsPerRound: Double {
        guard totalRoundsPlayed > 0 else { return 0.0 }
        return Double(totalRoundPoints) / Double(totalRoundsPlayed)
    }
    
    // Mutating functions to update stats
    mutating func recordRound(points: Int, wonRound: Bool, shotMoon: Bool, tookQueen: Bool) {
        totalRoundsPlayed += 1
        totalRoundPoints += points
        
        if wonRound {
            roundsWon += 1
        }
        
        if points == 0 {
            cleanRounds += 1
        }
        
        if shotMoon {
            moonsShot += 1
        }
        
        if tookQueen {
            queensTaken += 1
        }
    }
    
    mutating func recordGameEnd(finalScore: Int, wonGame: Bool) {
        gamesPlayed += 1
        totalFinalScore += finalScore
        
        if wonGame {
            gamesWon += 1
        }
        
        // Update best/worst game
        if let currentBest = bestGame {
            bestGame = min(currentBest, finalScore)
        } else {
            bestGame = finalScore
        }
        
        if let currentWorst = worstGame {
            worstGame = max(currentWorst, finalScore)
        } else {
            worstGame = finalScore
        }
    }
    
    mutating func reset() {
        gamesPlayed = 0
        gamesWon = 0
        totalFinalScore = 0
        bestGame = nil
        worstGame = nil
        totalRoundsPlayed = 0
        roundsWon = 0
        cleanRounds = 0
        totalRoundPoints = 0
        moonsShot = 0
        queensTaken = 0
    }
}

// MARK: - StatsManager
class StatsManager {
    static let shared = StatsManager()
    private let userDefaults = UserDefaults.standard
    private let statsKey = "HeartsPlayerStats"
    
    // Player names - gets current player name from settings
    private func getPlayerNames() -> [String] {
        return [GameSettings.shared.playerName, "Emma", "Abby", "Bob"]
    }
    
    private init() {}
    
    // MARK: - Load Stats
    func loadStats(for playerName: String) -> PlayerStats {
        guard let data = userDefaults.data(forKey: "\(statsKey)_\(playerName)"),
              let stats = try? JSONDecoder().decode(PlayerStats.self, from: data) else {
            // Return new stats if none exist
            return PlayerStats(playerName: playerName)
        }
        return stats
    }
    
    func loadAllStats() -> [PlayerStats] {
        return getPlayerNames().map { loadStats(for: $0) }
    }
    
    // MARK: - Save Stats
    func saveStats(_ stats: PlayerStats) {
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults.set(encoded, forKey: "\(statsKey)_\(stats.playerName)")
        }
    }
    
    func saveAllStats(_ allStats: [PlayerStats]) {
        for stats in allStats {
            saveStats(stats)
        }
    }
    
    // MARK: - Reset Stats
    func resetStats(for playerName: String) {
        var stats = loadStats(for: playerName)
        stats.reset()
        saveStats(stats)
    }
    
    func resetAllStats() {
        for name in getPlayerNames() {
            resetStats(for: name)
        }
    }
    
    // MARK: - Update Stats (Helper Methods)
    func recordRoundForPlayer(
        playerName: String,
        points: Int,
        wonRound: Bool,
        shotMoon: Bool,
        tookQueen: Bool
    ) {
        var stats = loadStats(for: playerName)
        stats.recordRound(
            points: points,
            wonRound: wonRound,
            shotMoon: shotMoon,
            tookQueen: tookQueen
        )
        saveStats(stats)
    }
    
    func recordGameEndForPlayer(
        playerName: String,
        finalScore: Int,
        wonGame: Bool
    ) {
        var stats = loadStats(for: playerName)
        stats.recordGameEnd(finalScore: finalScore, wonGame: wonGame)
        saveStats(stats)
    }
}
