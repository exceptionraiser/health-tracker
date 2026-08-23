import Foundation

// MARK: - Persisted data

struct DayEntry: Codable {
    var done: [String: Bool]
    var workout: String?

    init(done: [String: Bool] = [:], workout: String? = nil) {
        self.done = done
        self.workout = workout
    }
}

struct AppData: Codable {
    var weights: [String: Double]
    var days: [String: DayEntry]

    init() {
        self.weights = [:]
        self.days = [:]
    }
}

// MARK: - Day types and schedule

enum DayType: String {
    case strength
    case cardio
    case functional
    case rest
}

struct ScheduleItem {
    let type: DayType
    let title: String
    let subtitle: String
}

struct ChecklistItem: Identifiable {
    let id: String
    let label: String
}

// MARK: - Static plan content

enum PlanContent {

    /// Indexed by weekday, Sunday = 0.
    static let schedule: [ScheduleItem] = [
        ScheduleItem(type: .rest, title: "Rest day", subtitle: "Recovery counts as training"),
        ScheduleItem(type: .strength, title: "Strength + 20-min walk", subtitle: "Suggested: Workout A"),
        ScheduleItem(type: .cardio, title: "Brisk walk 35\u{2013}45 min", subtitle: "Plus 10-min mobility"),
        ScheduleItem(type: .strength, title: "Strength + 20-min walk", subtitle: "Suggested: Workout B"),
        ScheduleItem(type: .cardio, title: "Brisk walk 35\u{2013}45 min", subtitle: "Plus 10-min mobility"),
        ScheduleItem(type: .strength, title: "Strength + 20-min walk", subtitle: "Suggested: Workout A"),
        ScheduleItem(type: .functional, title: "Functional day", subtitle: "Long walk 45\u{2013}60 min + carries")
    ]

    private static let commonItems: [ChecklistItem] = [
        ChecklistItem(id: "protein", label: "Protein \u{2265} 160g"),
        ChecklistItem(id: "cals", label: "Calories \u{2264} 1,900"),
        ChecklistItem(id: "water", label: "Water ~3 liters")
    ]

    static func checklist(for type: DayType) -> [ChecklistItem] {
        switch type {
        case .strength:
            return [
                ChecklistItem(id: "workout", label: "Strength workout done"),
                ChecklistItem(id: "walk20", label: "20-minute walk")
            ] + commonItems
        case .cardio:
            return [
                ChecklistItem(id: "briskwalk", label: "Brisk walk 35\u{2013}45 min"),
                ChecklistItem(id: "mobility", label: "10-min mobility routine")
            ] + commonItems
        case .functional:
            return [
                ChecklistItem(id: "longwalk", label: "Long walk 45\u{2013}60 min"),
                ChecklistItem(id: "carries", label: "Carries + balance work")
            ] + commonItems
        case .rest:
            return [
                ChecklistItem(id: "stroll", label: "Optional easy stroll")
            ] + commonItems
        }
    }

    static let workoutA: [String] = [
        "Chair sit-to-stands \u{2014} 3 \u{d7} 8\u{2013}12",
        "Incline push-ups (counter) \u{2014} 3 \u{d7} 8\u{2013}12",
        "Glute bridges \u{2014} 3 \u{d7} 12\u{2013}15",
        "Table or towel rows \u{2014} 3 \u{d7} 8\u{2013}12",
        "Wall calf raises, slow \u{2014} 3 \u{d7} 12\u{2013}15",
        "Plank (counter or knees) \u{2014} 3 \u{d7} 20\u{2013}40 sec"
    ]

    static let workoutB: [String] = [
        "Hip hinges \u{2014} 3 \u{d7} 10\u{2013}12",
        "Incline push-ups, close grip \u{2014} 3 \u{d7} 8\u{2013}12",
        "Single-leg glute bridge \u{2014} 3 \u{d7} 8/side",
        "Bird dogs \u{2014} 3 \u{d7} 8/side",
        "Shallow wall sit (pain-free depth) \u{2014} 3 \u{d7} 15\u{2013}30 sec",
        "Wall tibialis raises \u{2014} 3 \u{d7} 12\u{2013}15",
        "Backpack suitcase carry \u{2014} 3 \u{d7} 30\u{2013}45 sec/side"
    ]

    static let dailyTargets: [String] = [
        "1,800\u{2013}2,000 calories \u{b7} protein first",
        "150\u{2013}180g protein / 30g+ fiber",
        "Zero liquid calories \u{b7} ~3L water",
        "Steps: build from 6,000 toward 10,000"
    ]

    static let weeklyRows: [WeeklyRow] = [
        WeeklyRow(day: "MON", plan: "Strength A + walk"),
        WeeklyRow(day: "TUE", plan: "Brisk walk + mobility"),
        WeeklyRow(day: "WED", plan: "Strength B + walk"),
        WeeklyRow(day: "THU", plan: "Brisk walk + mobility"),
        WeeklyRow(day: "FRI", plan: "Strength A + walk"),
        WeeklyRow(day: "SAT", plan: "Functional day"),
        WeeklyRow(day: "SUN", plan: "Rest")
    ]

    static let weeklyNote = "Next week swap so you do B twice (B\u{2013}A\u{2013}B). Keep alternating."

    static let jointRules: [String] = [
        "Discomfort \u{2264}3/10 that clears overnight: fine.",
        "Sharp pain or swelling: stop, regress, shorten walks.",
        "Muscle burn yes. Joint pain never."
    ]

    static let progressionRule = "Hit the top of every rep range with good form? Next session, make it harder: lower the incline, slow the tempo, or go single-leg. Never harder and more reps the same week."

    static let milestones: [Milestone] = [
        Milestone(value: 225, label: "First 10 gone"),
        Milestone(value: 215, label: "Down 20"),
        Milestone(value: 205, label: "Down 30"),
        Milestone(value: 199, label: "Under 200")
    ]
}

struct Milestone: Identifiable {
    let value: Double
    let label: String
    var id: Double { value }
}

struct WeeklyRow: Identifiable {
    let day: String
    let plan: String
    var id: String { day }
}
