import Foundation
import Combine

enum PassDirection: Int {
    case left = 0, across = 1, right = 2, none = 3
    
    var description: String {
        switch self {
        case .left: return "Left"
        case .across: return "Across"
        case .right: return "Right"
        case .none: return "No Pass"
        }
    }
    
    func next() -> PassDirection {
        return PassDirection(rawValue: (self.rawValue + 1) % 4) ?? .left
    }
}

class GameViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayerIndex = 0
    @Published var playedCards: [(playerIndex: Int, card: Card)] = []
    @Published var playedCardsThisRound: [Card] = []
    @Published var roundNumber = 0
    @Published var gameStarted = false
    @Published var isProcessing = false
    @Published var heartsBroken = false
    @Published var isGameOver = false
    @Published var lastTrickWinner: Int? = nil
    @Published var difficulty: DifficultyLevel = .medium {
        didSet {
            // Save difficulty whenever it changes
            GameSettings.shared.difficulty = difficulty
        }
    }
    
    // Passing phase
    @Published var isPassing = false
    @Published var passDirection: PassDirection = .left
    @Published var selectedCardsToPass: Set<Card> = []
    private var allPassedCards: [[Card]] = [[], [], [], []]  // Cards each player is passing
    
    // NEW: Track Queen of Spades for stats
    private var tookQueenThisRound: [Bool] = [false, false, false, false]
    
    init() {
        // Load saved difficulty
        difficulty = GameSettings.shared.difficulty
        
        players = [
            Player(name: GameSettings.shared.playerName, isHuman: true, hand: []),
            Player(name: "Emma", isHuman: false, hand: []),
            Player(name: "Abby", isHuman: false, hand: []),
            Player(name: "Bob", isHuman: false, hand: [])
        ]
        setupGame()
    }
    
    func setupGame() {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        deck.shuffle()
        
        for i in 0..<4 {
            players[i].hand = Array(deck[(i*13)..<((i+1)*13)])
        }
        
        roundNumber += 1
        heartsBroken = false
        selectedCardsToPass = []
        allPassedCards = [[], [], [], []]
        playedCardsThisRound = []
        tookQueenThisRound = [false, false, false, false]  // NEW: Reset queen tracker
        
        if passDirection == .none {
            startPlaying()
        } else {
            isPassing = true
            gameStarted = false
            
            // AI players immediately select cards to pass
            for i in 1..<players.count {
                let cardsToPass = AIPassingStrategy.selectCardsToPass(hand: players[i].hand)
                allPassedCards[i] = cardsToPass
            }
        }
    }
    
    // MARK: - Passing
    func toggleCardSelection(_ card: Card) {
        if selectedCardsToPass.contains(card) {
            selectedCardsToPass.remove(card)
        } else if selectedCardsToPass.count < 3 {
            selectedCardsToPass.insert(card)
        }
    }
    
    func submitPass() {
        guard selectedCardsToPass.count == 3 else { return }
        allPassedCards[0] = Array(selectedCardsToPass)
        executePass()
    }
    
    private func executePass() {
        for i in 0..<players.count {
            for card in allPassedCards[i] {
                players[i].removeCard(card)
            }
        }
        
        for i in 0..<players.count {
            let recipientIndex = getPassRecipient(from: i)
            players[recipientIndex].hand.append(contentsOf: allPassedCards[i])
        }
        
        selectedCardsToPass = []
        isPassing = false
        startPlaying()
    }
    
    func getPassRecipient(from playerIndex: Int) -> Int {
        switch passDirection {
        case .left: return (playerIndex + 1) % 4
        case .across: return (playerIndex + 2) % 4
        case .right: return (playerIndex + 3) % 4
        case .none: return playerIndex
        }
    }
    
    // MARK: - Gameplay
    func startPlaying() {
        if let startPlayer = RuleValidator.findPlayerWith2OfClubs(players: players) {
            currentPlayerIndex = startPlayer
        } else {
            currentPlayerIndex = 0
        }
        gameStarted = true
        if !players[currentPlayerIndex].isHuman {
            // Slight delay before AI plays to show whose turn it is
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playAITurn()
            }
        }
    }
    
    func playCard(_ card: Card) {
        guard gameStarted, !isProcessing else { return }
        let isFirstTrick = RuleValidator.isFirstTrick(players: players)
        
        guard RuleValidator.canPlayCard(card, hand: players[currentPlayerIndex].hand,
                                        playedCards: playedCards,
                                        heartsBroken: heartsBroken,
                                        isFirstTrick: isFirstTrick) else { return }
        
        isProcessing = true
        if let index = players[currentPlayerIndex].hand.firstIndex(of: card) {
            players[currentPlayerIndex].hand.remove(at: index)
            playedCards.append((currentPlayerIndex, card))
            playedCardsThisRound.append(card)
            if card.suit == .hearts { heartsBroken = true }
            
            if playedCards.count == 4 {
                completeTrick()
            } else {
                currentPlayerIndex = (currentPlayerIndex + 1) % 4
                
                // Delay before next player's turn (especially for AI)
                let delay = players[currentPlayerIndex].isHuman ? 0.0 : 0.1
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.isProcessing = false
                    self.playAITurn()
                }
            }
        } else {
            isProcessing = false
        }
    }
    
    private func completeTrick() {
        let leadSuit = playedCards[0].card.suit
        let winner = playedCards.filter { $0.card.suit == leadSuit }
            .max { $0.card.rank.value < $1.card.rank.value }!
        
        let wonCards = playedCards.map { $0.card }
        players[winner.playerIndex].wonCards.append(contentsOf: wonCards)
        lastTrickWinner = winner.playerIndex
        
        // NEW: Check if winner took Queen of Spades
        for card in wonCards {
            if card.rank == .queen && card.suit == .spades {
                tookQueenThisRound[winner.playerIndex] = true
            }
        }

        if players[0].hand.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.endRound()
                self.isProcessing = false
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.playedCards = []
                self.currentPlayerIndex = winner.playerIndex
                self.isProcessing = false
                self.playAITurn()
            }
        }
    }
    
    private func endRound() {
        var moonShooterIndex: Int? = nil
        for i in 0..<players.count {
            let points = players[i].wonCards.reduce(0) { $0 + $1.points }
            if points == 26 { moonShooterIndex = i; break }
        }
        
        for i in 0..<players.count {
            if let shooter = moonShooterIndex {
                if i == shooter {
                    players[i].endRound(shootingMoon: true)
                } else {
                    players[i].endRound(shootingMoon: false)
                    players[i].score += 26
                }
            } else {
                players[i].endRound(shootingMoon: false)
            }
        }
        
        // NEW: Record stats for this round
        recordRoundStats()
        
        playedCards = []
        passDirection = passDirection.next()
        gameStarted = false
        
        if players.contains(where: { $0.score >= 100 }) {
            isGameOver = true
            // NEW: Record game stats when game ends
            recordGameStats()
        }
    }
    
    func startNewGame() {
        for i in 0..<players.count {
            players[i].score = 0
            players[i].lastRoundScore = 0
            players[i].wonCards = []
            players[i].hand = []
        }
        roundNumber = 0
        isGameOver = false
        passDirection = .left
        setupGame()
    }
    
    func playAITurn() {
        guard !players[currentPlayerIndex].isHuman, !players[currentPlayerIndex].hand.isEmpty else { return }
        
        let iterations = difficulty.iterations
        
        let bestCard = AIPlayingStrategy.selectCard(
            playerIndex: self.currentPlayerIndex,
            players: self.players,
            currentTrick: self.playedCards,
            heartsBroken: self.heartsBroken,
            playedCardsThisRound: self.playedCardsThisRound,
            iterations: iterations,
            numSamples: 25
        )
        
        if let cardToPlay = bestCard {
            self.playCard(cardToPlay)
        } else {
            print("AI failed to select a card.")
        }
    }
    
    // MARK: - Player Name Management
    func updatePlayerName() {
        players[0].name = GameSettings.shared.playerName
    }
    
    // MARK: - Stats Tracking
    
    /// Records stats for all players at the end of a round
    private func recordRoundStats() {
        // Find who won the round (lowest points this round)
        let minRoundScore = players.map { $0.lastRoundScore }.min() ?? 0
        
        for (index, player) in players.enumerated() {
            let wonRound = player.lastRoundScore == minRoundScore
            let shotMoon = player.shotTheMoon
            let tookQueen = tookQueenThisRound[index]
            
            StatsManager.shared.recordRoundForPlayer(
                playerName: player.name,
                points: player.lastRoundScore,
                wonRound: wonRound,
                shotMoon: shotMoon,
                tookQueen: tookQueen
            )
        }
    }
    
    /// Records game stats for all players when game ends
    private func recordGameStats() {
        // Find the winner (lowest total score)
        let minScore = players.map { $0.score }.min() ?? 0
        
        for player in players {
            let wonGame = player.score == minScore
            
            StatsManager.shared.recordGameEndForPlayer(
                playerName: player.name,
                finalScore: player.score,
                wonGame: wonGame
            )
        }
    }
}
