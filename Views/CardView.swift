import SwiftUI
import Combine

struct CardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 70, height: 100)
            
            VStack(spacing: 4) {
                Text(card.rank.rawValue)
                    .font(.title)
                    .foregroundColor(card.suit.color)
                Text(card.suit.rawValue)
                    .font(.title)
            }
        }
    }
}
