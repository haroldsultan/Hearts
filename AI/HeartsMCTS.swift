// HeartsMCTS_Improved.swift
// Strongest MCTS-based AI for Hearts (MCTS-P)

import Foundation

// MARK: - HeartsGameState
// This is the model the MCTS uses internally for simulation.
struct HeartsGameState: Equatable, Hashable {
    
    // Assumed Helper: RuleValidator.getLegalCards
    class RuleValidator {
        /**
         Calculates the set of cards legal to play based on the current trick state.
         
         The logic here MUST be accurate to ensure MCTS simulations are valid.
         */
        static func getLegalCards(hand: [Card], playedCards: [(playerIndex: Int, card: Card)], heartsBroken: Bool, isFirstTrick: Bool) -> [Card] {
            guard !hand.isEmpty else { return [] }

            // --- 1. Leading the Trick ---
            if playedCards.isEmpty {
                
                // First trick lead rule: Must lead 2 of clubs if it's the very first trick.
                if isFirstTrick && hand.contains(where: { $0.isTwoOfClubs }) {
                    return hand.filter { $0.isTwoOfClubs }
                }
                
                // Regular lead: cannot lead hearts if not broken, unless hand is all hearts.
                let canLeadHearts = heartsBroken || hand.allSatisfy { $0.suit == .hearts }
                return canLeadHearts ? hand : hand.filter { $0.suit != .hearts }
            }

            // --- 2. Following the Trick ---
            
            let leadSuit = playedCards[0].card.suit
            let followSuit = hand.filter { $0.suit == leadSuit }

            if !followSuit.isEmpty {
                // Must follow suit
                return followSuit
            } else {
                // Void in suit (Sloughing)
                
                // BUG FIX: Corrected first trick sloughing rule.
                if isFirstTrick {
                    // Check if the card is a point card (Heart or Q♠)
                    let pointCards = hand.filter { $0.points > 0 }
                    
                    // If the entire hand is point cards, the player is forced to play one.
                    if hand.count == pointCards.count {
                        return hand
                    }
                    
                    // Otherwise, the player CANNOT play a point card on the first trick.
                    let nonPointCards = hand.filter { $0.points == 0 }
                    return nonPointCards
                }
                
                return hand // Otherwise, any card is legal to slough
            }
        }
    }


    var playersHands: [[Card]]
    var playedCardsThisRound: [Card]
    var currentTrick: [(playerIndex: Int, card: Card)]
    var heartsBroken: Bool
    var currentPlayer: Int
    var wonCards: [[Card]]

    // MARK: - Equatable Implementation
    static func == (lhs: HeartsGameState, rhs: HeartsGameState) -> Bool {
        let tricksEqual = lhs.currentTrick.elementsEqual(rhs.currentTrick) { t1, t2 in
            return t1.playerIndex == t2.playerIndex && t1.card == t2.card
        }

        return lhs.playersHands == rhs.playersHands &&
            lhs.playedCardsThisRound == rhs.playedCardsThisRound &&
            tricksEqual &&
            lhs.heartsBroken == rhs.heartsBroken &&
            lhs.currentPlayer == rhs.currentPlayer &&
            lhs.wonCards == rhs.wonCards
    }

    func legalMoves() -> [Card] {
        guard !playersHands[currentPlayer].isEmpty else { return [] }
        return RuleValidator.getLegalCards(
            hand: playersHands[currentPlayer],
            playedCards: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: playedCardsThisRound.isEmpty && currentTrick.isEmpty
        )
    }

