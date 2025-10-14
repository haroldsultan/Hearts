import SwiftUI
import Combine

struct GameView: View {
    @StateObject var viewModel = GameViewModel()
    @State private var showDifficultyPicker = false
    @State private var showStatsView = false
    @State private var showSettingsView = false
    @State private var showFirstLaunchPrompt = false
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            if viewModel.isGameOver {
                gameOverScreen
            } else if !viewModel.gameStarted && !viewModel.isPassing {
                roundCompleteScreen
            } else {
                // Combined screen for both playing and passing (with overlay for passing)
                playingAndPassingContent
            }
            
            // --- TOP BAR: New Game + Difficulty ---
            if !viewModel.isGameOver {
                ZStack {
                    // New Game button - left top corner
                    VStack {
                        HStack(spacing: 8) {
                            Button("New Game") {
                                viewModel.startNewGame()
                            }
                            .font(.caption)
                            .padding(8)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            // Settings button
                            Button(action: {
                                showSettingsView = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.leading, 10)
                    
                    // Difficulty button - right top corner
                    VStack {
                        HStack(spacing: 8) {
                            Spacer()
                            
                            // Stats button
                            Button(action: {
                                showStatsView = true
                            }) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
            }
            
            // Difficulty Picker Overlay
            if showDifficultyPicker {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDifficultyPicker = false
                    }
                
                VStack(spacing: 20) {
                    Text("AI Difficulty")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Button(action: {
                                viewModel.difficulty = level
                                showDifficultyPicker = false
                            }) {
                                HStack {
                                    Text(level.description)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if viewModel.difficulty == level {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(
                                    viewModel.difficulty == level ?
                                    Color.blue.opacity(0.8) :
                                    Color.gray.opacity(0.6)
                                )
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Button("Close") {
                        showDifficultyPicker = false
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.black.opacity(0.9))
                .cornerRadius(20)
                .frame(width: 300)
            }
        }
        .sheet(isPresented: $showStatsView) {
            StatsView()
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showFirstLaunchPrompt) {
            FirstLaunchNamePrompt(isPresented: $showFirstLaunchPrompt)
                .onDisappear {
                    // Update player name after first launch setup
                    updatePlayerName()
                }
        }
        .onAppear {
            // Check for first launch
            if GameSettings.shared.isFirstLaunch {
                showFirstLaunchPrompt = true
            }
            // Update player name in case it changed in settings
            updatePlayerName()
        }
    }
    
    private func updatePlayerName() {
        // Update the human player's name from settings
        viewModel.updatePlayerName()
    }
    
    // MARK: - Game Over Screen
    var gameOverScreen: some View {
        VStack(spacing: 30) {
            Text("Game Over!")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
            
            let winner = viewModel.players.min(by: { $0.score < $1.score })!
            
            Text("\(winner.name) Wins!")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            
            VStack(spacing: 15) {
                Text("Final Scores:")
                    .font(.title2)
                    .foregroundColor(.white)
                
                ForEach(viewModel.players.sorted(by: { $0.score < $1.score }), id: \.name) { player in
                    HStack {
                        Text(player.name)
                            .foregroundColor(.white)
                            .frame(width: 100, alignment: .leading)
                        
                        Spacer()
                        
                        Text("\(player.score) points")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            // Difficulty selector on game over screen
            VStack(spacing: 10) {
                Text("AI Difficulty for Next Game")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Picker("Difficulty", selection: $viewModel.difficulty) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 40)
            }
            .padding(.top, 10)
            
            Button("New Game") {
                viewModel.startNewGame()
            }
            .font(.title2)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Round Complete Screen
    var roundCompleteScreen: some View {
            VStack(spacing: 20) {
                Text("Round \(viewModel.roundNumber) Complete!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                // Show if someone shot the moon
                if let moonShooter = viewModel.players.first(where: { $0.shotTheMoon }) {
                    Text("\(moonShooter.name) SHOT THE MOON! 🌙")
                        .font(.title)
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
                
                VStack(spacing: 10) {
                    ForEach(0..<viewModel.players.count, id: \.self) { i in
                        HStack(spacing: 15) {
                            Text(viewModel.players[i].name)
                                .foregroundColor(.white)
                                .frame(width: 80, alignment: .leading)
                            
                            Text("This Round: +\(viewModel.players[i].lastRoundScore)")
                                .foregroundColor(viewModel.players[i].shotTheMoon ? .green : .yellow)
                                .frame(width: 150, alignment: .leading)
                            
                            Text("Total: \(viewModel.players[i].score)")
                                .foregroundColor(.white)
                                .font(.title3)
                                .frame(width: 80, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Button("Start Next Round") {
                    viewModel.setupGame()
                }
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 20)
            }
    }
    
    // MARK: - Playing and Passing Content (excluding the floating New Game button)
    var playingAndPassingContent: some View {
        let playerHand = viewModel.players[0].sortedHand
        let totalCardsInHand = playerHand.count
        let baseSpacing: CGFloat = 25
        let passingSpacing: CGFloat = 20
        let currentSpacing = viewModel.isPassing ? passingSpacing : baseSpacing
        
        let isFirstTrick = RuleValidator.isFirstTrick(players: viewModel.players)
        let legalCards = RuleValidator.getLegalCards(
            hand: playerHand,
            playedCards: viewModel.playedCards,
            heartsBroken: viewModel.heartsBroken,
            isFirstTrick: isFirstTrick
        )
        
        return VStack(spacing: 0) {
            // Top area with circle and player info
            ZStack {
                // Center circle
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 280, height: 280)
                
                // Player info boxes with absolute positions
                playerInfoView(index: 1, position: .left)    // Emma
                    .position(x: 40, y: 225)
                playerInfoView(index: 2, position: .top)     // Abby
                    .position(x: 196, y: 50)
                playerInfoView(index: 3, position: .right)   // Bob
                    .position(x: 362, y: 225)
                playerInfoView(index: 0, position: .bottom)  // You
                    .position(x: 196, y: 400)
                
                // Played cards (only visible during actual play)
                if !viewModel.isPassing {
                    ForEach(Array(viewModel.playedCards.enumerated()), id: \.element.playerIndex) { index, play in
                        let position = getTrickCardPosition(for: play.playerIndex)
                        let isFirstCard = index == 0
                        
                        VStack(spacing: 4) {
                            CardView(card: play.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isFirstCard ? Color.red : Color.clear, lineWidth: 3)
                                )
                        }
                        .offset(x: position.x, y: position.y)
                    }
                }
                
                // Overlay for Passing phase
                if viewModel.isPassing {
                    VStack(spacing: 15) {
                        Spacer() // Pushes button to the bottom
                        
                        Button("Confirm Pass (\(viewModel.selectedCardsToPass.count)/3)") {
                            viewModel.submitPass()
                        }
                        .font(.title2)
                        .padding()
                        .background(viewModel.selectedCardsToPass.count == 3 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(viewModel.selectedCardsToPass.count != 3)
                        .padding(.bottom, 20) // Give space above the hand
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4)) // Semi-transparent overlay
                    .edgesIgnoringSafeArea(.all) // Extend overlay to edges
                }
            }
            .frame(height: 450)
            
            // Passing instruction text - in the light green area
            if viewModel.isPassing {
                let recipientIndex = viewModel.getPassRecipient(from: 0)
                let recipientName = viewModel.players[recipientIndex].name
                
                Text("Round \(viewModel.roundNumber): Select 3 cards to pass to \(recipientName)")
                    .font(.headline)
                    .foregroundColor(viewModel.selectedCardsToPass.count == 3 ? .yellow : .white)
                    .padding(.vertical, 10)
            } else {
                Spacer()
            }
            
            // Your hand
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(playerHand.enumerated()), id: \.element.id) { index, card in
                        let centerIndex = CGFloat(totalCardsInHand - 1) / 2
                        let xOffset = (CGFloat(index) - centerIndex) * currentSpacing
                        
                        let isSelectedForPassing = viewModel.isPassing && viewModel.selectedCardsToPass.contains(card)
                        let isLegalToPlay = legalCards.contains(card)
                        let isPlayable = viewModel.currentPlayerIndex == 0 && isLegalToPlay
                        
                        // Card visual group
                        Group {
                            CardView(card: card)
                                .scaleEffect(isSelectedForPassing ? 1.1 : 1.0)
                                .offset(y: isSelectedForPassing ? -20 : 0)
                                .animation(.spring(), value: isSelectedForPassing)
                                .overlay( // Apply overlay directly to CardView
                                    Group {
                                        if isSelectedForPassing {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.yellow, lineWidth: 4)
                                        } else if isPlayable && !viewModel.isPassing {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white, lineWidth: 2)
                                        }
                                    }
                                )
                        }
                        .rotationEffect(.degrees(Double(index) - Double(centerIndex)) * (viewModel.isPassing ? 3 : 5)) // Apply rotation AFTER overlay
                        .offset(x: xOffset, y: 0) // Apply offset AFTER rotation and overlay
                        .disabled(viewModel.isProcessing || (viewModel.isPassing && !viewModel.players[0].isHuman) || (!viewModel.isPassing && !isPlayable))
                        .opacity(viewModel.isPassing || isPlayable ? 1.0 : 0.4) // Dim unplayable/unselectable cards
                        .onTapGesture { // Use onTapGesture directly on the card for consistent hit area
                            if viewModel.isPassing {
                                viewModel.toggleCardSelection(card)
                            } else if isPlayable {
                                viewModel.playCard(card)
                            }
                        }
                    }
                }
                .scaleEffect(0.95)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
    }
    
    enum PlayerPosition {
        case left, top, right, bottom
    }
    
    func playerInfoView(index: Int, position: PlayerPosition) -> some View {
        let player = viewModel.players[index]
        let isLastWinner = viewModel.lastTrickWinner == index
        
        return VStack(spacing: 2) {
            Text(player.name)
                .foregroundColor(.white)
                .font(.headline)
            Text("Round: +\(player.roundScore)")
                .foregroundColor(.white)
                .font(.caption)
            Text("Total: \(player.score)")
                .foregroundColor(.white)
                .font(.caption)
            Text("\(player.hand.count) cards")
                .foregroundColor(.white)
                .font(.caption2)
        }
        .padding(8)
        .background(
            isLastWinner && !viewModel.isPassing ? Color.red.opacity(0.7) : Color.black.opacity(0.5) // Don't highlight winner during passing
        )
        .cornerRadius(8)
    }
    
    func getTrickCardPosition(for playerIndex: Int) -> CGPoint {
        switch playerIndex {
        case 0: return CGPoint(x: 0, y: 80)      // You - bottom, closer to center
        case 1: return CGPoint(x: -80, y: 0)    // Emma - left, closer to center
        case 2: return CGPoint(x: 0, y: -80)     // Abby - top, closer to center
        case 3: return CGPoint(x: 80, y: 0)     // Bob - right, closer to center
        default: return CGPoint(x: 0, y: 0)
        }
    }
}
