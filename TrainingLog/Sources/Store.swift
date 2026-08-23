import Foundation
import Combine

final class Store: ObservableObject {

    static let storageKey = "fatloss-log-v1"
    static let startWeight: Double = 235
    static let goalWeight: Double = 199
    static let startDateString = "2026-08-22"

    @Published private(set) var data: AppData

    private let keyFormatter: DateFormatter
    private let headerFormatter: DateFormatter
    private let shortFormatter: DateFormatter
    private let listFormatter: DateFormatter

    init() {
        func makeFormatter(_ format: String) -> DateFormatter {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.calendar = Calendar.current
            f.timeZone = TimeZone.current
            f.dateFormat = format
            return f
        }
        keyFormatter = makeFormatter("yyyy-MM-dd")
        headerFormatter = makeFormatter("EEE, MMM d")
        shortFormatter = makeFormatter("M/d")
        listFormatter = makeFormatter("EEE MMM d")

        if let raw = UserDefaults.standard.data(forKey: Store.storageKey),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }
    }

    // MARK: - Date helpers

    func key(for date: Date) -> String {
        keyFormatter.string(from: date)
    }

    var todayKey: String {
        key(for: Date())
    }

    var headerDateString: String {
        headerFormatter.string(from: Date()).uppercased()
    }

    func shortLabel(for key: String) -> String {
        guard let date = keyFormatter.date(from: key) else { return key }
        return shortFormatter.string(from: date)
    }

    func listLabel(for key: String) -> String {
        guard let date = keyFormatter.date(from: key) else { return key }
        return listFormatter.string(from: date).uppercased()
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

    func toggleTask(_ id: String, for key: String) {
        var entry = data.days[key] ?? DayEntry()
        entry.done[id] = !(entry.done[id] ?? false)
        data.days[key] = entry
        save()
    }

    func setWorkout(_ workout: String, for key: String) {
        var entry = data.days[key] ?? DayEntry()
        entry.workout = workout
        data.days[key] = entry
        save()
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

    var dayNumber: Int {
        guard let start = keyFormatter.date(from: Store.startDateString) else { return 1 }
        let cal = Calendar.current
        let comps = cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: Date()))
        let days = comps.day ?? 0
        return max(1, days + 1)
    }

    // MARK: - Chart series

    struct ChartPoint: Identifiable {
        let id: String
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
            let windowStart = max(0, index - 6)
            let window = entries[windowStart...index]
            let total = window.reduce(0.0) { $0 + $1.weight }
            let avg = total / Double(window.count)
            let entry = entries[index]
            points.append(ChartPoint(
                id: entry.key,
                label: shortLabel(for: entry.key),
                weight: entry.weight,
                average: avg
            ))
        }
        return points
    }
}
