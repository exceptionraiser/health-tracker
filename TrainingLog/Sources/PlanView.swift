import SwiftUI

struct PlanView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var reminders: ReminderManager
    @State private var showResetConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                targetsSection
                workoutSection(title: "Workout A", exercises: PlanContent.workoutA)
                workoutSection(title: "Workout B", exercises: PlanContent.workoutB)
                scheduleSection
                warmUpSection
                mobilitySection
                cardioSection
                functionalSection
            }
            Group {
                dietSection
                trackingSection
                jointRulesSection
                progressionSection
                reminderSection
                exportSection
                resetSection
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    private var targetsSection: some View {
        PlanSection(title: "Daily targets") {
            BulletList(items: PlanContent.dailyTargets)
        }
    }

    private func workoutSection(title: String, exercises: [String]) -> some View {
        PlanSection(title: title) {
            NumberedList(items: exercises)
        }
    }

    private var scheduleSection: some View {
        PlanSection(title: "Weekly schedule") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(PlanContent.weeklyRows) { row in
                    HStack(alignment: .top, spacing: 10) {
                        Text(row.day)
                            .font(.mono(13, weight: .bold))
                            .foregroundColor(Theme.red)
                            .frame(width: 44, alignment: .leading)
                        Text(row.plan)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.ink)
                    }
                }
                Text(PlanContent.weeklyNote)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(Theme.sub)
                    .padding(.top, 4)
            }
        }
    }

    private var warmUpSection: some View {
        PlanSection(title: "Warm-up (every strength session)") {
            NumberedList(items: PlanContent.warmUp)
        }
    }

    private var mobilitySection: some View {
        PlanSection(title: "Mobility routine (10 min)") {
            VStack(alignment: .leading, spacing: 10) {
                NumberedList(items: PlanContent.mobility)
                Text(PlanContent.balance)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.ink)
            }
        }
    }

    private var cardioSection: some View {
        PlanSection(title: "Cardio rules") {
            BulletList(items: PlanContent.cardioRules)
        }
    }

    private var functionalSection: some View {
        PlanSection(title: "Saturday functional block") {
            NumberedList(items: PlanContent.functionalBlock)
        }
    }

    private var dietSection: some View {
        PlanSection(title: "Diet") {
            VStack(alignment: .leading, spacing: 10) {
                Text(PlanContent.dietPlate)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.ink)
                SubheadText("Sample day")
                MealList(items: PlanContent.sampleDay)
                SubheadText("Non-negotiables")
                BulletList(items: PlanContent.nonNegotiables)
            }
        }
    }

    private var trackingSection: some View {
        PlanSection(title: "Tracking & adjustments") {
            BulletList(items: PlanContent.trackingRules)
        }
    }

    private var jointRulesSection: some View {
        PlanSection(title: "Joint rules") {
            BulletList(items: PlanContent.jointRules)
        }
    }

    private var progressionSection: some View {
        PlanSection(title: "Progression rule") {
            Text(PlanContent.progressionRule)
                .font(.system(size: 14))
                .foregroundColor(Theme.ink)
        }
    }

    // MARK: - Reminder

    private var reminderSection: some View {
        PlanSection(title: "Reminder") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $reminders.enabled) {
                    Text("Daily weigh-in reminder")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.ink)
                }
                .tint(Theme.ink)
                if reminders.enabled {
                    DatePicker(
                        "Time",
                        selection: $reminders.time,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 14))
                    .foregroundColor(Theme.ink)
                    .tint(Theme.ink)
                }
            }
            .onChange(of: reminders.enabled) { _ in
                reminders.apply()
            }
            .onChange(of: reminders.time) { _ in
                reminders.apply()
            }
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        PlanSection(title: "Export") {
            VStack(alignment: .leading, spacing: 10) {
                if let url = store.exportCSV() {
                    ShareLink(item: url) {
                        OutlinedLabel(text: "Export weights (CSV)")
                    }
                    .buttonStyle(.plain)
                }
                if let url = store.exportJSON() {
                    ShareLink(item: url) {
                        OutlinedLabel(text: "Full backup (JSON)")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Reset

    @ViewBuilder
    private var resetSection: some View {
        if showResetConfirm {
            resetConfirm
        } else {
            Button {
                showResetConfirm = true
            } label: {
                Text("Reset all data")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.sub)
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private var resetConfirm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This erases every weigh-in and every checklist. No undo.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.ink)
            Button {
                store.resetAll()
                showResetConfirm = false
            } label: {
                Text("Yes, erase everything")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.red)
            }
            .buttonStyle(.plain)
            Button {
                showResetConfirm = false
            } label: {
                Text("Keep my data")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .padding(.top, 8)
    }
}

// MARK: - Building blocks

private struct PlanSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                DisplayText(title, size: 20)
                Rectangle()
                    .fill(Theme.ink)
                    .frame(height: 2)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small red mono subheading inside a section.
private struct SubheadText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.mono(11, weight: .bold))
            .foregroundColor(Theme.red)
            .padding(.top, 2)
    }
}

/// Full-width outlined button label, matching the app's secondary buttons.
private struct OutlinedLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
            .contentShape(Rectangle())
    }
}

private struct BulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Text("\u{2022}")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.red)
                    Text(items[index])
                        .font(.system(size: 14))
                        .foregroundColor(Theme.ink)
                }
            }
        }
    }
}

private struct NumberedList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.mono(13, weight: .bold))
                        .foregroundColor(Theme.red)
                        .frame(width: 22, alignment: .trailing)
                    Text(items[index])
                        .font(.system(size: 14))
                        .foregroundColor(Theme.ink)
                }
            }
        }
    }
}

private struct MealList: View {
    let items: [MealRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items) { row in
                HStack(alignment: .top, spacing: 8) {
                    Text(row.meal.uppercased())
                        .font(.mono(12, weight: .bold))
                        .foregroundColor(Theme.red)
                        .frame(width: 84, alignment: .leading)
                    Text("\u{2014} \(row.example)")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.ink)
                }
            }
        }
    }
}
