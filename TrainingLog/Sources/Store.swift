import Foundation
import Combine

final class Store: ObservableObject {

    static let storageKey = "fatloss-log-v1"
    static let startWeight: Double = 235
    static let goalWeight: Double = 199
    static let startDateString = "2026-08-22"
    static let milestoneTargets: [Double] = [225, 215, 205, 199]

    @Published private(set) var data: AppData
    /// "yyyy-MM-dd" for the current calendar day. Refreshed on day change / foreground.
    @Published private(set) var todayKey: String

    private let keyFormatter: DateFormatter
    private let headerFormatter: DateFormatter
    private let shortFormatter: DateFormatter
    private let listFormatter: DateFormatter
    private var cancellables = Set<AnyCancellable>()

    init() {
        func makeFormatter(_ format: String) -> DateFormatter {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.calendar = Calendar.current
            f.timeZone = TimeZone.current
            f.dateFormat = format
            return f
        }
        let dayKeyFormatter = makeFormatter("yyyy-MM-dd")
        keyFormatter = dayKeyFormatter
        headerFormatter = makeFormatter("EEE, MMM d")
        shortFormatter = makeFormatter("M/d")
        listFormatter = makeFormatter("EEE MMM d")
        todayKey = dayKeyFormatter.string(from: Date())

        if let raw = UserDefaults.standard.data(forKey: Store.storageKey),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }

