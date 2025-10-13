import SwiftUI
import Combine

enum Suit: String, CaseIterable {
    case clubs = "♣️"
    case diamonds = "♦️"
    case spades = "♠️"
    case hearts = "♥️"
    
    var color: Color {
        switch self {
        case .hearts, .diamonds: return .red
        case .clubs, .spades: return .black
        }
    }
}
enum Rank: String, CaseIterable {
    case two = "2", three = "3", four = "4", five = "5", six = "6"
    case seven = "7", eight = "8", nine = "9", ten = "10"
    case jack = "J", queen = "Q", king = "K", ace = "A"
    
    var value: Int {
        switch self {
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 8
        case .nine: return 9
        case .ten: return 10
        case .jack: return 11
        case .queen: return 12
        case .king: return 13
        case .ace: return 14
        }
    }
}

struct Card: Identifiable, Equatable, Hashable {
    let id = UUID()
    let rank: Rank
    let suit: Suit
    
    var points: Int {
        if suit == .hearts { return 1 }
        if suit == .spades && rank == .queen { return 13 }
        return 0
    }
    
    var isTwoOfClubs: Bool {
        rank == .two && suit == .clubs
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.rank == rhs.rank && lhs.suit == rhs.suit
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rank)
        hasher.combine(suit)
    }
}
