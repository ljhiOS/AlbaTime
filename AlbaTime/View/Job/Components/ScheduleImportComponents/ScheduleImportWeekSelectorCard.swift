import SwiftUI

// ScheduleImportView에서 사용하는 주차 선택 전용 카드 UI.
// 년/월/주 선택 이벤트는 클로저로 전달받아 상위 뷰 상태를 변경한다.
struct ScheduleImportWeekSelectorCard: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var selectedWeekStart: Date?

    let yearCandidates: [Int]
    let monthCandidates: [Int]
    let monthWeeks: [Date]
    let onSelectYear: (Int) -> Void
    let onSelectMonth: (Int) -> Void
    let weekLabel: (Date) -> String
    let onTapManualInput: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.theme.primary)
                Text("저장 기준 주차 (월~일)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(spacing: 8) {
                Menu {
                    ForEach(yearCandidates, id: \.self) { year in
                        Button("\(String(format: "%d", year))년") {
                            onSelectYear(year)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("\(String(format: "%d", selectedYear))년")
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack(spacing: 8) {
                Menu {
                    ForEach(monthCandidates, id: \.self) { month in
                        Button("\(month)월") {
                            onSelectMonth(month)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        Text("\(selectedMonth)월")
                    }
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Menu {
                    ForEach(monthWeeks, id: \.self) { week in
                        Button(weekLabel(week)) {
                            selectedWeekStart = week
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text(selectedWeekStart.map(weekLabel) ?? "주 선택")
                    }
                    .font(.caption)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            Button("수기로 추가") {
                onTapManualInput()
            }
            .font(.subheadline).bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .background(Color.theme.primary.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.primary.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("주차 선택 카드") {
    struct PreviewWrapper: View {
        @State private var selectedYear: Int = 2026
        @State private var selectedMonth: Int = 2
        @State private var selectedWeekStart: Date? = {
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            let weekday = calendar.component(.weekday, from: startOfDay)
            let offset = (weekday + 5) % 7
            return calendar.date(byAdding: .day, value: -offset, to: startOfDay)
        }()

        private var monthWeeks: [Date] {
            let calendar = Calendar.current
            var comps = DateComponents()
            comps.year = selectedYear
            comps.month = selectedMonth
            comps.day = 1
            guard let monthStart = calendar.date(from: comps),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStart)
            else { return [] }

            var weeks: [Date] = []
            var cursor = startOfWeekMonday(for: monthInterval.start)
            while cursor < monthInterval.end {
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: cursor) ?? cursor
                if weekEnd >= monthInterval.start {
                    weeks.append(cursor)
                }
                cursor = calendar.date(byAdding: .day, value: 7, to: cursor) ?? cursor
            }
            return weeks
        }

        var body: some View {
            ScheduleImportWeekSelectorCard(
                selectedYear: $selectedYear,
                selectedMonth: $selectedMonth,
                selectedWeekStart: $selectedWeekStart,
                yearCandidates: Array(2020...2030),
                monthCandidates: Array(1...12),
                monthWeeks: monthWeeks,
                onSelectYear: { selectedYear = $0 },
                onSelectMonth: { selectedMonth = $0 },
                weekLabel: { weekStart in
                    let calendar = Calendar.current
                    let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                    return "\(weekStart.monthDayText) ~ \(end.monthDayText)"
                },
                onTapManualInput: {
                    print("수기로 추가 tapped")
                }
            )
            .padding()
        }

        private func startOfWeekMonday(for date: Date) -> Date {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let weekday = calendar.component(.weekday, from: startOfDay)
            let offset = (weekday + 5) % 7
            return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
        }
    }

    return PreviewWrapper()
}