        NotificationCenter.default
            .publisher(for: Notification.Name.NSCalendarDayChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshToday()
            }
            .store(in: &cancellables)
    }

    // MARK: - Date helpers

    func key(for date: Date) -> String {
        keyFormatter.string(from: date)
    }

    func date(for key: String) -> Date? {
        keyFormatter.date(from: key)
    }

    /// Recomputes today's key; publishes only when the day actually changed.
    func refreshToday() {
        let fresh = keyFormatter.string(from: Date())
        if fresh != todayKey {
            todayKey = fresh
        }
    }

    /// Start of the current day as a Date (derived from `todayKey`).
    var todayDate: Date {
        keyFormatter.date(from: todayKey) ?? Calendar.current.startOfDay(for: Date())
    }

    var headerDateString: String {
        headerFormatter.string(from: todayDate).uppercased()
    }

    func shortLabel(for key: String) -> String {
        guard let date = keyFormatter.date(from: key) else { return key }
        return shortFormatter.string(from: date)
    }

    func listLabel(for key: String) -> String {
        guard let date = keyFormatter.date(from: key) else { return key }
        return listFormatter.string(from: date).uppercased()
    }

    private var startDate: Date {
        let cal = Calendar.current
        guard let start = keyFormatter.date(from: Store.startDateString) else {
            return cal.startOfDay(for: Date())
        }
        return cal.startOfDay(for: start)
    }

    private func daysSinceStart(_ date: Date) -> Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.day], from: startDate, to: cal.startOfDay(for: date))
        return comps.day ?? 0
    }

    var dayNumber: Int {
        max(1, daysSinceStart(todayDate) + 1)
    }

    // MARK: - Schedule

    func schedule(for date: Date) -> ScheduleItem {
        let weekday = Calendar.current.component(.weekday, from: date) - 1
        let index = max(0, min(6, weekday))
        return PlanContent.schedule[index]
    }

    func dayType(for date: Date) -> DayType {
        schedule(for: date).type
    }

    /// Whole weeks elapsed since the start date for the given day (never negative).
    func weekIndex(for date: Date) -> Int {
        max(0, daysSinceStart(date) / 7)
    }

    var weekIndex: Int {
        weekIndex(for: todayDate)
    }

    /// Even weeks: Mon A, Wed B, Fri A. Odd weeks: Mon B, Wed A, Fri B. Nil on non-strength days.
    func suggestedWorkout(for date: Date) -> String? {
        let weekday = Calendar.current.component(.weekday, from: date)
        let evenWeek = weekIndex(for: date) % 2 == 0
        switch weekday {
        case 2, 6: // Monday, Friday
            return evenWeek ? "A" : "B"
        case 4: // Wednesday
            return evenWeek ? "B" : "A"
        default:
            return nil
        }
    }

    // MARK: - Persistence

    private func save() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: Store.storageKey)
        }
    }

    // MARK: - Mutations

    func logWeight(_ weight: Double, for key: String) {
        data.weights[key] = weight
        save()
    }

    func removeWeight(for key: String) {
        data.weights.removeValue(forKey: key)
        save()
    }

    func logWaist(_ inches: Double, for key: String) {
        data.waist[key] = inches
        save()
    }

    func toggleTask(_ id: String, for key: String) {
        var entry = data.days[key] ?? DayEntry()
        entry.done[id] = !(entry.done[id] ?? false)
        data.days[key] = entry
        save()
    }

    func setWorkout(_ workout: String, for key: String) {
        var entry = data.days[key] ?? DayEntry()
        if entry.workout != workout {
            entry.hits = []
        }
        entry.workout = workout
        data.days[key] = entry
        save()
    }

    /// Toggles "hit top of range" for an exercise index and records it as the
    /// latest progression state for that workout.
    func toggleHit(_ index: Int, workout: String, for key: String) {
        var entry = data.days[key] ?? DayEntry()
        if entry.workout == nil {
            entry.workout = workout
        }
        if let position = entry.hits.firstIndex(of: index) {
            entry.hits.remove(at: position)
        } else {
            entry.hits.append(index)
            entry.hits.sort()
        }
        data.days[key] = entry
        data.progression[workout] = entry.hits
        data.progressionDate[workout] = key
        save()
    }

    /// True when the exercise hit the top of the range in a *previous* session of this workout.
    func showsHarderTag(workout: String, index: Int) -> Bool {
        guard let indices = data.progression[workout], indices.contains(index) else { return false }
        return data.progressionDate[workout] != todayKey
    }

    func resetAll() {
        data = AppData()
        save()
    }

    // MARK: - Derived values

    /// All weigh-ins sorted by date key ascending ("yyyy-MM-dd" sorts lexicographically).
    var sortedEntries: [(key: String, weight: Double)] {
        data.weights
            .sorted { $0.key < $1.key }
            .map { (key: $0.key, weight: $0.value) }
    }

    var latestWeight: Double? {
        sortedEntries.last?.weight
    }

    /// Mean of the last up-to-7 entries.
    var avg7: Double? {
        let entries = sortedEntries
        guard !entries.isEmpty else { return nil }
        let tail = entries.suffix(7)
        let total = tail.reduce(0.0) { $0 + $1.weight }
        return total / Double(tail.count)
    }

    private var currentEstimate: Double? {
        avg7 ?? latestWeight
    }

    var lost: Double? {
        guard let current = currentEstimate else { return nil }
        return Store.startWeight - current
    }

    var toGo: Double? {
        guard let current = currentEstimate else { return nil }
        return current - Store.goalWeight
    }

    /// Highest milestone not yet hit by the 7-day average. 225 with no data; 199 once all are hit.
    var nextTarget: Double {
        guard let avg = avg7 else { return Store.milestoneTargets[0] }
        for target in Store.milestoneTargets where avg > target {
            return target
        }
        return Store.goalWeight
    }

    // MARK: - Waist

    var sortedWaist: [(key: String, inches: Double)] {
        data.waist
            .sorted { $0.key < $1.key }
            .map { (key: $0.key, inches: $0.value) }
    }

    var latestWaist: Double? {
        sortedWaist.last?.inches
    }

    /// Latest minus first waist measurement (negative = lost inches).
    var waistChange: Double? {
        let entries = sortedWaist
        guard let first = entries.first, let last = entries.last, entries.count > 1 else { return nil }
        return last.inches - first.inches
    }

    // MARK: - Stall detection

    /// Mean weight per 7-day bin since the start date (bin i = days 7i...7i+6),
    /// including only bins with at least 3 weigh-ins, in chronological order.
    var weeklyAverages: [Double] {
        var bins: [Int: [Double]] = [:]
        for (key, weight) in data.weights {
            guard let date = keyFormatter.date(from: key) else { continue }
            let days = daysSinceStart(date)
            guard days >= 0 else { continue }
            bins[days / 7, default: []].append(weight)
        }
        guard let lastBin = bins.keys.max() else { return [] }
        var result: [Double] = []
        for bin in 0...lastBin {
            guard let weights = bins[bin], weights.count >= 3 else { continue }
            let total = weights.reduce(0.0, +)
            result.append(total / Double(weights.count))
        }
        return result
    }

    var isStalled: Bool {
        let averages = weeklyAverages
        guard averages.count >= 3 else { return false }
        let twoWeeksAgo = averages[averages.count - 3]
        let latest = averages[averages.count - 1]
        return (twoWeeksAgo - latest) < 1.0
    }

    // MARK: - Adherence

    /// True when every checklist item for that date's day type is done.
    func sheetComplete(for key: String) -> Bool {
        guard let date = keyFormatter.date(from: key) else { return false }
        let items = PlanContent.checklist(for: dayType(for: date))
        guard !items.isEmpty else { return false }
        let done = data.days[key]?.done ?? [:]
        return items.allSatisfy { done[$0.id] == true }
    }

    private func dayKey(offsetFromToday offset: Int) -> String? {
        guard let date = Calendar.current.date(byAdding: .day, value: offset, to: todayDate) else { return nil }
        return key(for: date)
    }

    /// Completed sheets in the Mon-Sun week containing today.
    var thisWeekCompleted: Int {
        let weekday = Calendar.current.component(.weekday, from: todayDate) // 1 = Sunday
        let daysFromMonday = (weekday + 5) % 7
        var count = 0
        for dayIndex in 0..<7 {
            if let key = dayKey(offsetFromToday: dayIndex - daysFromMonday), sheetComplete(for: key) {
                count += 1
            }
        }
        return count
    }

    /// Consecutive complete days ending today (or yesterday if today is not complete yet).
    var currentStreak: Int {
        var offset = 0
        if !sheetComplete(for: todayKey) {
            offset = -1
        }
        var streak = 0
        while let key = dayKey(offsetFromToday: offset), sheetComplete(for: key) {
            streak += 1
            offset -= 1
            if streak > 3650 { break }
        }
        return streak
    }

    // MARK: - Export

    func exportCSV() -> URL? {
        var lines: [String] = ["date,weight_lb"]
        for entry in sortedEntries {
            lines.append("\(entry.key),\(String(format: "%.1f", entry.weight))")
        }
        let text = lines.joined(separator: "\n") + "\n"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("traininglog-weights.csv")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    func exportJSON() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let raw = try? encoder.encode(data) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("traininglog-backup.json")
        do {
            try raw.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Chart series

    struct ChartPoint: Identifiable {
        let id: String
        let date: Date
        let label: String
        let weight: Double
        let average: Double
    }

    /// Daily weights plus a rolling 7-entry average, oldest first.
    var chartPoints: [ChartPoint] {
        let entries = sortedEntries
        var points: [ChartPoint] = []
        points.reserveCapacity(entries.count)
        for index in entries.indices {
            let entry = entries[index]
            guard let date = keyFormatter.date(from: entry.key) else { continue }
            let windowStart = max(0, index - 6)
            let window = entries[windowStart...index]
            let total = window.reduce(0.0) { $0 + $1.weight }
            let avg = total / Double(window.count)
            points.append(ChartPoint(
                id: entry.key,
                date: date,
                label: shortLabel(for: entry.key),
                weight: entry.weight,
                average: avg
            ))
        }
        return points
    }
}
