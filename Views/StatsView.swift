import SwiftUI

struct StatsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var allStats: [PlayerStats] = []
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(allStats, id: \.playerName) { stats in
                        PlayerStatsCard(stats: stats)
                    }
                }
                .padding()
            }
            .background(Color.green.opacity(0.3))
            .navigationTitle("Player Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showResetAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Reset All Statistics?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllStats()
                }
            } message: {
                Text("This will permanently delete all player statistics. This action cannot be undone.")
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        allStats = StatsManager.shared.loadAllStats()
    }
    
    private func resetAllStats() {
        StatsManager.shared.resetAllStats()
        loadStats()
    }
}

struct PlayerStatsCard: View {
    let stats: PlayerStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Player Name Header
            Text(stats.playerName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 5)
            
            if stats.gamesPlayed == 0 && stats.totalRoundsPlayed == 0 {
                Text("No games played yet")
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Game Stats Section
                StatsSectionView(title: "Game Statistics") {
                    StatRow(label: "Games Played", value: "\(stats.gamesPlayed)")
                    StatRow(label: "Games Won", value: "\(stats.gamesWon)")
                    StatRow(label: "Win Rate", value: String(format: "%.1f%%", stats.winRate))
                    StatRow(label: "Avg Final Score", value: String(format: "%.1f", stats.averageFinalScore))
                    
                    if let best = stats.bestGame {
                        StatRow(label: "Best Game", value: "\(best)", highlight: .green)
                    }
                    if let worst = stats.worstGame {
                        StatRow(label: "Worst Game", value: "\(worst)", highlight: .red)
                    }
                }
                
                // Round Stats Section
                StatsSectionView(title: "Round Statistics") {
                    StatRow(label: "Total Rounds", value: "\(stats.totalRoundsPlayed)")
                    StatRow(label: "Rounds Won", value: "\(stats.roundsWon)")
                    StatRow(label: "Clean Rounds", value: "\(stats.cleanRounds)", highlight: .green)
                    StatRow(label: "Avg Points/Round", value: String(format: "%.1f", stats.averagePointsPerRound))
                }
                
                // Achievements Section
                StatsSectionView(title: "Achievements") {
                    StatRow(label: "Moons Shot", value: "\(stats.moonsShot)", highlight: .yellow)
                    StatRow(label: "Queens Taken", value: "\(stats.queensTaken)")
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
    }
}

struct StatsSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.yellow)
                .padding(.bottom, 2)
            
            content
        }
        .padding(.bottom, 5)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var highlight: Color? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Text(value)
                .foregroundColor(highlight ?? .white)
                .fontWeight(highlight != nil ? .bold : .regular)
        }
        .font(.subheadline)
    }
}

// Preview
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
