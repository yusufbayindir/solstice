import Foundation
import SwiftData

enum Symptom: String, Codable, CaseIterable, Sendable {
    case cramps
    case headache
    case bloating
    case fatigue
    case backache
    case breastTenderness
    case nausea
    case spotting

    var displayName: String {
        switch self {
        case .cramps: return "Cramps"
        case .headache: return "Headache"
        case .bloating: return "Bloating"
        case .fatigue: return "Fatigue"
        case .backache: return "Backache"
        case .breastTenderness: return "Breast Tenderness"
        case .nausea: return "Nausea"
        case .spotting: return "Spotting"
        }
    }
}

@Model
final class SymptomLog {
    var date: Date
    var symptom: Symptom
    var intensity: Int

    init(date: Date, symptom: Symptom, intensity: Int) {
        self.date = date
        self.symptom = symptom
        self.intensity = max(1, min(3, intensity))
    }
}
