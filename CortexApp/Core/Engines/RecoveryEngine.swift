import Foundation

enum BrainState: String, Equatable {
    case inflamed
    case recovering
    case balanced
    case optimized

    var title: String {
        switch self {
        case .inflamed: return "INÍCIO"
        case .recovering: return "EM FLUXO"
        case .balanced: return "INTEGRAÇÃO"
        case .optimized: return "CONSOLIDADO"
        }
    }
}

struct RecoverySnapshot: Equatable {
    let currentDay: Int
    let recoveryScore: Double
    let currentStreak: Int
    let alignedDays: Int
    let slips: Int
    let hoursRecovered: Double
    let brainState: BrainState
    let isFlatlineWindow: Bool
}

struct RecoveryEngine {
    private static let secondsPerDay: TimeInterval = 86_400

    /// Builds the current cycle from the profile start date. Check-ins are journal
    /// records only and never advance, pause or reduce the automatic day counter.
    static func snapshot(
        profile: UserProfile,
        checkIns: [DailyCheckIn],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> RecoverySnapshot {
        let cycleStart = min(profile.startDate, now)
        let elapsedSeconds = max(0, now.timeIntervalSince(cycleStart))

        // A day is earned only after a complete 24-hour interval. Calendar
        // midnights never advance the counter on their own.
        let currentDay = Int(elapsedSeconds / secondsPerDay)
        let elapsedDays = elapsedSeconds / secondsPerDay
        let targetSpan = Double(max(profile.targetDays, 1))
        let progress = min(max(Double(currentDay) / targetSpan, 0), 1)

        let currentCycleEntries = checkIns.filter { $0.date >= cycleStart && $0.date <= now }
        let uniqueByDay = Dictionary(grouping: currentCycleEntries) {
            calendar.startOfDay(for: $0.date)
        }
        .compactMapValues { entries in
            entries.sorted { $0.date > $1.date }.first
        }
        let daily = Array(uniqueByDay.values)
        let observations = daily.filter { $0.status == .aligned }.count
        let lifetimeRelapses = checkIns.filter { $0.status == .slip && $0.date <= now }.count

        // The estimate is based on the user's average minutes spent per day and
        // the exact elapsed time since the account was created or the last relapse.
        let recoveredHours = elapsedDays * Double(max(profile.dailyUsageMinutes, 0)) / 60

        return RecoverySnapshot(
            currentDay: currentDay,
            recoveryScore: progress,
            currentStreak: currentDay,
            alignedDays: observations,
            slips: lifetimeRelapses,
            hoursRecovered: recoveredHours,
            brainState: brainState(for: progress),
            isFlatlineWindow: (14...25).contains(currentDay)
        )
    }

    static func brainState(for score: Double) -> BrainState {
        switch score {
        case ..<0.25: return .inflamed
        case ..<0.55: return .recovering
        case ..<0.82: return .balanced
        default: return .optimized
        }
    }
}
