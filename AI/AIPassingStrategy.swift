import Foundation

class AIPassingStrategy {
    
    // Simple strategy: Pass dangerous high cards
    // TODO: Make this smarter later with actual Hearts strategy
    static func selectCardsToPass(hand: [Card]) -> [Card] {
        var cardsToPass: [Card] = []
        
        // Strategy 1: Pass high spades (A, K) if we don't have Q
        let spades = hand.filter { $0.suit == .spades }
        let hasQueenOfSpades = spades.contains { $0.rank == .queen }
        
        if !hasQueenOfSpades {
            // Pass A and K of spades if we have them (dangerous without Q)
            let highSpades = spades.filter { $0.rank == .ace || $0.rank == .king }
            for card in highSpades.prefix(2) {
                cardsToPass.append(card)
            }
        }
        
        // Strategy 2: Pass high hearts
        if cardsToPass.count < 3 {
            let hearts = hand.filter { $0.suit == .hearts && !cardsToPass.contains($0) }
            let highHearts = hearts.sorted { $0.rank.value > $1.rank.value }
            for card in highHearts.prefix(3 - cardsToPass.count) {
                cardsToPass.append(card)
            }
        }
        
        // Strategy 3: If still need more, pass highest remaining cards
        if cardsToPass.count < 3 {
            let remaining = hand.filter { !cardsToPass.contains($0) }
            let highest = remaining.sorted { $0.rank.value > $1.rank.value }
            for card in highest.prefix(3 - cardsToPass.count) {
                cardsToPass.append(card)
            }
        }
        
        return Array(cardsToPass.prefix(3))
    }
}
