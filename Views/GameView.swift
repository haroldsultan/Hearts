
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
                                
                                Text("This Round: +\(viewModel.players[i].roundScore)")
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
                                Text("Score: \(viewModel.players[i].score)")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                Text("\(viewModel.players[i].hand.count) cards")
                                    .foregroundColor(.white)
                                    .font(.caption)
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
                    
                    HStack(spacing: -20) {
                        ForEach(viewModel.players[0].hand) { card in
                            Button(action: {
                                if viewModel.currentPlayerIndex == 0 {
                                    viewModel.playCard(card)
                                }
                            }) {
                                CardView(card: card)
                            }
                            .disabled(viewModel.currentPlayerIndex != 0)
                            .opacity(viewModel.currentPlayerIndex == 0 ? 1.0 : 0.5)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if viewModel.players.isEmpty {
                viewModel.setupGame()
            }
        }
    }
}
