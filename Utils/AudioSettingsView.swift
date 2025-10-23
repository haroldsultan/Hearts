import SwiftUI

struct AudioSettingsView: View {
    @State private var isMusicEnabled = GameSettings.shared.isBackgroundMusicEnabled
    @State private var areSFXEnabled = GameSettings.shared.areSoundEffectsEnabled
    @State private var musicVolume = GameSettings.shared.musicVolume
    @State private var sfxVolume = GameSettings.shared.sfxVolume
    
    var body: some View {
        Form {
            Section(header: Text("Background Music")) {
                Toggle("Enable Music", isOn: $isMusicEnabled)
                    .onChange(of: isMusicEnabled) { newValue in
                        GameSettings.shared.isBackgroundMusicEnabled = newValue
                    }
                
                if isMusicEnabled {
                    VStack(alignment: .leading) {
                        Text("Volume: \(Int(musicVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $musicVolume, in: 0...1, step: 0.1)
                            .onChange(of: musicVolume) { newValue in
                                GameSettings.shared.musicVolume = newValue
                            }
                    }
                }
            }
            
            Section(header: Text("Sound Effects")) {
                Toggle("Enable Sound Effects", isOn: $areSFXEnabled)
                    .onChange(of: areSFXEnabled) { newValue in
                        GameSettings.shared.areSoundEffectsEnabled = newValue
                    }
                
                if areSFXEnabled {
                    VStack(alignment: .leading) {
                        Text("Volume: \(Int(sfxVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $sfxVolume, in: 0...1, step: 0.1)
                            .onChange(of: sfxVolume) { newValue in
                                GameSettings.shared.sfxVolume = newValue
                                // Play a test sound
                                SoundManager.shared.playCardSound()
                            }
                    }
                }
            }
        }
        .navigationTitle("Audio Settings")
    }
}