    func playCard(_ card: Card) -> HeartsGameState {
        var nextHands = playersHands
        nextHands[currentPlayer].removeAll { $0 == card }

        var nextTrick = currentTrick
        nextTrick.append((currentPlayer, card))

        var nextHeartsBroken = heartsBroken || card.suit == .hearts
        var nextPlayer = (currentPlayer + 1) % 4
        var nextWonCards = wonCards

        var nextPlayedCards = playedCardsThisRound

        if nextTrick.count == 4 {
            let leadSuit = nextTrick[0].card.suit
            
            // Determine winner of the trick
            let winner = nextTrick
                .filter { $0.card.suit == leadSuit }
                .max { $0.card.rank.value < $1.card.rank.value }!

            nextWonCards[winner.playerIndex].append(contentsOf: nextTrick.map { $0.card })
            nextPlayedCards.append(contentsOf: nextTrick.map { $0.card })

            nextTrick = []
            nextPlayer = winner.playerIndex
            
            // Re-check hearts broken status after the trick if it was previously false
            if !nextHeartsBroken {
                nextHeartsBroken = nextWonCards[winner.playerIndex].contains(where: { $0.suit == .hearts })
            }
        }

        return HeartsGameState(
            playersHands: nextHands,
            playedCardsThisRound: nextPlayedCards,
            currentTrick: nextTrick,
            heartsBroken: nextHeartsBroken,
            currentPlayer: nextPlayer,
            wonCards: nextWonCards
        )
    }

    func isTerminal() -> Bool {
        return playersHands.allSatisfy { $0.isEmpty }
    }

    func score(for playerIndex: Int) -> Int {
        return wonCards[playerIndex].reduce(0) { $0 + $1.points }
    }

    func hash(into hasher: inout Hasher) {
        // Simplified hashing to improve speed while maintaining essential uniqueness
        for hand in playersHands { for card in hand { hasher.combine(card) } }
        for card in playedCardsThisRound { hasher.combine(card) }
        for (index, card) in currentTrick { hasher.combine(index); hasher.combine(card) }
        hasher.combine(heartsBroken)
        hasher.combine(currentPlayer)
    }
}

// MARK: - MCTS Node
class MCTSNode {
    let state: HeartsGameState
    weak var parent: MCTSNode?
    var children: [MCTSNode] = []
    var visits: Int = 0
    var totalScore: Double = 0.0
    var untriedMoves: [Card]

    init(state: HeartsGameState, parent: MCTSNode? = nil) {
        self.state = state
        self.parent = parent
        self.untriedMoves = state.legalMoves()
    }

    func uctValue(totalParentVisits: Int, exploration: Double = 1.41) -> Double {
        guard visits > 0 else { return Double.infinity }
        // UCT formula: (exploitation) + (exploration)
        return (totalScore / Double(visits)) + exploration * sqrt(log(Double(totalParentVisits)) / Double(visits))
    }

    func bestChild() -> MCTSNode? {
        // Selects the child with the highest UCT value
        return children.max { $0.uctValue(totalParentVisits: visits) < $1.uctValue(totalParentVisits: visits) }
    }
}

// MARK: - Hearts MCTS AI
class AIPlayingStrategy {

    // --- IMPERFECT INFORMATION FIX: Monte Carlo Sampling ---

    /**
    Samples the unknown cards and distributes them to the opponents.
    This creates a full-information state for the MCTS run.
    */
    private static func sampleInitialState(
        playerIndex: Int,
        playerHand: [Card],
        players: [Player],
        playedCardsThisRound: [Card],
        currentTrick: [(playerIndex: Int, card: Card)]
    ) -> HeartsGameState {
        
        let allCards = Card.allRanksAndSuits()
        let numPlayers = 4
        
        // 1. Identify all known cards
        var knownCards = Set(playerHand)
        knownCards.formUnion(playedCardsThisRound)
        knownCards.formUnion(currentTrick.map { $0.card })
        
        // 2. Identify all unknown cards
        var unknownCards = allCards.filter { !knownCards.contains($0) }
        unknownCards.shuffle()
        
        // 3. Determine how many cards each opponent must have
        let currentHandCount = playerHand.count
        var hands: [[Card]] = Array(repeating: [], count: numPlayers)
        hands[playerIndex] = playerHand // AI's hand is 100% known

        // 4. Distribute unknown cards to opponents based on remaining cards
        var unknownCardsIndex = 0
        for i in 0..<numPlayers {
            if i != playerIndex {
                // Determine the number of cards this opponent should have left
                let playedInTrick = currentTrick.contains(where: { $0.playerIndex == i }) ? 1 : 0
                let cardsNeeded = currentHandCount - playedInTrick
                
                if cardsNeeded > 0 {
                    let endIndex = min(unknownCardsIndex + cardsNeeded, unknownCards.count)
                    hands[i] = Array(unknownCards[unknownCardsIndex..<endIndex])
                    unknownCardsIndex = endIndex
                }
            }
        }
        
        // Won cards are irrelevant for sampling, MCTS calculates points from this state forward.
        var won: [[Card]] = players.map { _ in [] }

        // The AI needs the correct heart-broken status from the real game state
        let heartsBrokenStatus = playedCardsThisRound.contains(where: { $0.suit == .hearts })
        
        return HeartsGameState(
            playersHands: hands,
            playedCardsThisRound: playedCardsThisRound,
            currentTrick: currentTrick,
            heartsBroken: heartsBrokenStatus,
            currentPlayer: playerIndex,
            wonCards: won
        )
    }
    
