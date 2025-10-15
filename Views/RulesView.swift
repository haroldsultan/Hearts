import SwiftUI

// 1. Data Model for a Rule
// This separates the data from the view logic, making it easier to manage.
struct Rule: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let icon: String // SF Symbol name for the section header
}

struct RulesView: View {
    @Environment(\.dismiss) var dismiss
    
    // 2. Data Source
    // All rules are now defined cleanly in one place as an array of Rule objects.
    private let rules: [Rule] = [
        Rule(title: "Objective",
             content: "The goal is to have the LOWEST score when one player reaches 100 points. Avoid taking Hearts (1 point each) and the Queen of Spades (13 points).",
             icon: "target"),
        Rule(title: "Gameplay",
             content: "• The player with the 2 of Clubs (2♣) leads the first trick.\n• You must follow the suit that was led if you can.\n• The highest card of the lead suit wins the trick.\n• The winner of a trick leads the next one.\n• You cannot lead with a Heart until Hearts have been 'broken' (played on another suit).\n• You cannot play point cards (any Heart or the Q♠) on the first trick.",
             icon: "gamecontroller"),
        Rule(title: "Scoring",
             content: "• Each Heart card ♥ is worth 1 point.\n• The Queen of Spades Q♠ is worth 13 points.\n• The game ends when a player's score reaches or exceeds 100 points. The player with the lowest score wins!",
             icon: "plusminus.circle"),
        Rule(title: "Shooting the Moon 🌙",
             content: "If you manage to take ALL the points in a round (all 13 Hearts and the Q♠), you get 0 points, and every other player gets 26 points. It's a high-risk, high-reward strategy!",
             icon: "moon.stars"),
        Rule(title: "Card Passing",
             content: "At the start of each round, pass 3 cards:\n• Round 1: Pass LEFT\n• Round 2: Pass ACROSS\n• Round 3: Pass RIGHT\n• Round 4: NO PASS\nThe cycle then repeats.",
             icon: "arrow.left.arrow.right.square"),
        Rule(title: "Strategy Tips",
             content: "• Pass your high-value cards (especially Spades) to your opponents.\n• Try to create a 'void' in a suit so you can discard point cards when that suit is led.\n• Keep track of which important cards have been played.",
             icon: "lightbulb")
    ]
    
    var body: some View {
        // 3. Use NavigationStack for modern navigation
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 4. Loop over the data model
                    // The ForEach makes the body extremely clean and simple.
                    ForEach(rules) { rule in
                        RuleSectionView(rule: rule)
                    }
                }
                .padding()
            }
            .navigationTitle("How to Play Hearts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { // More semantic placement
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 5. Reusable View Component
// This is a more robust and reusable way to define the section UI.
struct RuleSectionView: View {
    let rule: Rule
    
    var body: some View {
        // Using Section gives a nice, standard visual grouping.
        Section {
            // Using AttributedString to properly render bullet points.
            Text(LocalizedStringKey(rule.content))
                .font(.body)
                .lineSpacing(5)
        } header: {
            Label(rule.title, systemImage: rule.icon)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 5)
        }
    }
}


// Optional: Add a preview to see your changes easily
struct RulesView_Previews: PreviewProvider {
    static var previews: some View {
        RulesView()
    }
}
