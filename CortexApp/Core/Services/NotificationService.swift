import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAndSchedule() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])
            if granted { schedulePredictableReminders() }
            return granted
        } catch {
            return false
        }
    }

    func schedulePredictableReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["cortex.morning", "cortex.evening"])

        schedule(
            identifier: "cortex.morning",
            hour: 8,
            title: "Direção antes da distração",
            body: "Escolha uma ação concreta para sua missão de hoje."
        )
        schedule(
            identifier: "cortex.evening",
            hour: 20,
            title: "Feche o ciclo do dia",
            body: "Registre seu check-in sem julgamento e ajuste o próximo passo."
        )
    }

    private func schedule(identifier: String, hour: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour), repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
