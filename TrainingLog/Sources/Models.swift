import Foundation

// MARK: - Persisted data

struct DayEntry: Codable {
    var done: [String: Bool]
    var workout: String?
    /// Indices of exercises where the top of the rep range was hit today.
    var hits: [Int]

    init(done: [String: Bool] = [:], workout: String? = nil, hits: [Int] = []) {
        self.done = done
        self.workout = workout
        self.hits = hits
    }

    private enum CodingKeys: String, CodingKey {
        case done
        case workout
        case hits
    }

    /// Tolerant decoding so JSON written by v1.0 ({"done":{},"workout":null}) still loads.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        done = try container.decodeIfPresent([String: Bool].self, forKey: .done) ?? [:]
        workout = try container.decodeIfPresent(String.self, forKey: .workout)
        hits = try container.decodeIfPresent([Int].self, forKey: .hits) ?? []
    }
}

struct AppData: Codable {
    var weights: [String: Double]
    var days: [String: DayEntry]
    /// Waist measurements in inches keyed by "yyyy-MM-dd".
    var waist: [String: Double]
    /// "A"/"B" -> exercise indices that hit the top of the range in the most recent session.
    var progression: [String: [Int]]
    /// "A"/"B" -> date key of the session that produced `progression`.
    var progressionDate: [String: String]

    init() {
        self.weights = [:]
        self.days = [:]
        self.waist = [:]
        self.progression = [:]
        self.progressionDate = [:]
    }

    private enum CodingKeys: String, CodingKey {
        case weights
        case days
        case waist
        case progression
        case progressionDate
    }

    /// Tolerant decoding so JSON written by v1.0 ({"weights":{},"days":{}}) still loads.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        weights = try container.decodeIfPresent([String: Double].self, forKey: .weights) ?? [:]
        days = try container.decodeIfPresent([String: DayEntry].self, forKey: .days) ?? [:]
        waist = try container.decodeIfPresent([String: Double].self, forKey: .waist) ?? [:]
        progression = try container.decodeIfPresent([String: [Int]].self, forKey: .progression) ?? [:]
        progressionDate = try container.decodeIfPresent([String: String].self, forKey: .progressionDate) ?? [:]
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

struct MealRow: Identifiable {
    let meal: String
    let example: String
    var id: String { meal }
}

// MARK: - Static plan content

enum PlanContent {

    /// Indexed by weekday, Sunday = 0. Strength subtitles are overridden at runtime
    /// by `Store.suggestedWorkout(for:)` so the A/B alternation is honored.
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

    private static let balanceItem = ChecklistItem(id: "balance", label: "Balance holds 3 \u{d7} 20 sec/side")

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
                ChecklistItem(id: "mobility", label: "10-min mobility routine"),
                balanceItem
            ] + commonItems
        case .functional:
            return [
                ChecklistItem(id: "longwalk", label: "Long walk 45\u{2013}60 min"),
                ChecklistItem(id: "carries", label: "Carries + balance work"),
                balanceItem
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

    static func exercises(for workout: String) -> [String] {
        workout == "B" ? workoutB : workoutA
    }

    // MARK: Warm-up, mobility, functional

    static let warmUp: [String] = [
        "March in place \u{2014} 1 min",
        "Ankle circles \u{2014} 10 each way per foot",
        "Leg swings \u{2014} 10 per leg, hold a counter",
        "Cat-cows \u{2014} 8",
        "Easy sit-to-stands \u{2014} 5"
    ]

    static let mobility: [String] = [
        "Wall calf stretch \u{2014} 2 \u{d7} 30 sec/side",
        "Ankle rocks \u{2014} 10/side",
        "Standing quad stretch \u{2014} 30 sec/side",
        "Hamstring stretch \u{2014} 30 sec/side",
        "Figure-4 glute stretch \u{2014} 30 sec/side",
        "Hip flexor stretch \u{2014} 30 sec/side",
        "Cat-cow \u{d7} 8, then child's pose 30 sec"
    ]

    static let balance = "Single-leg stand by a counter \u{2014} 3 \u{d7} 20 sec/side. When easy, eyes closed."

    static let functionalBlock: [String] = [
        "Floor get-ups \u{2014} 5 reps, any style",
        "Backpack farmer carries \u{2014} 3 \u{d7} 45 sec",
        "Balance holds \u{2014} 3 \u{d7} 20 sec/side",
        "From week 4\u{2013}6, if joints feel good: low step-ups (6\u{2013}8\" step, hold rail) \u{2014} 2 \u{d7} 8/side"
    ]

    static let cardioRules: [String] = [
        "Steps are the base: 6,000/day in weeks 1\u{2013}2, add ~1,000 every week or two until 10,000.",
        "Brisk = you can talk but couldn't sing.",
        "Progress pace and hills before impact. No running or jumping for now.",
        "If knees or ankles flare, split walks into 2\u{2013}3 shorter ones."
    ]

    // MARK: Diet

    static let dietPlate = "Every meal: half vegetables, quarter protein, quarter starch."

    static let sampleDay: [MealRow] = [
        MealRow(meal: "Breakfast", example: "3 eggs + a cup of Greek yogurt with berries"),
        MealRow(meal: "Lunch", example: "Big grilled chicken breast, cup of rice, large salad"),
        MealRow(meal: "Snack", example: "Cottage cheese or a protein shake + a piece of fruit"),
        MealRow(meal: "Dinner", example: "Lean beef, fish, or turkey + potatoes + lots of vegetables")
    ]

    static let nonNegotiables: [String] = [
        "Track everything in an app for at least the first month \u{2014} everyone underestimates by 30\u{2013}40% when eyeballing.",
        "Liquid calories are gone: soda, juice, sweet coffee drinks. Water, black coffee, tea, zero-sugar drinks are fine.",
        "Alcohol: ideally none during the cut; if you do, cap it at 2 drinks a week and log them.",
        "Restaurants: protein + vegetables, sauce on the side, skip the bread basket."
    ]

    static let trackingRules: [String] = [
        "Weigh daily, same time each morning, but only trust the 7-day average.",
        "If the weekly average stalls for 2+ weeks: drop ~100 cal/day OR add 1,000 steps. Not both.",
        "Every 15 lb lost, expect to make one of those adjustments."
    ]

    // MARK: Targets, schedule, rules

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

    static let progressionHint = "Tap the circle when you hit the top of the range. Next session, \u{2191} HARDER means: lower the incline, slow the tempo, or go single-leg."

    static let plateauMessage = "Your weekly average has moved less than 1 lb in two weeks. Make ONE adjustment: drop ~100 cal/day, or add 1,000 steps. Not both."

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
