//import SwiftUI
//
//enum Suit: String, CaseIterable {
//    case hearts = "♥️"
//    case spades = "♠️"
//    case diamonds = "♦️"
//    case clubs = "♣️"
//    
//    var color: Color {
//        self == .hearts || self == .diamonds ? .red : .black
//    }
//}
//
//enum Rank: String, CaseIterable {
//    case two = "2", three = "3", four = "4", five = "5", six = "6"
//    case seven = "7", eight = "8", nine = "9", ten = "10"
//    case jack = "J", queen = "Q", king = "K", ace = "A"
//}
//
//struct Card: Identifiable, Equatable {
//    let id = UUID()
//    let rank: Rank
//    let suit: Suit
//    
//    static func == (lhs: Card, rhs: Card) -> Bool {
//        lhs.rank == rhs.rank && lhs.suit == rhs.suit
//    }
//}
//
//struct Player {
//    let name: String
//    let isHuman: Bool
//    var hand: [Card]
//}
//
//struct ContentView: View {
//    @State var players: [Player] = []
//    @State var currentPlayerIndex = 0
//    @State var playedCards: [(playerIndex: Int, card: Card)] = []
//    
//    var body: some View {
//        ZStack {
//            Color.green.ignoresSafeArea()
//            
//            if players.isEmpty {
//                Text("Loading...")
//                    .foregroundColor(.white)
//            } else {
//                VStack(spacing: 20) {
//                    Text(players[currentPlayerIndex].isHuman ? "YOUR TURN" : "\(players[currentPlayerIndex].name)'S TURN")
//                        .font(.title)
//                        .foregroundColor(.yellow)
//                    
//                    HStack {
//                        ForEach(0..<players.count, id: \.self) { i in
//                            VStack {
//                                Text(players[i].name)
//                                    .foregroundColor(.white)
//                                Text("\(players[i].hand.count) cards")
//                                    .foregroundColor(.white)
//                                    .font(.caption)
//                            }
//                            .padding(8)
//                            .background(i == currentPlayerIndex ? Color.yellow.opacity(0.3) : Color.clear)
//                            .cornerRadius(8)
//                        }
//                    }
//                    
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 15)
//                            .fill(Color.black.opacity(0.3))
//                            .frame(height: 200)
//                        
//                        HStack {
//                            ForEach(playedCards, id: \.playerIndex) { play in
//                                VStack {
//                                    Text(players[play.playerIndex].name)
//                                        .font(.caption)
//                                        .foregroundColor(.white)
//                                    CardView(rank: play.card.rank.rawValue, suit: play.card.suit.rawValue, color: play.card.suit.color)
//                                }
//                            }
//                        }
//                    }
//                    .padding()
//                    
//                    Spacer()
//                    
//                    HStack(spacing: -20) {
//                        ForEach(players[0].hand) { card in
//                            Button(action: {
//                                if currentPlayerIndex == 0 {
//                                    playCard(card)
//                                }
//                            }) {
//                                CardView(rank: card.rank.rawValue, suit: card.suit.rawValue, color: card.suit.color)
//                            }
//                            .disabled(currentPlayerIndex != 0)
//                            .opacity(currentPlayerIndex == 0 ? 1.0 : 0.5)
//                        }
//                    }
//                    .padding()
//                }
//            }
//        }
//        .onAppear {
//            setupGame()
//        }
//    }
//    
//    func setupGame() {
//        var deck: [Card] = []
//        for suit in Suit.allCases {
//            for rank in Rank.allCases {
//                deck.append(Card(rank: rank, suit: suit))
//            }
//        }
//        deck.shuffle()
//        
//        players = [
//            Player(name: "You", isHuman: true, hand: Array(deck[0..<13])),
//            Player(name: "Bob", isHuman: false, hand: Array(deck[13..<26])),
//            Player(name: "Abby", isHuman: false, hand: Array(deck[26..<39])),
//            Player(name: "Emma", isHuman: false, hand: Array(deck[39..<52]))
//        ]
//    }
//    
//    func playCard(_ card: Card) {
//        if let index = players[currentPlayerIndex].hand.firstIndex(of: card) {
//            let removed = players[currentPlayerIndex].hand.remove(at: index)
//            playedCards.append((currentPlayerIndex, removed))
//            
//            if playedCards.count == 4 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    playedCards = []
//                    currentPlayerIndex = 0
//                    playAITurn()
//                }
//            } else {
//                currentPlayerIndex = (currentPlayerIndex + 1) % 4
//                playAITurn()
//            }
//        }
//    }
//    
//    func playAITurn() {
//        if !players[currentPlayerIndex].isHuman && !players[currentPlayerIndex].hand.isEmpty {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
//                if let randomCard = players[currentPlayerIndex].hand.randomElement() {
//                    playCard(randomCard)
//                }
//            }
//        }
//    }
//}
//
//struct CardView: View {
//    let rank: String
//    let suit: String
//    let color: Color
//    
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 8)
//                .fill(Color.white)
//                .frame(width: 70, height: 100)
//            
//            VStack {
//                Text(rank)
//                    .font(.title)
//                    .foregroundColor(color)
//                Text(suit)
//                    .font(.title)
//            }
//        }
//    }
//}
