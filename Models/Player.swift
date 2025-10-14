import Foundation

struct Player {
    var name: String  // Changed from 'let' to 'var' to allow name updates
    let isHuman: Bool
    var hand: [Card]
    var wonCards: [Card] = []
    var score: Int = 0
    var lastRoundScore: Int = 0
    var shotTheMoon: Bool = false
    
    var roundScore: Int {
        wonCards.reduce(0) { $0 + $1.points }
    }
    
    mutating func removeCard(_ card: Card) {
        hand.removeAll { $0 == card }
    }
    
    mutating func addCards(_ cards: [Card]) {
        wonCards.append(contentsOf: cards)
    }
    
    mutating func endRound(shootingMoon: Bool) {
        lastRoundScore = roundScore
        shotTheMoon = shootingMoon
        
        if shootingMoon {
            score += 0  // Moon shooter gets 0
        } else {
            score += lastRoundScore
        }
        
        wonCards = []
    }
    
    var sortedHand: [Card] {
        hand.sorted { card1, card2 in
            if card1.suit != card2.suit {
                let suitOrder: [Suit] = [.hearts, .spades, .diamonds, .clubs]
                let index1 = suitOrder.firstIndex(of: card1.suit) ?? 0
                let index2 = suitOrder.firstIndex(of: card2.suit) ?? 0
                return index1 < index2
            }
            return card1.rank.value < card2.rank.value
        }
    }
}
