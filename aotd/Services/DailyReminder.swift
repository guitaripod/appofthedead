import Foundation

/// The daily-reminder preference and its scheduling, shared by Settings and the first-lesson
/// opt-in card so both read and write the same stored state.
struct DailyReminder {
    static let shared = DailyReminder()

    static let enabledKey = "DailyReminderEnabled"
    static let timeKey = "DailyReminderTime"
    static let defaultHour = 9

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get { defaults.bool(forKey: Self.enabledKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.enabledKey) }
    }

    var time: Date {
        get { defaults.object(forKey: Self.timeKey) as? Date ?? Self.defaultTime }
        nonmutating set { defaults.set(newValue, forKey: Self.timeKey) }
    }

    /// Asks for notification permission if it was never asked, then schedules the reminder at the
    /// stored time. Reports on the main queue whether the reminder is now active.
    func enable(completion: @escaping (Bool) -> Void) {
        NotificationManager.shared.requestAuthorization { granted in
            DispatchQueue.main.async {
                self.isEnabled = granted
                if granted {
                    NotificationManager.shared.scheduleDailyReminder(at: self.time)
                }
                completion(granted)
            }
        }
    }

    func disable() {
        isEnabled = false
        NotificationManager.shared.cancelDailyReminder()
    }

    func updateTime(_ newTime: Date) {
        time = newTime
        if isEnabled {
            NotificationManager.shared.scheduleDailyReminder(at: newTime)
        }
    }

    private static var defaultTime: Date {
        var components = DateComponents()
        components.hour = defaultHour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
