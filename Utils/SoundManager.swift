import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    
    private init() {
        // Preload sound effects for better performance
        preloadSounds()
    }
    
    // MARK: - Preload Sounds
    
    private func preloadSounds() {
        let soundFiles = [
            "card_play",
            "hearts_break",
            "queen_played",
            "queen_won",
            "shoot_moon",
            "trick_won",
            "round_complete",
            "game_over",
            "button_click",
            "card_pass"
        ]
        
        for sound in soundFiles {
            loadSound(named: sound)
        }
    }
    
    private func loadSound(named soundName: String) {
        // Try different file extensions
        let extensions = ["mp3", "wav", "m4a"]
        
        for ext in extensions {
            if let path = Bundle.main.path(forResource: soundName, ofType: ext) {
                let url = URL(fileURLWithPath: path)
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    soundPlayers[soundName] = player
                    return
                } catch {
                    print("⚠️ Error loading sound \(soundName).\(ext): \(error)")
                }
            }
        }
        
        // If no sound file found, that's okay - the game will work without it
    }
    
    // MARK: - Play Sounds
    
    private func playSound(_ soundName: String) {
        if let player = soundPlayers[soundName] {
            player.currentTime = 0
            player.play()
        }
    }
    
    // MARK: - Specific Game Sounds
    
    func playCardSound() {
        playSound("card_play")
    }
    
    func playHeartsBreakSound() {
        playSound("hearts_break")
    }
    
    func playQueenPlayedSound() {
        playSound("queen_played")
    }
    
    func playQueenWonSound() {
        playSound("queen_won")
    }
    
    func playShootMoonSound() {
        playSound("shoot_moon")
    }
    
    func playTrickWonSound() {
        playSound("trick_won")
    }
    
    func playRoundCompleteSound() {
        playSound("round_complete")
    }
    
    func playGameOverSound() {
        playSound("game_over")
    }
    
    func playButtonClickSound() {
        playSound("button_click")
    }
    
    func playCardPassSound() {
        playSound("card_pass")
    }
    
    // MARK: - Background Music
    
    func startBackgroundMusic() {
        // Don't start if already playing
        guard musicPlayer == nil || musicPlayer?.isPlaying == false else { return }
        
        // Try to find background music file
        let musicFiles = ["background_music", "game_music", "hearts_music"]
        
        for musicFile in musicFiles {
            let extensions = ["mp3", "m4a", "wav"]
            
            for ext in extensions {
                if let path = Bundle.main.path(forResource: musicFile, ofType: ext) {
                    let url = URL(fileURLWithPath: path)
                    do {
                        musicPlayer = try AVAudioPlayer(contentsOf: url)
                        musicPlayer?.numberOfLoops = -1  // Loop forever
                        musicPlayer?.volume = 0.3        // Quieter than sound effects
                        musicPlayer?.play()
                        print("✅ Background music started: \(musicFile).\(ext)")
                        return
                    } catch {
                        print("⚠️ Error loading background music \(musicFile).\(ext): \(error)")
                    }
                }
            }
        }
        
        // If no music file found, that's okay - game works without it
        print("ℹ️ No background music file found (optional)")
    }
    
    func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }
    
    func fadeOutBackgroundMusic(duration: TimeInterval = 1.0) {
        guard let player = musicPlayer, player.isPlaying else { return }
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume -= volumeStep
                
                if i == steps {
                    self.stopBackgroundMusic()
                }
            }
        }
    }
}
