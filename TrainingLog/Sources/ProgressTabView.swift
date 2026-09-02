import SwiftUI
import Charts

struct ProgressTabView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 16) {
            StatRow()
            AdherenceCard()
            if store.isStalled {
                PlateauCard()
            }
            ChartCard()
            MilestonesCard()
            WaistCard()
            RecentEntriesCard()
        }
    }
}

// MARK: - Stat boxes

private struct StatRow: View {
    @EnvironmentObject var store: Store

    var body: some View {
        HStack(spacing: 10) {
            StatBox(title: "7-DAY AVG", value: format(store.avg7))
            StatBox(title: "LOST", value: format(store.lost, fallback: "0.0"))
            StatBox(title: "TO 199", value: format(store.toGo))
        }
    }

    private func format(_ value: Double?, fallback: String = "\u{2014}") -> String {
        guard let value = value else { return fallback }
        return String(format: "%.1f", value)
    }
}

private struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.mono(10, weight: .bold))
                .foregroundColor(Theme.sub)
            Text(value)
                .font(.mono(22, weight: .bold))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(Theme.card)
        .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
    }
}

// MARK: - Adherence

private struct AdherenceCard: View {
    @EnvironmentObject var store: Store

    private var streakText: String {
        let streak = store.currentStreak
        return streak == 1 ? "1 day" : "\(streak) days"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THIS WEEK")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            HStack(spacing: 10) {
                StatBox(title: "SHEETS DONE", value: "\(store.thisWeekCompleted)/7")
                StatBox(title: "STREAK", value: streakText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Plateau

private struct PlateauCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLATEAU CHECK")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            Text(PlanContent.plateauMessage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.ink)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(Rectangle().stroke(Theme.red, lineWidth: 2))
        .background(alignment: .center) {
            Rectangle()
                .fill(Theme.line)
                .offset(x: 3, y: 3)
        }
        .padding(.trailing, 3)
        .padding(.bottom, 3)
    }
}

// MARK: - Chart

private struct ChartCard: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THE LINE THAT MATTERS (7-DAY AVERAGE)")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            if store.sortedEntries.count < 2 {
                placeholder
            } else {
                weightChart
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var placeholder: some View {
        Text("Log two weigh-ins and your line starts here. Daily dots will bounce \u{2014} the average is the truth.")
            .font(.system(size: 14))
            .foregroundColor(Theme.sub)
            .multilineTextAlignment(.center)
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 160)
            .overlay(
                Rectangle()
                    .stroke(Theme.line, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
    }

    /// Data range padded by 2 lb, always including the next target line.
    private var yDomain: ClosedRange<Double> {
        let target = store.nextTarget
        var values: [Double] = []
        for p in store.chartPoints {
            values.append(p.weight)
            values.append(p.average)
        }
        let dataMin = values.min() ?? target
        let dataMax = values.max() ?? target
        let lo = min(dataMin, target) - 2
        let hi = max(dataMax, target) + 2
        return lo...hi
    }

    private var targetLabel: String {
        String(format: "%.0f", store.nextTarget)
    }

    private var weightChart: some View {
        Chart {
            ForEach(store.chartPoints) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Theme.sub.opacity(0.55))
                .symbolSize(30)

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Average", point.average)
                )
                .foregroundStyle(Theme.ink)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.monotone)
            }
            RuleMark(y: .value("Target", store.nextTarget))
                .foregroundStyle(Theme.red)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(targetLabel)
                        .font(.mono(10, weight: .bold))
                        .foregroundColor(Theme.red)
                }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                    .foregroundStyle(Theme.line)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: false)
                    .font(.mono(9))
                    .foregroundStyle(Theme.sub)
            }
        }
        .frame(height: 220)
    }
}

// MARK: - Milestones

private struct MilestonesCard: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MILESTONES")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(PlanContent.milestones) { milestone in
                    MilestoneChip(
                        value: milestone.value,
                        label: milestone.label,
                        hit: isHit(milestone.value)
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func isHit(_ value: Double) -> Bool {
        guard let avg = store.avg7 else { return false }
        return avg <= value
    }
}

