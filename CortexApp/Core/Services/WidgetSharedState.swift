import Foundation
import WidgetKit

struct WidgetSharedState {
    static func update(profile: UserProfile, snapshot: RecoverySnapshot) {
        let widgetSnapshot = CortexWidgetSnapshot(
            alterName: profile.alterName,
            recoveryScore: snapshot.recoveryScore,
            neuralState: snapshot.brainState.title,
            currentDay: snapshot.currentDay,
            cycleStartDate: profile.startDate,
            targetDays: profile.targetDays
        )
        guard let data = try? JSONEncoder().encode(widgetSnapshot) else { return }
        let defaults = UserDefaults(suiteName: CortexShared.appGroup) ?? .standard
        defaults.set(data, forKey: CortexShared.snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
