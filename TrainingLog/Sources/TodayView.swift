import SwiftUI
import UIKit

struct TodayView: View {
    @EnvironmentObject var store: Store

    private var schedule: ScheduleItem {
        store.schedule(for: store.todayDate)
    }

    var body: some View {
        VStack(spacing: 16) {
            AssignmentCard(schedule: schedule)
            WeighInCard()
            SheetCard(schedule: schedule)
        }
    }
}

// MARK: - Haptics

private func lightTap() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}

// MARK: - Assignment card

private struct AssignmentCard: View {
    @EnvironmentObject var store: Store
    let schedule: ScheduleItem

    private var selectedWorkout: String? {
        store.data.days[store.todayKey]?.workout
    }

    private var suggestedWorkout: String {
        store.suggestedWorkout(for: store.todayDate) ?? "A"
    }

    /// Explicit selection wins; otherwise the alternation's suggestion.
    private var activeWorkout: String {
        selectedWorkout ?? suggestedWorkout
    }

    private var subtitle: String {
        if schedule.type == .strength {
            return "Suggested: Workout \(suggestedWorkout)"
        }
        return schedule.subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S ASSIGNMENT")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            DisplayText(schedule.title, size: 24)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(Theme.sub)
            extras
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private var extras: some View {
        switch schedule.type {
        case .strength:
            CollapsibleList(
                title: "WARM-UP (5 MIN)",
                items: PlanContent.warmUp,
                footnote: nil,
                initiallyExpanded: false
            )
            workoutPicker
            ExerciseList(workout: activeWorkout)
        case .cardio:
            CollapsibleList(
                title: "MOBILITY (10 MIN)",
                items: PlanContent.mobility,
                footnote: PlanContent.balance,
                initiallyExpanded: false
            )
        case .functional:
            CollapsibleList(
                title: "FUNCTIONAL BLOCK",
                items: PlanContent.functionalBlock,
                footnote: nil,
                initiallyExpanded: true
            )
        case .rest:
            EmptyView()
        }
    }

    private var workoutPicker: some View {
        HStack(spacing: 8) {
            workoutButton("A")
            workoutButton("B")
        }
        .padding(.top, 4)
    }

    private func workoutButton(_ id: String) -> some View {
        let isSelected = activeWorkout == id
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

// MARK: - Collapsible numbered list

private struct CollapsibleList: View {
    let title: String
    let items: [String]
    let footnote: String?
    @State private var expanded: Bool

    init(title: String, items: [String], footnote: String?, initiallyExpanded: Bool) {
        self.title = title
        self.items = items
        self.footnote = footnote
        _expanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            toggleButton
            if expanded {
                rows
                if let note = footnote {
                    Text(note)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(Theme.sub)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.top, 4)
    }

    private var toggleButton: some View {
        Button {
            expanded.toggle()
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.mono(11, weight: .bold))
                    .foregroundColor(Theme.ink)
                Image(systemName: expanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.sub)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.mono(12, weight: .bold))
                        .foregroundColor(Theme.sub)
                    Text(items[index])
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ink)
                }
            }
        }
    }
}

// MARK: - Exercise list with progression toggles

private struct ExerciseList: View {
    @EnvironmentObject var store: Store
    let workout: String

    private var exercises: [String] {
        PlanContent.exercises(for: workout)
    }

    private var hits: [Int] {
        store.data.days[store.todayKey]?.hits ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            exerciseRows
            Text(PlanContent.progressionHint)
                .font(.system(size: 12))
                .italic()
                .foregroundColor(Theme.sub)
                .padding(.top, 4)
        }
        .padding(.top, 6)
    }

    private var exerciseRows: some View {
        let items = exercises
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                ExerciseRow(
                    number: index + 1,
                    text: items[index],
                    hit: hits.contains(index),
                    harder: store.showsHarderTag(workout: workout, index: index)
                ) {
                    lightTap()
                    store.toggleHit(index, workout: workout, for: store.todayKey)
                }
            }
        }
    }
}

private struct ExerciseRow: View {
    let number: Int
    let text: String
    let hit: Bool
    let harder: Bool
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.mono(13, weight: .bold))
                .foregroundColor(Theme.red)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.ink)
            Spacer(minLength: 6)
            if harder {
                Text("\u{2191} HARDER")
                    .font(.mono(10, weight: .bold))
                    .foregroundColor(Theme.red)
                    .padding(.top, 2)
            }
            hitToggle
        }
    }

    private var hitToggle: some View {
        Button(action: action) {
            ZStack {
                if hit {
                    Circle()
                        .fill(Theme.green)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .stroke(Theme.ink, lineWidth: 1.5)
                }
            }
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weigh-in card

private struct WeighInCard: View {
    @EnvironmentObject var store: Store
    @State private var weightText: String = ""
    @State private var selectedOffset: Int = 0
    @State private var errorText: String? = nil
    @FocusState private var weightFocused: Bool

    private static let maxBackfillDays = 30

    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedOffset, to: store.todayDate) ?? store.todayDate
    }

    private var selectedKey: String {
        store.key(for: selectedDate)
    }

    private var selectedWeight: Double? {
        store.data.weights[selectedKey]
    }

    private var dayLabel: String {
        switch selectedOffset {
        case 0:
            return "TODAY"
        case -1:
            return "YESTERDAY"
        default:
            return store.listLabel(for: selectedKey)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MORNING WEIGH-IN")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            dateRow
            if let weight = selectedWeight {
                loggedRow(weight)
            } else {
                inputRow
                if let error = errorText {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.red)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .onChange(of: weightText) { _ in
            errorText = nil
        }
    }

    private var dateRow: some View {
        HStack(spacing: 10) {
            arrowButton("\u{2039}", enabled: selectedOffset > -WeighInCard.maxBackfillDays) {
                selectedOffset = max(-WeighInCard.maxBackfillDays, selectedOffset - 1)
                errorText = nil
            }
            Text(dayLabel)
                .font(.mono(12, weight: .bold))
                .foregroundColor(Theme.ink)
                .frame(minWidth: 110)
            arrowButton("\u{203A}", enabled: selectedOffset < 0) {
                selectedOffset = min(0, selectedOffset + 1)
                errorText = nil
            }
            Spacer()
        }
    }

    private func arrowButton(_ glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(enabled ? Theme.ink : Theme.line)
                .frame(width: 32, height: 28)
                .overlay(Rectangle().stroke(enabled ? Theme.ink : Theme.line, lineWidth: 1.5))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
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
                beginEdit(weight)
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
                .focused($weightFocused)
                .font(.mono(16))
                .foregroundColor(Theme.ink)
                .padding(10)
                .background(Theme.paper)
                .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            weightFocused = false
                        }
                    }
                }
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

    private func beginEdit(_ weight: Double) {
        weightText = String(format: "%.1f", weight)
        errorText = nil
        store.removeWeight(for: selectedKey)
        weightFocused = true
    }

    private func logWeight() {
        let cleaned = weightText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value >= 80, value <= 500 else {
            errorText = "Enter a weight between 80 and 500 lb."
            return
        }
        store.logWeight(value, for: selectedKey)
        weightText = ""
        errorText = nil
        weightFocused = false
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
                    lightTap()
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
