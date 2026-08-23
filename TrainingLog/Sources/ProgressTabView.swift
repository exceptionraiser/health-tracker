import SwiftUI
import Charts

struct ProgressTabView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 16) {
            StatRow()
            ChartCard()
            MilestonesCard()
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

    private var yDomain: ClosedRange<Double> {
        let points = store.chartPoints
        var values: [Double] = []
        for p in points {
            values.append(p.weight)
            values.append(p.average)
        }
        guard let lo = values.min(), let hi = values.max() else {
            return 190...240
        }
        return (lo - 3)...(hi + 3)
    }

    private var weightChart: some View {
        Chart {
            ForEach(store.chartPoints) { point in
                PointMark(
                    x: .value("Date", point.label),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Theme.sub.opacity(0.55))
                .symbolSize(30)

                LineMark(
                    x: .value("Date", point.label),
                    y: .value("Average", point.average)
                )
                .foregroundStyle(Theme.ink)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.monotone)
            }
            RuleMark(y: .value("Goal", Store.goalWeight))
                .foregroundStyle(Theme.red)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("199")
                        .font(.mono(10, weight: .bold))
                        .foregroundColor(Theme.red)
                }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis(.hidden)
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
