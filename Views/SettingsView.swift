import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var playerName: String
    @State private var selectedDifficulty: DifficultyLevel
    @State private var showNameAlert = false
    
    // Audio settings
    @State private var isMusicOn = GameSettings.shared.isBackgroundMusicEnabled
    @State private var areSFXOn = GameSettings.shared.areSoundEffectsEnabled
    @State private var musicVolume = GameSettings.shared.musicVolume
    @State private var sfxVolume = GameSettings.shared.sfxVolume
    
    init() {
        _playerName = State(initialValue: GameSettings.shared.playerName)
        _selectedDifficulty = State(initialValue: GameSettings.shared.difficulty)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player")) {
                    HStack {
                        Text("Your Name")
                        Spacer()
                        Button(action: {
                            showNameAlert = true
                        }) {
                            Text(playerName)
                                .foregroundColor(.blue)
                        }
                    }
                    Text("This name will appear in game and statistics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Difficulty")) {
                    Picker("AI Difficulty", selection: $selectedDifficulty) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.rawValue)
                                Text("\(level.iterations) simulations")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(InlinePickerStyle())
                    .onChange(of: selectedDifficulty) {
                        GameSettings.shared.difficulty = selectedDifficulty
                    }
                }
                
                // Audio Section
                Section(header: Text("Audio")) {
                    // Music Toggle
                    Toggle("Background Music", isOn: $isMusicOn)
                        .onChange(of: isMusicOn) { newValue in
                            GameSettings.shared.isBackgroundMusicEnabled = newValue
                        }
                    
                    // Music Volume Slider
                    if isMusicOn {
                        HStack {
                            Text("Volume")
                                .foregroundColor(.secondary)
                            Slider(value: $musicVolume, in: 0...1, step: 0.1)
                                .onChange(of: musicVolume) { newValue in
                                    GameSettings.shared.musicVolume = newValue
                                }
                            Text("\(Int(musicVolume * 100))%")
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }
                    
                    // Sound Effects Toggle
                    Toggle("Sound Effects", isOn: $areSFXOn)
                        .onChange(of: areSFXOn) { newValue in
                            GameSettings.shared.areSoundEffectsEnabled = newValue
                        }
                    
                    // SFX Volume Slider
                    if areSFXOn {
                        HStack {
                            Text("Volume")
                                .foregroundColor(.secondary)
                            Slider(value: $sfxVolume, in: 0...1, step: 0.1)
                                .onChange(of: sfxVolume) { newValue in
                                    GameSettings.shared.sfxVolume = newValue
                                    // Play test sound for feedback
                                    SoundManager.shared.playCardSound()
                                }
                            Text("\(Int(sfxVolume * 100))%")
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Game")
                        Spacer()
                        Text("Hearts")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Change Your Name", isPresented: $showNameAlert) {
                TextField("Enter your name", text: $playerName)
                    .autocapitalization(.words)
                Button("Cancel", role: .cancel) {
                    playerName = GameSettings.shared.playerName
                }
                Button("Save") {
                    savePlayerName()
                }
            } message: {
                Text("Your stats will be preserved with your new name.")
            }
        }
    }
    
    private func savePlayerName() {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            GameSettings.shared.playerName = trimmedName
            playerName = trimmedName
        } else {
            playerName = GameSettings.shared.playerName
        }
    }
}

// MARK: - First Launch Name Prompt
struct FirstLaunchNamePrompt: View {
    @Binding var isPresented: Bool
    @State private var name: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Hearts!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("What's your name?")
                .font(.title2)
            
            TextField("Enter your name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
                .autocapitalization(.words)
            
            Button(action: {
                saveName()
            }) {
                Text("Start Playing")
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 40)
            
            Button("Skip (use 'You')") {
                GameSettings.shared.playerName = "You"
                isPresented = false
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func saveName() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            GameSettings.shared.playerName = trimmedName
        }
        isPresented = false
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
