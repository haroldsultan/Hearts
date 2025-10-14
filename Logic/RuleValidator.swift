import Foundation

class RuleValidator {
    
    // Finds the player index with the 2 of Clubs
    static func findPlayerWith2OfClubs(players: [Player]) -> Int? {
        for (index, player) in players.enumerated() {
            if player.hand.contains(where: { $0.isTwoOfClubs }) {
                return index
            }
        }
        return nil
    }
    
    // Determines if it is the first trick of the hand (i.e., no cards have been won yet)
    static func isFirstTrick(players: [Player]) -> Bool {
        return players.allSatisfy { $0.wonCards.isEmpty }
    }
    
    static func canPlayCard(
        _ card: Card,
        hand: [Card],
        playedCards: [(playerIndex: Int, card: Card)],
        heartsBroken: Bool,
        isFirstTrick: Bool
    ) -> Bool {
        
        // --- 1. Leading the Trick ---
        if playedCards.isEmpty {
            
            // First rule: MUST lead 2 of clubs if it's the very first trick of the hand.
            if isFirstTrick {
                return card.isTwoOfClubs
            }
            
            // Regular lead: cannot lead hearts unless hearts are broken OR the player only has hearts.
            if card.suit == .hearts && !heartsBroken {
                let onlyHasHearts = hand.allSatisfy { $0.suit == .hearts }
                return onlyHasHearts
            }
            
            // All other cards are legal to lead.
            return true
        }
        
        // --- 2. Following the Trick ---
               
            let leadSuit = playedCards.first!.card.suit
            let hasSuit = hand.contains { $0.suit == leadSuit }
               
            if hasSuit {
                // Must follow suit if possible
                return card.suit == leadSuit
            } else {
                // Void in suit - can slough any card, BUT check first trick points rule.
                   
                if isFirstTrick {
                    let isPointCard = card.suit == .hearts || (card.suit == .spades && card.rank == .queen)
                    let hasNonPointCards = hand.contains { $0.points == 0 }

                    if isPointCard {
                        // Cannot play a point card unless you have NO non-point cards left.
                        return !hasNonPointCards
                    }
                    
                    // Non-point cards are always legal when void on the first trick.
                    return true
                }
                   
                // Not the first trick: can slough any card.
                return true
            }
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
