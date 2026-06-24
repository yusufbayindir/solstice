import Foundation
import SwiftData

enum Mood: String, Codable, CaseIterable, Sendable {
    case happy
    case calm
    case anxious
    case sad
    case irritable
    case energetic
    case tired

    var displayName: String {
        switch self {
        case .happy: return "Happy"
        case .calm: return "Calm"
        case .anxious: return "Anxious"
        case .sad: return "Sad"
        case .irritable: return "Irritable"
        case .energetic: return "Energetic"
        case .tired: return "Tired"
        }
    }
}

@Model
final class MoodLog {
    var date: Date
    var mood: Mood

    init(date: Date, mood: Mood) {
        self.date = date
        self.mood = mood
    }
}
