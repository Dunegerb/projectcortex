import XCTest
@testable import Cortex

final class RecoveryEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var now: Date {
        calendar.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 25,
            hour: 12
        ))!
    }

    func testDayCountAdvancesWithoutCheckIn() {
        let start = calendar.date(byAdding: .day, value: -10, to: now)!
        let profile = makeProfile(startDate: start)

        let snapshot = RecoveryEngine.snapshot(
            profile: profile,
            checkIns: [],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.currentDay, 11)
        XCTAssertEqual(snapshot.currentStreak, 11)
        XCTAssertEqual(snapshot.alignedDays, 0)
    }

    func testCheckInsDoNotControlAutomaticProgress() {
        let start = calendar.date(byAdding: .day, value: -20, to: now)!
        let profile = makeProfile(startDate: start)
        let entries = [
            DailyCheckIn(date: calendar.date(byAdding: .day, value: -1, to: now)!, status: .aligned),
            DailyCheckIn(date: calendar.date(byAdding: .day, value: -3, to: now)!, status: .slip)
        ]

        let withEntries = RecoveryEngine.snapshot(
            profile: profile,
            checkIns: entries,
            now: now,
            calendar: calendar
        )
        let withoutEntries = RecoveryEngine.snapshot(
            profile: profile,
            checkIns: [],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(withEntries.currentDay, withoutEntries.currentDay)
        XCTAssertEqual(withEntries.recoveryScore, withoutEntries.recoveryScore, accuracy: 0.000_001)
        XCTAssertEqual(withEntries.slips, 1)
    }

    func testRecoveredTimeUsesExactTimeSinceCycleStart() {
        let start = calendar.date(byAdding: .hour, value: -48, to: now)!
        let profile = makeProfile(startDate: start, dailyMinutes: 45)

        let snapshot = RecoveryEngine.snapshot(
            profile: profile,
            checkIns: [],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.hoursRecovered, 1.5, accuracy: 0.001)
    }

    func testResetStartDateBeginsNewCycleAtDayOne() {
        let oldRelapse = DailyCheckIn(
            date: calendar.date(byAdding: .day, value: -10, to: now)!,
            status: .slip
        )
        let profile = makeProfile(startDate: now)

        let snapshot = RecoveryEngine.snapshot(
            profile: profile,
            checkIns: [oldRelapse],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.currentDay, 1)
        XCTAssertEqual(snapshot.hoursRecovered, 0, accuracy: 0.001)
        XCTAssertEqual(snapshot.slips, 1)
    }

    func testProgressCapsAtOne() {
        let start = calendar.date(byAdding: .day, value: -120, to: now)!
        let profile = makeProfile(startDate: start)

        let snapshot = RecoveryEngine.snapshot(
            profile: profile,
            checkIns: [],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.recoveryScore, 1, accuracy: 0.000_001)
        XCTAssertGreaterThanOrEqual(snapshot.currentDay, 90)
    }

    private func makeProfile(startDate: Date, dailyMinutes: Int = 45) -> UserProfile {
        UserProfile(
            realName: "Pessoa",
            alterName: "Atlas",
            archetype: .strategist,
            mission: "Concluir um projeto",
            manifesto: "Manifesto",
            losses: ["Energia", "Foco", "Tempo"],
            startDate: startDate,
            dailyUsageMinutes: dailyMinutes
        )
    }
}
