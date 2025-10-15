import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    
    private init() {
        configureAudioSession()
        preloadSounds()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured for playback.")
        } catch {
            print("⚠️ Failed to configure audio session:", error)
        }
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
        let extensions = ["mp3", "wav", "m4a"]
        for ext in extensions {
            if let path = Bundle.main.path(forResource: soundName, ofType: ext) {
                print("✅ Found sound file:", "\(soundName).\(ext)")
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
        print("❌ Could not find any file for sound:", soundName)
    }
    
    // MARK: - Play Sounds
    private func playSound(_ soundName: String) {
        guard let player = soundPlayers[soundName] else {
            print("⚠️ No preloaded player for sound:", soundName)
            return
        }
        player.currentTime = 0
        player.play()
    }
    
    // MARK: - Specific Game Sounds
    func playCardSound() { playSound("card_play") }
    func playHeartsBreakSound() { playSound("hearts_break") }
    func playQueenPlayedSound() { playSound("queen_played") }
    func playQueenWonSound() { playSound("queen_won") }
    func playShootMoonSound() { playSound("shoot_moon") }
    func playTrickWonSound() { playSound("trick_won") }
    func playRoundCompleteSound() { playSound("round_complete") }
    func playGameOverSound() { playSound("game_over") }
    func playButtonClickSound() { playSound("button_click") }
    func playCardPassSound() { playSound("card_pass") }
    
    // MARK: - Background Music
    func startBackgroundMusic() {
        guard musicPlayer == nil || musicPlayer?.isPlaying == false else { return }
        
        let musicFiles = ["background_music", "game_music", "hearts_music"]
        let extensions = ["mp3", "m4a", "wav"]
        
        for musicFile in musicFiles {
            for ext in extensions {
                if let path = Bundle.main.path(forResource: musicFile, ofType: ext) {
                    print("✅ Found background music:", "\(musicFile).\(ext)")
                    let url = URL(fileURLWithPath: path)
                    do {
                        musicPlayer = try AVAudioPlayer(contentsOf: url)
                        musicPlayer?.numberOfLoops = -1
                        musicPlayer?.volume = 0.3
                        musicPlayer?.play()
                        print("🎵 Background music started.")
                        return
                    } catch {
                        print("⚠️ Error loading background music \(musicFile).\(ext): \(error)")
                    }
                }
            }
        }
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
                if i == steps { self.stopBackgroundMusic() }
            }
        }
    }
}
