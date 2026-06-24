import Foundation
import SwiftData

@Model
final class AppSettings {
    var averageCycleLength: Int
    var averagePeriodLength: Int
    var lastPeriodStart: Date?
    var appLockEnabled: Bool
    var notificationsEnabled: Bool
    var healthKitSyncEnabled: Bool

    init(
        averageCycleLength: Int = 28,
        averagePeriodLength: Int = 5,
        lastPeriodStart: Date? = nil,
        appLockEnabled: Bool = false,
        notificationsEnabled: Bool = false,
        healthKitSyncEnabled: Bool = false
    ) {
        self.averageCycleLength = averageCycleLength
        self.averagePeriodLength = averagePeriodLength
        self.lastPeriodStart = lastPeriodStart
        self.appLockEnabled = appLockEnabled
        self.notificationsEnabled = notificationsEnabled
        self.healthKitSyncEnabled = healthKitSyncEnabled
    }
}
