import SwiftUI
import Combine

struct GameView: View {
    @StateObject var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            if !viewModel.gameStarted {
                VStack(spacing: 20) {
                    Text("Round \(viewModel.roundNumber) Complete!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 10) {
                        ForEach(0..<viewModel.players.count, id: \.self) { i in
                            HStack {
                                Text(viewModel.players[i].name)
                                    .foregroundColor(.white)
                                    .frame(width: 80, alignment: .leading)
                                Text("This Round: +\(viewModel.players[i].lastRoundScore)")
                                    .foregroundColor(.yellow)
                                    .frame(width: 150)
                                
                                Text("Total: \(viewModel.players[i].score)")
                                    .foregroundColor(.white)
                                    .font(.title3)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Button("Start Next Round") {
                        viewModel.setupGame()
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 20)
                }
            } else {
                VStack(spacing: 20) {
                    Text(viewModel.players[viewModel.currentPlayerIndex].isHuman ? "YOUR TURN" : "\(viewModel.players[viewModel.currentPlayerIndex].name)'S TURN")
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    HStack {
                        ForEach(0..<viewModel.players.count, id: \.self) { i in
                            VStack {
                                Text(viewModel.players[i].name)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Text("Round: +\(viewModel.players[i].roundScore)")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text("Total: \(viewModel.players[i].score)")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                Text("\(viewModel.players[i].hand.count) cards")
                                    .foregroundColor(.gray)
                                    .font(.caption2)
                            }
                            .padding(8)
                            .background(i == viewModel.currentPlayerIndex ? Color.yellow.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 200)
                        
                        HStack(spacing: 15) {
                            ForEach(viewModel.playedCards, id: \.playerIndex) { play in
                                VStack {
                                    Text(viewModel.players[play.playerIndex].name)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    CardView(card: play.card)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    GeometryReader { geometry in
                        let hand = viewModel.players[0].sortedHand
                        let totalCards = hand.count
                        let spacing: CGFloat = 25
                        let isFirstTrick = RuleValidator.isFirstTrick(players: viewModel.players)
                        let legalCards = RuleValidator.getLegalCards(
                            hand: hand,
                            playedCards: viewModel.playedCards,
                            heartsBroken: viewModel.heartsBroken,
                            isFirstTrick: isFirstTrick
                        )

                        ZStack {
                            ForEach(Array(hand.enumerated()), id: \.element.id) { index, card in
                                let centerIndex = CGFloat(totalCards - 1) / 2
                                let xOffset = (CGFloat(index) - centerIndex) * spacing
                                let isLegal = legalCards.contains(card)

                                Button(action: {
                                    if viewModel.currentPlayerIndex == 0 && isLegal {
                                        viewModel.playCard(card)
                                    }
                                }) {
                                    CardView(card: card)
                                        .rotationEffect(.degrees(Double(index) - Double(centerIndex)) * 5)
                                        .opacity(isLegal && viewModel.currentPlayerIndex == 0 ? 1.0 : 0.4)
                                }
                                .offset(x: xOffset, y: 0)
                                .disabled(viewModel.currentPlayerIndex != 0 || !isLegal)
                            }
                        }
                        .scaleEffect(0.95)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 12)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                }
            }
        }
    }
}
