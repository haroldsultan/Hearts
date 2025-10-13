import SwiftUI

struct CardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(radius: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1)
                )

            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(card.rank.rawValue)
                            .font(.headline)
                        Text(card.suit.rawValue)
                            .font(.subheadline)
                    }
                    .foregroundColor(card.suit.color)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(card.rank.rawValue)
                            .font(.headline)
                        Text(card.suit.rawValue)
                            .font(.subheadline)
                    }
                    .foregroundColor(card.suit.color)
                    .rotationEffect(.degrees(180))
                }
            }
            .padding(6)
        }
        .frame(width: 75, height: 112) // standard card ratio ~2:3
    }
}
