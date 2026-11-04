import Foundation

/// One question a day from the whole bank, the same for everyone on the same calendar day, spread so that
/// neighbouring days rarely draw from the same tradition.
public enum DailyOmenSchedule {

    /// The day's number in the person's calendar, counted from 2026-01-01.
    public static func dayNumber(for date: Date, calendar: Calendar) -> Int {
        let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date(timeIntervalSince1970: 0)
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: epoch), to: calendar.startOfDay(for: date)).day ?? 0
    }

    /// A stable key for the day, such as `2026-11-04`.
    public static func dayKey(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// The index of the day's question among `count` candidates: a large odd stride walks the whole bank before
    /// repeating, so a question comes back only after every other one has had its day.
    public static func index(forDay day: Int, count: Int) -> Int? {
        guard count > 0 else { return nil }
        let stride = 7919 % count == 0 ? 1 : 7919
        let value = (day * stride) % count
        return value < 0 ? value + count : value
    }
}
