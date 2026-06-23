import Foundation
import SwiftData

@Model
final class CycleEntry {
    var id: UUID
    var periodStart: Date
    var periodEnd: Date?
    var cycleLength: Int?
    var notes: String

    @Relationship(deleteRule: .cascade)
    var symptomLogs: [SymptomLog]

    @Relationship(deleteRule: .cascade)
    var moodLogs: [MoodLog]

    init(
        id: UUID = UUID(),
        periodStart: Date,
        periodEnd: Date? = nil,
        cycleLength: Int? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.cycleLength = cycleLength
        self.notes = notes
        self.symptomLogs = []
        self.moodLogs = []
    }
}
