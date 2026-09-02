import Foundation
import Combine
import UserNotifications

/// Owns the daily "morning weigh-in" local notification.
final class ReminderManager: ObservableObject {

    private static let enabledKey = "reminder.enabled"
    private static let hourKey = "reminder.hour"
    private static let minuteKey = "reminder.minute"
    private static let requestIdentifier = "morning-weighin"

    @Published var enabled: Bool
    @Published var time: Date

    init() {
        let defaults = UserDefaults.standard
        let storedHour = defaults.object(forKey: ReminderManager.hourKey) as? Int
        let storedMinute = defaults.object(forKey: ReminderManager.minuteKey) as? Int
        let hour = storedHour ?? 7
        let minute = storedMinute ?? 0
        enabled = defaults.bool(forKey: ReminderManager.enabledKey)
        time = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private var hourAndMinute: (hour: Int, minute: Int) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        return (hour: comps.hour ?? 7, minute: comps.minute ?? 0)
    }

    private func persist() {
        let defaults = UserDefaults.standard
        let hm = hourAndMinute
        defaults.set(enabled, forKey: ReminderManager.enabledKey)
        defaults.set(hm.hour, forKey: ReminderManager.hourKey)
        defaults.set(hm.minute, forKey: ReminderManager.minuteKey)
    }

    /// Persists the current settings and (re)schedules or cancels the notification.
    func apply() {
        persist()
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [ReminderManager.requestIdentifier])
        guard enabled else { return }

        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if granted {
                    self.schedule(on: center)
                } else if self.enabled {
                    self.enabled = false
                    self.persist()
                }
            }
        }
    }

    private func schedule(on center: UNUserNotificationCenter) {
        let hm = hourAndMinute
        var comps = DateComponents()
        comps.hour = hm.hour
        comps.minute = hm.minute

        let content = UNMutableNotificationContent()
        content.title = "Morning weigh-in"
        content.body = "Step on the scale before coffee, then log it."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: ReminderManager.requestIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request, withCompletionHandler: nil)
    }
}
