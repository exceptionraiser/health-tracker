import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: Store

    private var schedule: ScheduleItem {
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1
        let index = max(0, min(6, weekday))
        return PlanContent.schedule[index]
    }

    var body: some View {
        VStack(spacing: 16) {
            AssignmentCard(schedule: schedule)
            WeighInCard()
            SheetCard(schedule: schedule)
        }
    }
}

// MARK: - Assignment card

private struct AssignmentCard: View {
    @EnvironmentObject var store: Store
    let schedule: ScheduleItem

    private var selectedWorkout: String? {
        store.data.days[store.todayKey]?.workout
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S ASSIGNMENT")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            DisplayText(schedule.title, size: 24)
            Text(schedule.subtitle)
                .font(.system(size: 14))
                .foregroundColor(Theme.sub)
            if schedule.type == .strength {
                workoutPicker
                if let workout = selectedWorkout {
                    ExerciseList(workout: workout)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var workoutPicker: some View {
        HStack(spacing: 8) {
            workoutButton("A")
            workoutButton("B")
        }
        .padding(.top, 4)
    }

    private func workoutButton(_ id: String) -> some View {
        let isSelected = selectedWorkout == id
        return Button {
            store.setWorkout(id, for: store.todayKey)
        } label: {
            Text("WORKOUT \(id)")
                .font(.system(size: 13, weight: .bold))
                .fontWidth(.condensed)
                .foregroundColor(isSelected ? Theme.paper : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.ink : Theme.card)
                .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

private struct ExerciseList: View {
    let workout: String

    private var exercises: [String] {
        workout == "B" ? PlanContent.workoutB : PlanContent.workoutA
    }

    var body: some View {
        let items = exercises
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.mono(13, weight: .bold))
                        .foregroundColor(Theme.red)
                    Text(items[index])
                        .font(.system(size: 14))
                        .foregroundColor(Theme.ink)
                }
            }
        }
        .padding(.top, 6)
    }
}

// MARK: - Weigh-in card

private struct WeighInCard: View {
    @EnvironmentObject var store: Store
    @State private var weightText: String = ""

    private var todayWeight: Double? {
        store.data.weights[store.todayKey]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MORNING WEIGH-IN")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            if let weight = todayWeight {
                loggedRow(weight)
            } else {
                inputRow
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func loggedRow(_ weight: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(format: "%.1f", weight))
                .font(.mono(32, weight: .bold))
                .foregroundColor(Theme.ink)
            Text("lbs logged")
                .font(.system(size: 14))
                .foregroundColor(Theme.sub)
            Spacer()
            Button {
                store.removeWeight(for: store.todayKey)
            } label: {
                Text("Edit")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.red)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("e.g. 234.5", text: $weightText)
                .keyboardType(.decimalPad)
                .font(.mono(16))
                .foregroundColor(Theme.ink)
                .padding(10)
                .background(Theme.paper)
                .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
            Button(action: logWeight) {
                Text("LOG IT")
                    .font(.system(size: 14, weight: .bold))
                    .fontWidth(.condensed)
                    .foregroundColor(Theme.paper)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background(Theme.ink)
            }
            .buttonStyle(.plain)
        }
    }

    private func logWeight() {
        let cleaned = weightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value >= 80, value <= 500 else { return }
        store.logWeight(value, for: store.todayKey)
        weightText = ""
    }
}

// MARK: - The Sheet (checklist)

private struct SheetCard: View {
    @EnvironmentObject var store: Store
    let schedule: ScheduleItem

    private var items: [ChecklistItem] {
        PlanContent.checklist(for: schedule.type)
    }

    private var doneMap: [String: Bool] {
        store.data.days[store.todayKey]?.done ?? [:]
    }

    private var doneCount: Int {
        items.filter { doneMap[$0.id] == true }.count
    }

    private var isComplete: Bool {
        doneCount == items.count && !items.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            checklistRows
            if isComplete {
                completionBanner
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var header: some View {
        HStack {
            Text("THE SHEET")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            Spacer()
            Text("\(doneCount)/\(items.count)")
                .font(.mono(12, weight: .bold))
                .foregroundColor(isComplete ? Theme.green : Theme.sub)
        }
    }

    private var checklistRows: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(items) { item in
                ChecklistRow(item: item, done: doneMap[item.id] == true) {
                    store.toggleTask(item.id, for: store.todayKey)
                }
            }
        }
    }

    private var completionBanner: some View {
        Text("Sheet complete. That's how the weight comes off.")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Theme.green)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.greenSoft)
            .overlay(Rectangle().stroke(Theme.green, lineWidth: 1.5))
    }
}

private struct ChecklistRow: View {
    let item: ChecklistItem
    let done: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                checkCircle
                Text(item.label)
                    .font(.system(size: 15))
                    .strikethrough(done, color: Theme.red)
                    .foregroundColor(done ? Theme.sub : Theme.ink)
                Spacer()
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var checkCircle: some View {
        ZStack {
            if done {
                Circle()
                    .fill(Theme.green)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Circle()
                    .stroke(Theme.ink, lineWidth: 1.5)
            }
        }
        .frame(width: 26, height: 26)
    }
}
