import SwiftUI

enum AppTab: String, CaseIterable {
    case today = "TODAY"
    case progress = "PROGRESS"
    case plan = "PLAN"
}

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var selectedTab: AppTab = .today

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            ScrollView {
                tabContent
                    .padding(16)
            }
            TabBarView(selection: $selectedTab)
        }
        .background(Theme.paper.ignoresSafeArea())
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .today:
            TodayView()
        case .progress:
            ProgressTabView()
        case .plan:
            PlanView()
        }
    }
}

// MARK: - Header

struct HeaderView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("DAY \(store.dayNumber)")
                    .font(.mono(12, weight: .bold))
                Spacer()
                Text(store.headerDateString)
                    .font(.mono(12, weight: .bold))
            }
            .foregroundColor(Theme.sub)

            DisplayText("Training Log", size: 34)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.ink)
                .frame(height: 2)
        }
    }
}

// MARK: - Tab bar

struct TabBarView: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .background(Theme.card)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.ink)
                .frame(height: 2)
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isActive = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isActive ? Theme.red : Color.clear)
                    .frame(height: 3)
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .bold))
                    .fontWidth(.condensed)
                    .foregroundColor(isActive ? Theme.ink : Theme.sub)
                    .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
