import Foundation
import Combine

enum PassDirection: Int {
    case left = 0
    case across = 1
    case right = 2
    case none = 3
    
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
    @Published var roundNumber = 0
    @Published var gameStarted = false
    @Published var isProcessing = false
    @Published var heartsBroken = false
    @Published var isGameOver = false
    
    // Passing phase
    @Published var isPassing = false
    @Published var passDirection: PassDirection = .left
    @Published var selectedCardsToPass: Set<Card> = []
    private var allPassedCards: [[Card]] = [[], [], [], []]  // Cards each player is passing
    
    init() {
        players = [
            Player(name: "You", isHuman: true, hand: []),
            Player(name: "Bob", isHuman: false, hand: []),
            Player(name: "Abby", isHuman: false, hand: []),
            Player(name: "Emma", isHuman: false, hand: [])
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
        
        players[0].hand = Array(deck[0..<13])
        players[1].hand = Array(deck[13..<26])
        players[2].hand = Array(deck[26..<39])
        players[3].hand = Array(deck[39..<52])
        
        roundNumber += 1
        heartsBroken = false
        selectedCardsToPass = []
        allPassedCards = [[], [], [], []]
        
        // Determine if we need to pass this round
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
    
    // FOR DEBUGGING
    func dealMoonHand() {
        players[0].hand = players[0].hand.map { card in
            if card.rank == .queen && card.suit == .spades {
                return card // keep Queen of Spades
            } else {
                return Card(rank: .ace, suit: card.suit) // same suit, make it Ace
            }
        }
    }
    
    // Human selects/deselects a card to pass
    func toggleCardSelection(_ card: Card) {
        if selectedCardsToPass.contains(card) {
            selectedCardsToPass.remove(card)
        } else if selectedCardsToPass.count < 3 {
            selectedCardsToPass.insert(card)
        }
    }
    
    // Human submits their 3 cards to pass
    func submitPass() {
        guard selectedCardsToPass.count == 3 else { return }
        allPassedCards[0] = Array(selectedCardsToPass)
        executePass()
    }
    
    // Execute the pass between all players
    func executePass() {
        // Remove passed cards from each player's hand
        for i in 0..<players.count {
            for card in allPassedCards[i] {
                players[i].removeCard(card)
            }
        }
        
        // Give cards to recipients based on pass direction
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
        case .left:
            return (playerIndex + 1) % 4
        case .across:
            return (playerIndex + 2) % 4
        case .right:
            return (playerIndex + 3) % 4
        case .none:
            return playerIndex
        }
    }
    
    func startPlaying() {
        if let startPlayer = RuleValidator.findPlayerWith2OfClubs(players: players) {
            currentPlayerIndex = startPlayer
        } else {
            currentPlayerIndex = 0
        }
        
        gameStarted = true
        
        if !players[currentPlayerIndex].isHuman {
            playAITurn()
        }
    }
    
    func playCard(_ card: Card) {
        guard gameStarted else { return }
        guard !isProcessing else { return }
        
        let isFirstTrick = RuleValidator.isFirstTrick(players: players)
        
        guard RuleValidator.canPlayCard(
            card,
            hand: players[currentPlayerIndex].hand,
            playedCards: playedCards,
            heartsBroken: heartsBroken,
            isFirstTrick: isFirstTrick
        ) else {
            return
        }
        
        isProcessing = true
        
        if let index = players[currentPlayerIndex].hand.firstIndex(of: card) {
            players[currentPlayerIndex].hand.remove(at: index)
            playedCards.append((currentPlayerIndex, card))
            
            if card.suit == .hearts {
                heartsBroken = true
            }
            
            if playedCards.count == 4 {
                completeTrick()
            } else {
                currentPlayerIndex = (currentPlayerIndex + 1) % 4
                isProcessing = false
                playAITurn()
            }
        } else {
            isProcessing = false
        }
    }
    
    func completeTrick() {
        let leadSuit = playedCards[0].card.suit
        let winner = playedCards
            .filter { $0.card.suit == leadSuit }
            .max { $0.card.rank.value < $1.card.rank.value }!
        
        let wonCards = playedCards.map { $0.card }
        players[winner.playerIndex].wonCards.append(contentsOf: wonCards)
        
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
    
    func endRound() {
        var moonShooterIndex: Int? = nil
        for i in 0..<players.count {
            let points = players[i].wonCards.reduce(0) { $0 + $1.points }
            if points == 26 {
                moonShooterIndex = i
                break
            }
        }
        
        if let shooterIndex = moonShooterIndex {
            for i in 0..<players.count {
                if i == shooterIndex {
                    players[i].endRound(shootingMoon: true)
                } else {
                    players[i].endRound(shootingMoon: false)
                    players[i].score += 26
                }
            }
        } else {
            for i in 0..<players.count {
                players[i].endRound(shootingMoon: false)
            }
        }
        
        playedCards = []
        passDirection = passDirection.next()  // Advance to next pass direction
        
        if players.contains(where: { $0.score >= 100 }) {
            isGameOver = true
            gameStarted = false
        } else {
            gameStarted = false
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
        passDirection = .left  // Reset pass direction
        setupGame()
    }
    
    func playAITurn() {
        if !players[currentPlayerIndex].isHuman && !players[currentPlayerIndex].hand.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let isFirstTrick = RuleValidator.isFirstTrick(players: self.players)
                
                let legalCards = RuleValidator.getLegalCards(
                    hand: self.players[self.currentPlayerIndex].hand,
                    playedCards: self.playedCards,
                    heartsBroken: self.heartsBroken,
                    isFirstTrick: isFirstTrick
                )
                
                if let randomCard = legalCards.randomElement() {
                    self.playCard(randomCard)
                }
            }
        }
    }
}