private struct MilestoneChip: View {
    let value: Double
    let label: String
    let hit: Bool

    var body: some View {
        HStack(spacing: 6) {
            if hit {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.green)
            }
            Text(String(format: "%.0f", value))
                .font(.mono(13, weight: .bold))
                .foregroundColor(hit ? Theme.green : Theme.ink)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(hit ? Theme.green : Theme.sub)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hit ? Theme.greenSoft : Theme.card)
        .overlay(
            Rectangle().stroke(hit ? Theme.green : Theme.ink, lineWidth: 1.5)
        )
    }
}

// MARK: - Waist

private struct WaistCard: View {
    @EnvironmentObject var store: Store
    @State private var waistText: String = ""
    @State private var errorText: String? = nil
    @FocusState private var waistFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WAIST")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            summaryRow
            inputRow
            if let error = errorText {
                Text(error)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.red)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .onChange(of: waistText) { _ in
            errorText = nil
        }
    }

    @ViewBuilder
    private var summaryRow: some View {
        if let latest = store.latestWaist {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", latest))
                    .font(.mono(24, weight: .bold))
                    .foregroundColor(Theme.ink)
                Text("in")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.sub)
                Spacer()
                Text(changeText)
                    .font(.mono(12, weight: .bold))
                    .foregroundColor(changeColor)
            }
        } else {
            Text("Measure at the navel, relaxed, same time as the weigh-in.")
                .font(.system(size: 13))
                .foregroundColor(Theme.sub)
        }
    }

    private var changeText: String {
        guard let change = store.waistChange else { return "first entry" }
        if abs(change) < 0.05 {
            return "no change since start"
        }
        let sign = change < 0 ? "\u{2212}" : "+"
        return "\(sign)\(String(format: "%.1f", abs(change))) in since start"
    }

    private var changeColor: Color {
        guard let change = store.waistChange, change < -0.05 else { return Theme.sub }
        return Theme.green
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("inches, e.g. 42.5", text: $waistText)
                .keyboardType(.decimalPad)
                .focused($waistFocused)
                .font(.mono(14))
                .foregroundColor(Theme.ink)
                .padding(8)
                .background(Theme.paper)
                .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            waistFocused = false
                        }
                    }
                }
            Button(action: logWaist) {
                Text("LOG")
                    .font(.system(size: 13, weight: .bold))
                    .fontWidth(.condensed)
                    .foregroundColor(Theme.paper)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Theme.ink)
            }
            .buttonStyle(.plain)
        }
    }

    private func logWaist() {
        let cleaned = waistText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value >= 20, value <= 80 else {
            errorText = "Enter a waist between 20 and 80 in."
            return
        }
        store.logWaist(value, for: store.todayKey)
        waistText = ""
        errorText = nil
        waistFocused = false
    }
}

// MARK: - Recent entries

private struct RecentEntriesCard: View {
    @EnvironmentObject var store: Store

    private var recent: [(key: String, weight: Double)] {
        Array(store.sortedEntries.suffix(7).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT ENTRIES")
                .font(.mono(11, weight: .bold))
                .foregroundColor(Theme.red)
            if recent.isEmpty {
                Text("No weigh-ins yet.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.sub)
            } else {
                entryRows
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var entryRows: some View {
        let entries = recent
        return VStack(spacing: 0) {
            ForEach(entries.indices, id: \.self) { index in
                HStack {
                    Text(store.listLabel(for: entries[index].key))
                        .font(.mono(13))
                        .foregroundColor(Theme.sub)
                    Spacer()
                    Text(String(format: "%.1f lbs", entries[index].weight))
                        .font(.mono(13, weight: .bold))
                        .foregroundColor(Theme.ink)
                }
                .padding(.vertical, 8)
                if index < entries.count - 1 {
                    Rectangle()
                        .fill(Theme.line)
                        .frame(height: 1)
                }
            }
        }
    }
}
