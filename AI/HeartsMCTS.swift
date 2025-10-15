// HeartsMCTS_Improved.swift
// Strongest MCTS-based AI for Hearts (MCTS-P) with Safety Checks

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
                // Corrected first trick sloughing rule (only non-point cards are legal)
                if isFirstTrick {
                    let pointCards = hand.filter { $0.points > 0 }
                    // If hand is all point cards, player is forced to play one.
                    if hand.count == pointCards.count {
                        return hand
                    }
                    // Otherwise, player CANNOT slough a point card on the first trick.
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

    // In playCard function
    func playCard(_ card: Card) -> HeartsGameState {
        var nextHands = playersHands
        nextHands[currentPlayer].removeAll { $0 == card }

        var nextTrick = currentTrick
        nextTrick.append((currentPlayer, card))

        var nextPlayer = (currentPlayer + 1) % 4
        var nextWonCards = wonCards
        var nextPlayedCards = playedCardsThisRound

        // --- Start with the current heartsBroken status ---
        var nextHeartsBroken = heartsBroken

        if nextTrick.count == 4 {
            let leadSuit = nextTrick[0].card.suit
            let winner = nextTrick
                .filter { $0.card.suit == leadSuit }
                .max { $0.card.rank.value < $1.card.rank.value }!

            let trickCards = nextTrick.map { $0.card }
            nextWonCards[winner.playerIndex].append(contentsOf: trickCards)
            nextPlayedCards.append(contentsOf: trickCards)

            // --- CORRECTED LOGIC: Update heartsBroken ONLY after the trick is complete ---
            if !nextHeartsBroken {
                nextHeartsBroken = trickCards.contains { $0.suit == .hearts }
            }

            nextTrick = []
            nextPlayer = winner.playerIndex
        }

        return HeartsGameState(
            playersHands: nextHands,
            playedCardsThisRound: nextPlayedCards,
            currentTrick: nextTrick,
            heartsBroken: nextHeartsBroken, // Use the correctly updated status
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
        // Sort each hand so the order of cards doesn't affect the hash
        for hand in playersHands {
            for card in hand.sorted() { // Assuming Card is Comparable
                hasher.combine(card)
            }
        }
        // The rest can remain the same as order matters for them
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

// MARK: - Hearts MCTS AI (Updated Logic with Safety Checks)
class AIPlayingStrategy {

    // --- IMPERFECT INFORMATION FIX: Monte Carlo Sampling ---

    /**
    Samples the unknown cards and distributes them to the opponents.
    
    IMPROVEMENT: This function now "cheats" by incorporating the human player's
    hand (assumed to be player index 0) into the known state, significantly
    improving MCTS accuracy against the human.
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
        let humanPlayerIndex = 0 // ASSUMPTION: The human player is always at index 0

        // 1. Identify all known cards
        var knownCards = Set(playerHand)
        
        // --- CHEAT: Add Human Player's Hand to known cards ---
        let humanHand = players[humanPlayerIndex].hand
        knownCards.formUnion(humanHand)
        // -----------------------------------------------------

        knownCards.formUnion(playedCardsThisRound)
        knownCards.formUnion(currentTrick.map { $0.card })
        // 2. Identify all unknown cards (only the two other AI opponents' hands are unknown now)
        var unknownCards = allCards.filter { !knownCards.contains($0) }
        unknownCards.shuffle()
        // 3. Determine how many cards each opponent must have
        let currentHandCount = playerHand.count
        var hands: [[Card]] = Array(repeating: [], count: numPlayers)
        hands[playerIndex] = playerHand        // AI's hand is 100% known
        hands[humanPlayerIndex] = humanHand    // CHEAT: Human's hand is 100% known
        // 4. Distribute unknown cards to the two remaining AI opponents (i.e., player 1 and 2 if AI is 3)
        var unknownCardsIndex = 0
        for i in 0..<numPlayers {
            // Only distribute to the *other* AI opponents (excluding the AI running the search and the known human player)
            if i != playerIndex && i != humanPlayerIndex {
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
        let won: [[Card]] = players.map { _ in [] }
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
    
    // --- MAIN AI STRATEGY with SAFETY CHECKS ---
    static func selectCard(playerIndex: Int,
                            players: [Player],
                            currentTrick: [(playerIndex: Int, card: Card)],
                            heartsBroken: Bool,
                            playedCardsThisRound: [Card],
                            iterations: Int,
                            numSamples: Int) -> Card? {
        
        let playerHand = players[playerIndex].hand
        
        // 1. SAFETY CHECK: If hand is empty, return nil
        guard !playerHand.isEmpty else {
            return nil
        }
        
        // 2. Pre-check: Find the legal moves for the current (real) state
        let legalMoves = HeartsGameState.RuleValidator.getLegalCards(
            hand: playerHand,
            playedCards: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: playedCardsThisRound.isEmpty && currentTrick.isEmpty
        )
        
        // 3. SAFETY CHECK: If no legal moves, return first card (should not happen)
        guard !legalMoves.isEmpty else {
            return playerHand.first
        }
        
        // 4. EARLY EXIT: If only one legal move, return it immediately
        if legalMoves.count == 1 {
            return legalMoves.first
        }
        
        var moveScores: [Card: Double] = [:]
        
        // 5. Monte Carlo Tree Search with Playouts (MCTS-P)
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
                var selectionDepth = 0
                let maxSelectionDepth = 100 // SAFETY: Prevent infinite selection
                
                while node.untriedMoves.isEmpty && !node.children.isEmpty && selectionDepth < maxSelectionDepth {
                    if let bestChild = node.bestChild() {
                        node = bestChild
                        selectionDepth += 1
                    } else {
                        break
                    }
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
                // The move played to get to this child
                // Need to find which card was played to reach this child
                let childTrick = child.state.currentTrick
                let parentTrick = root.state.currentTrick
                
                // The new card in the child's trick that wasn't in parent
                if childTrick.count > parentTrick.count {
                    let move = childTrick.last!.card
                    let avgScore = child.visits > 0 ? child.totalScore / Double(child.visits) : 0.0
                    // Sum the average score for each move across all samples
                    moveScores[move, default: 0.0] += avgScore
                }
            }
        }
        
        // 6. Select the move with the highest average score (highest score differential)
        guard !moveScores.isEmpty else {
            return legalMoves.first
        }

        let bestMove = moveScores.max { $0.value < $1.value }!
        return bestMove.key
    }

    // --- IMPROVED ROLLOUT & REWARD FUNCTION with SAFETY ---

    private static func rollout(state: HeartsGameState, aiPlayer: Int) -> Double {
        var state = state
        var rolloutSteps = 0
        let maxRolloutSteps = 100 // SAFETY: Prevent infinite rollout (13 tricks * 4 players = 52 max)

        // Playout: use the heuristic until terminal state is reached
        while !state.isTerminal() && rolloutSteps < maxRolloutSteps {
            let legal = state.legalMoves()
            if legal.isEmpty {
                break
            }
            
            // Apply the heuristic to *all* players during rollout for realistic play
            let move = rolloutHeuristicMove(state: state, legalMoves: legal)
            state = state.playCard(move)
            rolloutSteps += 1
        }

        let aiFinalScore = state.score(for: aiPlayer)
        // --- REWARD CALCULATION (Updated: Maximize Score Differential) ---
        var opponentsTotalScore = 0
        for i in 0..<4 where i != aiPlayer {
            opponentsTotalScore += state.score(for: i)
        }
        
        // Calculate the score differential (Opponents' score - AI's score).
        // Maximizing this differential is equivalent to minimizing AI's score
        // AND maximizing opponents' scores.
        let scoreDifferential = Double(opponentsTotalScore - aiFinalScore)
        
        // 1. Shoot the Moon Check
        if aiFinalScore == 26 {
            // If AI shoots the moon, it gets 0 points. Opponents get 26.
            // Massive positive reward for the AI.
            return 10000.0
        }
        
        // 2. Normal Play: Reward is the score differential.
        return scoreDifferential
    }

    // --- REWRITTEN SMARTER ROLLOUT HEURISTIC ---

    /**
    A smarter heuristic for use during the Playout/Simulation phase.
    It prioritizes losing tricks safely over aggressively dumping points.
    */
    private static func rolloutHeuristicMove(state: HeartsGameState, legalMoves: [Card]) -> Card {
        guard !legalMoves.isEmpty else {
            fatalError("Rollout heuristic called with no legal moves.")
        }
        
        let isLeading = state.currentTrick.isEmpty
        
        // --- 1. Strategy for LEADING a Trick ---
        if isLeading {
            // A. Lead the lowest card possible in a non-point suit (to lose lead safely and short the suit)
            let safeLeads = legalMoves.filter { $0.points == 0 }
            if !safeLeads.isEmpty {
                // Find the card that is lowest and in the shortest suit (more valuable to dump)
                // We will simplify and just find the absolute lowest rank card.
                return safeLeads.min { $0.rank.value < $1.rank.value }!
            } else {
                // B. Must lead points (hand is all hearts/Q♠). Lead the lowest card to minimize damage.
                return legalMoves.min { $0.rank.value < $1.rank.value }!
            }
        }
        
        // --- 2. Strategy for FOLLOWING a Trick (Non-Leading) ---
        let leadCard = state.currentTrick[0].card
        let leadSuit = leadCard.suit
        
        // Find the winning card of the trick *so far*
        let currentWinningCardValue = state.currentTrick
            .filter { $0.card.suit == leadSuit }
            .max { $0.card.rank.value < $1.card.rank.value }!
            .card.rank.value
        
        // A. Following Suit
        let followingSuit = legalMoves.filter { $0.suit == leadSuit }
        if !followingSuit.isEmpty {
            
            // Try to DUCK: play the highest card that WON'T win the trick.
            let nonWinningCards = followingSuit.filter { $0.rank.value < currentWinningCardValue }
            if let bestDuck = nonWinningCards.max(by: { $0.rank.value < $1.rank.value }) {
                return bestDuck
            }
            
            // If forced to win: play the lowest card possible to win (to conserve high cards)
            let winningCards = followingSuit.filter { $0.rank.value > currentWinningCardValue }
            if let lowestToWin = winningCards.min(by: { $0.rank.value < $1.rank.value }) {
                return lowestToWin
            }
            
            // If all cards lose or all cards win and the filter above failed (e.g., only one card left)
            // Default to playing the absolute lowest card to conserve
            if let lowestCard = followingSuit.min(by: { $0.rank.value < $1.rank.value }) {
                return lowestCard
            }
        }
        
        // B. Void in Suit (Sloughing) - A much smarter strategy
        // 1. Always dump the Queen of Spades if possible.
        if let queenOfSpades = legalMoves.first(where: { $0.isQueenOfSpades }) {
            return queenOfSpades
        }
        
        // 2. Dump the highest point card (Hearts). Get rid of dangerous high hearts.
        let pointCards = legalMoves.filter { $0.points > 0 }
        if let highestPointCard = pointCards.max(by: { $0.rank.value < $1.rank.value }) {
            return highestPointCard
        }
        
        // 3. If no point cards can be dumped, dump the HIGHEST non-point card
        //    (e.g., Ace of Clubs) to avoid winning a future trick in that suit.
        if let highestSafeCard = legalMoves.max(by: { $0.rank.value < $1.rank.value }) {
            return highestSafeCard
        }
        
        // Fallback, should not be reached if legalMoves is not empty.
        return legalMoves.first!
    }
}
