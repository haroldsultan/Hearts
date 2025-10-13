// Hearts Card Passing Strategy (Heuristic)
// Focuses on dumping points and creating voids aggressively.

import Foundation

class AIPassingStrategy {
    /// Choose up to 3 cards to pass (heuristic, ranked by danger score)
    static func selectCardsToPass(hand: [Card]) -> [Card] {
        // Quick helpers (assuming Card, Rank, Suit are available)
        func isQSpade(_ c: Card) -> Bool { c.rank == .queen && c.suit == .spades }
        // J, Q, K, A
        func isHigh(_ c: Card) -> Bool { c.rank.value >= Rank.jack.value }
        // 2, 3, 4, 5 (Good "escape" cards)
        func isLow(_ c: Card) -> Bool { c.rank.value <= 5 }

        // Count suits for tactical analysis
        let suitCounts = Dictionary(grouping: hand, by: { $0.suit }).mapValues { $0.count }
        
        // Score each card (higher = more desirable to pass)
        var scores: [(card: Card, score: Int)] = hand.map { ($0, 0) }

        for i in 0..<scores.count {
            var score = 0
            let c = scores[i].card

            // 1) Queen of Spades: Highest priority to pass
            if isQSpade(c) {
                let spadeCount = suitCounts[.spades] ?? 0
                // Base score is high (300). If we hold 4+ spades (control), reduce score significantly
                // to encourage keeping it for protection.
                score += (spadeCount >= 4) ? 75 : 300
            }

            // 2) Dangerous Spades: A and K are highly risky if they're not Q♠
            if c.suit == .spades {
                switch c.rank {
                case .ace: score += 150 // Very dangerous, often forced to win
                case .king: score += 120
                case .queen: break // Handled above
                default: score += 10 // Small bias for mid-spades
                }
            }

            // 3) Hearts: Score proportional to rank (higher hearts are worse)
            if c.suit == .hearts {
                // High hearts (A-14 to 2-2) are a huge liability.
                score += c.rank.value * 8
            }

            // 4) High Clubs/Diamonds: Aggressively dump high cards in short suits to create voids
            if (c.suit == .clubs || c.suit == .diamonds) && isHigh(c) {
                let count = suitCounts[c.suit] ?? 0
                // Score based on rank (high) + large bonus if short suit (<= 2)
                score += 40 + (c.rank.value - 10) * 10 + (count <= 2 ? 60 : 0) // Increased multipliers
            }

            // 5) Creating Voids: boost singletons
            let countInSuit = suitCounts[c.suit] ?? 0
            if countInSuit == 1 {
                // Big bonus for non-spade singletons; slightly more conservative with spades
                score += (c.suit == .spades) ? 30 : 80
            }
            
            // 6) Keep a few low “escape” cards: penalize passing very low cards
            if isLow(c) {
                // Penalize keeping 2/3/4/5 cards that are useful to duck or lead safely
                score -= 40
            }

            // 7) Tie-breaker: higher rank -> slight bonus
            score += c.rank.value

            scores[i].score = score
        }

        // Sort descending by score
        let ordered = scores.sorted { $0.score > $1.score }.map { $0.card }

        // Final Selection Logic: Pick top 3, enforcing a defensive spade limit
        var picks: [Card] = []
        var nonQSpadesPicked = 0
        let maxNonQSpades = 2

        for c in ordered {
            if picks.count == 3 { break }

            let isCurrentQSpade = isQSpade(c)
            let isCurrentSpade = c.suit == .spades

            if isCurrentSpade {
                if isCurrentQSpade {
                    // Always pick Q♠ if it's ranked in the top few
                    picks.append(c)
                } else if nonQSpadesPicked < maxNonQSpades {
                    // Pick non-Q♠ up to the limit of 2 (A/K/J/10 etc.)
                    picks.append(c)
                    nonQSpadesPicked += 1
                }
                // else: skip this non-Q♠ spade, as it would exceed the defensive limit
            } else {
                // Always pick non-spade cards (Hearts, Clubs, Diamonds)
                picks.append(c)
            }
        }
        
        // This ensures we always return 3 cards if possible, filling with the next best if needed.
        // This handles cases where we skipped too many spades but still need 3 cards.
        while picks.count < 3 {
             if let nextCard = ordered.first(where: { !picks.contains($0) }) {
                 picks.append(nextCard)
             } else {
                 break
             }
        }
        
        return Array(picks.prefix(3))
    }
}
