import Foundation

class RuleValidator {
    
    static func findPlayerWith2OfClubs(players: [Player]) -> Int? {
        for (index, player) in players.enumerated() {
            if player.hand.contains(where: { $0.isTwoOfClubs }) {
                return index
            }
        }
        return nil
    }
    
    static func isFirstTrick(players: [Player]) -> Bool {
        return players.allSatisfy { $0.hand.count == 13 }
    }
    
    static func canPlayCard(
        _ card: Card,
        hand: [Card],
        playedCards: [(playerIndex: Int, card: Card)],
        heartsBroken: Bool,
        isFirstTrick: Bool
    ) -> Bool {
        
        // First trick: must play 2 of clubs if you have it and are leading
        if isFirstTrick && playedCards.isEmpty {
            return card.isTwoOfClubs
        }
        
        // If someone already played in this trick (following)
        if let firstCard = playedCards.first {
            let leadSuit = firstCard.card.suit
            let hasSuit = hand.contains { $0.suit == leadSuit }
            
            if hasSuit {
                // Must follow suit
                return card.suit == leadSuit
            } else {
                // No suit - can slough, BUT check first trick points rule
                if isFirstTrick && (card.suit == .hearts || (card.suit == .spades && card.rank == .queen)) {
                    // Can't slough points on first trick unless forced
                    let hasOnlyPoints = hand.allSatisfy { $0.points > 0 }
                    return hasOnlyPoints
                }
                return true
            }
        }
        
        // Leading a card (first in trick)
        if card.suit == .hearts && !heartsBroken {
            // Can't lead hearts unless broken OR only have hearts
            let onlyHasHearts = hand.allSatisfy { $0.suit == .hearts }
            return onlyHasHearts
        }
        
        return true
    }
    
    static func getLegalCards(
        hand: [Card],
        playedCards: [(playerIndex: Int, card: Card)],
        heartsBroken: Bool,
        isFirstTrick: Bool
    ) -> [Card] {
        return hand.filter { card in
            canPlayCard(card, hand: hand, playedCards: playedCards, heartsBroken: heartsBroken, isFirstTrick: isFirstTrick)
        }
    }
}
