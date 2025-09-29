import Foundation
import UserNotifications

final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let dailyReminderIdentifier = "com.aotd.dailyReminder"

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        AppLogger.general.error("Failed to request notification authorization: \(error)")
                    }
                    completion(granted)
                }
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }

    func scheduleDailyReminder(at date: Date) {
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "Time to Learn"
        content.body = "Continue your journey through the afterlife. Come explore today's lesson!"
        content.sound = .default
        content.badge = 1

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                AppLogger.general.error("Failed to schedule daily reminder: \(error)")
            } else {
                AppLogger.general.info("Daily reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
            }
        }
    }

    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        AppLogger.general.info("Daily reminder cancelled")
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        clearBadge()

        if response.notification.request.identifier == dailyReminderIdentifier {
            NotificationCenter.default.post(name: .didTapDailyReminder, object: nil)
        }

        completionHandler()
    }
}

extension Notification.Name {
    static let didTapDailyReminder = Notification.Name("didTapDailyReminder")
}