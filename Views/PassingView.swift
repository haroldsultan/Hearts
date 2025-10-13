import SwiftUI

struct PassingView: View {
    let hand: [Card]
    let selectedCards: Set<Card>
    let passDirection: String
    let onCardTap: (Card) -> Void
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Pass 3 Cards \(passDirection)")
                .font(.title)
                .foregroundColor(.white)
            
            Text("Selected: \(selectedCards.count) / 3")
                .font(.headline)
                .foregroundColor(selectedCards.count == 3 ? .green : .yellow)
            
            Spacer()
            
            GeometryReader { geometry in
                let totalCards = hand.count
                let spacing: CGFloat = 25
                
                ZStack {
                    ForEach(Array(hand.enumerated()), id: \.element.id) { index, card in
                        let centerIndex = CGFloat(totalCards - 1) / 2
                        let xOffset = (CGFloat(index) - centerIndex) * spacing
                        let isSelected = selectedCards.contains(card)
                        
                        Button(action: {
                            onCardTap(card)
                        }) {
                            CardView(card: card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 4)
                                )
                                .scaleEffect(isSelected ? 1.15 : 1.0)
                                .rotationEffect(.degrees(Double(index) - Double(centerIndex)) * 5)
                        }
                        .offset(x: xOffset, y: 0)
                    }
                }
                .scaleEffect(0.95)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)
            }
            .frame(height: 200)
            .padding(.horizontal)
            
            Button(action: onSubmit) {
                Text("Pass Cards")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(selectedCards.count == 3 ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(selectedCards.count != 3)
            .padding(.bottom, 30)
        }
    }
}