    // --- MAIN AI STRATEGY ---

    static func selectCard(playerIndex: Int,
                            players: [Player],
                            currentTrick: [(playerIndex: Int, card: Card)],
                            heartsBroken: Bool,
                            playedCardsThisRound: [Card],
                            iterations: Int = 1000000,
                            numSamples: Int = 30) -> Card? {
        
        let playerHand = players[playerIndex].hand
        
        // 1. Pre-check: Find the legal moves for the current (real) state
        let legalMoves = HeartsGameState.RuleValidator.getLegalCards(
            hand: playerHand,
            playedCards: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: playedCardsThisRound.isEmpty && currentTrick.isEmpty
        )
        
        if legalMoves.count <= 1 { return legalMoves.first }

        var moveScores: [Card: Double] = [:]
        
        // 2. Monte Carlo Tree Search with Playouts (MCTS-P)
        let iterationsPerSample = iterations / numSamples
        
        for _ in 0..<numSamples {
            // A. Sample the unknown cards and create a full state
            let sampledState = sampleInitialState(
                playerIndex: playerIndex,
                playerHand: playerHand,
                players: players,
                playedCardsThisRound: playedCardsThisRound,
                currentTrick: currentTrick
            )
            
            // B. MCTS Search on the sampled state
            let root = MCTSNode(state: sampledState)

            for _ in 0..<iterationsPerSample {
                // Selection & Expansion
                var node = root
                
                while node.untriedMoves.isEmpty && !node.children.isEmpty {
                    node = node.bestChild()!
                }
                
                var state = node.state
                
                if let move = node.untriedMoves.randomElement() {
                    // Expansion: Play the move and create a child node
                    state = state.playCard(move)
                    let child = MCTSNode(state: state, parent: node)
                    node.children.append(child)
                    node.untriedMoves.removeAll { $0 == move }
                    node = child
                }

                // Simulation & Backpropagation
                let score = rollout(state: node.state, aiPlayer: playerIndex)
                var backNode: MCTSNode? = node
                while let current = backNode {
                    current.visits += 1
                    current.totalScore += score
                    backNode = current.parent
                }
            }
            
            // C. Aggregate results from the root's direct children (the initial moves)
            for child in root.children {
                // The move played to get to this child is the last card in the trick
                if let move = child.state.currentTrick.last?.card {
                    let avgScore = child.totalScore / Double(child.visits)
                    // Sum the average score for each move across all samples
                    moveScores[move, default: 0.0] += avgScore
                }
            }
        }
        
        // 4. Select the move with the highest average score (lowest penalty = highest score)
        guard !moveScores.isEmpty else { return legalMoves.first }

        let bestMove = moveScores.max { $0.value < $1.value }!
        return bestMove.key
    }

    // --- WEIGHTED ROLLOUT & REWARD FUNCTION ---

