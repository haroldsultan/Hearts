import Foundation

struct Player {
    let name: String
    let isHuman: Bool
    var hand: [Card]
    var wonCards: [Card] = []
    var score: Int = 0
    var lastRoundScore: Int = 0  // NEW - stores last round's score
    
    var roundScore: Int {
        wonCards.reduce(0) { $0 + $1.points }
    }
    
    mutating func removeCard(_ card: Card) {
        hand.removeAll { $0 == card }
    }
    
    mutating func addCards(_ cards: [Card]) {
        wonCards.append(contentsOf: cards)
    }
    
    mutating func endRound() {
        lastRoundScore = roundScore  // Save it
        score += lastRoundScore
        wonCards = []
    }
}
