import Foundation

struct Player {
    let name: String
    let isHuman: Bool
    var hand: [Card]
    var wonCards: [Card] = []
    var score: Int = 0
    var roundScore: Int = 0
    
    mutating func removeCard(_ card: Card) {
        hand.removeAll { $0 == card }
    }
    
    mutating func addCards(_ cards: [Card]) {
        wonCards.append(contentsOf: cards)
    }
    
    mutating func calculateRoundScore() {
        roundScore = wonCards.reduce(0) { $0 + $1.points }
    }
    
    mutating func endRound() {
        calculateRoundScore()
        score += roundScore
        wonCards = []
    }
}