    private static func rollout(state: HeartsGameState, aiPlayer: Int) -> Double {
        var state = state

        // Playout: use the heuristic until terminal state is reached
        while !state.isTerminal() {
            let legal = state.legalMoves()
            if legal.isEmpty { break }
            
            // Apply the heuristic to *all* players during rollout for realistic play
            let move = rolloutHeuristicMove(state: state, legalMoves: legal)
            state = state.playCard(move)
        }

        let aiFinalScore = state.score(for: aiPlayer)
        
        let wonCards = state.wonCards[aiPlayer]
        let qsCount = wonCards.filter { $0.rank == .queen && $0.suit == .spades }.count
        let heartCount = wonCards.filter { $0.suit == .hearts }.count
        
        // 1. Shoot the Moon: Massive positive reward
        if aiFinalScore == 26 {
            return 100000.0
        }
        
        // 2. Competitive Reward and Weighted Penalty
        // Opponents' combined score (what the AI wants to maximize)
        let opponentScores = (0..<4).filter { $0 != aiPlayer }.map { Double(state.score(for: $0)) }.reduce(0.0, +)
        
        // Weighted penalty for the AI's own points (what the AI wants to minimize)
        // Q♠ is 75x more penalized than a standard heart point.
        let weightedAIPenalty = (Double(qsCount) * 75.0) + (Double(heartCount) * 1.0)

        // The AI seeks to MAXIMIZE this total reward: Maximize opponent scores - Minimize AI penalty
        let totalReward = opponentScores - weightedAIPenalty
        
        return totalReward
    }

    // --- IMPROVED ROLLOUT HEURISTIC (FIXED CARD COMPARISON) ---

    /**
    A better heuristic for use during the Playout/Simulation phase.
    */
    private static func rolloutHeuristicMove(state: HeartsGameState, legalMoves: [Card]) -> Card {
        guard !legalMoves.isEmpty else { fatalError("Rollout heuristic called with no legal moves.") }

        let isLeading = state.currentTrick.isEmpty
        let leadCard = isLeading ? nil : state.currentTrick[0].card

        // 1. Strategy for FOLLOWING a Trick (Non-Leading)
        if !isLeading, let leadCard = leadCard {
            let leadSuit = leadCard.suit
            
            // A. Following Suit
            let followingSuit = legalMoves.filter { $0.suit == leadSuit }
            if !followingSuit.isEmpty {
                
                // Find the value of the current highest card in the trick of the lead suit
                let currentWinningCardValue = state.currentTrick
                    .filter { $0.card.suit == leadSuit }
                    .max { $0.card.rank.value < $1.card.rank.value }!
                    .card.rank.value

                // Try to DUCK: play the highest card that WON'T win the trick.
                let nonWinningCards = followingSuit.filter { $0.rank.value < currentWinningCardValue }
                
                // FIX: Removed .card from $1 here and below, as $0 and $1 are Card objects.
                if let bestDuck = nonWinningCards.max(by: { $0.rank.value < $1.rank.value }) {
                    return bestDuck
                }
                
                // If forced to win or lose (all cards win or all cards lose):
                // Play the lowest card possible (to conserve high cards for later).
                // FIX: Removed .card from $1.
                if let lowestCard = followingSuit.min(by: { $0.rank.value < $1.rank.value }) {
                    return lowestCard
                }
            }

            // B. Void in Suit (Sloughing)
            // Prioritize dumping the highest point card, then highest non-point card.
            
            // Dump Queen of Spades (if legal)
            if let qs = legalMoves.first(where: { $0.rank == .queen && $0.suit == .spades }) {
                return qs
            }

            // Dump a Heart (highest value first)
            let hearts = legalMoves.filter { $0.suit == .hearts }
            // FIX: Removed .card from $1.
            if let highHeart = hearts.max(by: { $0.rank.value < $1.rank.value }) {
                return highHeart
            }

            // Dump a high non-point card (highest value first)
            // FIX: Removed .card from $1.
            if let highCard = legalMoves.max(by: { $0.rank.value < $1.rank.value }) {
                return highCard
            }
        }
        
        // 2. Strategy for LEADING a Trick
        if isLeading {
            // A. Lead the lowest card possible in a non-point suit to lose the lead safely
            let safeLeads = legalMoves.filter { $0.points == 0 }
            
            if !safeLeads.isEmpty {
                // Lead the absolute lowest non-point card to maximize safety
                return safeLeads.min { $0.rank.value < $1.rank.value }!
            } else {
                // B. Must lead points (only hearts/Q♠ left in legal moves)
                // Lead the lowest card possible (likely lowest heart) to minimize damage.
                return legalMoves.min { $0.rank.value < $1.rank.value }!
            }
        }

        // Fallback: Default to lowest legal card
        // FIX: Removed .card from $1.
        return legalMoves.min { $0.rank.value < $1.rank.value }!
    }
}
