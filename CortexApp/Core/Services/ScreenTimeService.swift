import Combine
import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

extension ManagedSettingsStore.Name {
    static let cortex = Self("cortex")
}

extension DeviceActivityName {
    static let cortexDaily = Self("cortex.daily")
}

@MainActor
final class ScreenTimeService: ObservableObject {
    static let shared = ScreenTimeService()

    @Published var selection = FamilyActivitySelection()
    @Published private(set) var authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    @Published private(set) var shieldsApplied = false
    @Published var lastError: String?

    private let store = ManagedSettingsStore(named: .cortex)
    private let activityCenter = DeviceActivityCenter()
    private let selectionKey = "cortex.family.selection"

    private init() {
        restoreSelection()
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            lastError = nil
        } catch {
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            lastError = error.localizedDescription
        }
    }

    func applyShields() {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        shieldsApplied = !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty
        scheduleDailyMonitoring()
        persistSelection()
    }

    func removeShields() {
        store.clearAllSettings()
        activityCenter.stopMonitoring([.cortexDaily])
        shieldsApplied = false
    }

    func restoreAndApplyIfNeeded() {
        restoreSelection()
        if UserDefaults.standard.bool(forKey: "cortex.shield.enabled") {
            applyShields()
        }
    }

    private func scheduleDailyMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        do {
            try activityCenter.startMonitoring(.cortexDaily, during: schedule)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func persistSelection() {
        guard let encoded = try? JSONEncoder().encode(selection) else { return }
        UserDefaults.standard.set(encoded, forKey: selectionKey)
    }

    private func restoreSelection() {
        guard let data = UserDefaults.standard.data(forKey: selectionKey),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
        selection = decoded
    }
}
