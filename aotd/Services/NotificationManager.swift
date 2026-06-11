import Foundation
import UIKit
import UserNotifications

final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let dailyReminderIdentifier = "com.aotd.dailyReminder"
    private let trialReminderIdentifier = "com.aotd.trialReminder"

    private override init() {
        super.init()
        notificationCenter.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func applicationDidBecomeActive() {
        clearBadge()
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

    /// Honest-paywall promise: the trial timeline tells the user we remind them two
    /// days before their free trial converts, so this must actually fire.
    func scheduleTrialEndingReminder(trialDays: Int) {
        requestAuthorization { [weak self] granted in
            guard let self, granted else {
                AppLogger.general.warning("Trial reminder not scheduled: notifications not authorized")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Your free trial ends in 2 days"
            content.body = "Keep exploring every path and the Oracle, or cancel anytime in Settings. No surprises."
            content.sound = .default

            let reminderDays = max(1, trialDays - 2)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(reminderDays) * 86_400,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: self.trialReminderIdentifier,
                content: content,
                trigger: trigger
            )

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [self.trialReminderIdentifier])
            self.notificationCenter.add(request) { error in
                if let error = error {
                    AppLogger.general.error("Failed to schedule trial reminder: \(error)")
                } else {
                    AppLogger.general.info("Trial ending reminder scheduled for day \(reminderDays)")
                }
            }
        }
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