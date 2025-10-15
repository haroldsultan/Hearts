// Add this enum at the top level
enum DifficultyLevel: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var iterations: Int {
        switch self {
        case .easy: return 500
        case .medium: return 1500
        case .hard: return 2000
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}
