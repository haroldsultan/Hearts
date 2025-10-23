import SwiftUI

@main
struct HeartsApp: App {
    init() {
        SoundManager.shared.startBackgroundMusic()
    }
    
    var body: some Scene {
        WindowGroup {
            GameView()
        }
    }
}
