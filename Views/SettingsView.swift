import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var playerName: String
    @State private var selectedDifficulty: DifficultyLevel
    @State private var showNameAlert = false
    
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
                    .onChange(of: selectedDifficulty) { newValue in
                        GameSettings.shared.difficulty = newValue
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
