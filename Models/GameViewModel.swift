
import Foundation
import Combine

class GameViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayerIndex = 0
    @Published var playedCards: [(playerIndex: Int, card: Card)] = []
    @Published var roundNumber = 0
    @Published var gameStarted = false
    
    func setupGame() {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        deck.shuffle()
        
        players = [
            Player(name: "You", isHuman: true, hand: Array(deck[0..<13])),
            Player(name: "Bob", isHuman: false, hand: Array(deck[13..<26])),
            Player(name: "Abby", isHuman: false, hand: Array(deck[26..<39])),
            Player(name: "Emma", isHuman: false, hand: Array(deck[39..<52]))
        ]
        
        roundNumber = 1
        currentPlayerIndex = 0
        gameStarted = true
    }
    
    func playCard(_ card: Card) {
        guard gameStarted else { return }
        
        if let index = players[currentPlayerIndex].hand.firstIndex(of: card) {
            players[currentPlayerIndex].hand.remove(at: index)
            playedCards.append((currentPlayerIndex, card))
            
            if playedCards.count == 4 {
                completeTrick()
            } else {
                currentPlayerIndex = (currentPlayerIndex + 1) % 4
                playAITurn()
            }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.endRound()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.playedCards = []
                self.currentPlayerIndex = winner.playerIndex
                self.playAITurn()
            }
        }
    }

    func endRound() {
        for i in 0..<players.count {
            players[i].endRound()
        }
        playedCards = []
        gameStarted = false
    }
    
    func playAITurn() {
        if !players[currentPlayerIndex].isHuman && !players[currentPlayerIndex].hand.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let randomCard = self.players[self.currentPlayerIndex].hand.randomElement() {
                    self.playCard(randomCard)
                }
            }
        }
    }
}
