import SwiftUI

struct AISavedSchedulesSelectorRow: View {
    let months: [AIListMonthKey]
    @Binding var selectedMonthID: String
    let weeks: [AIListWeekItem]
    @Binding var selectedWeekStart: Date?
    let monthLabelText: String
    let weekLabelDisplay: String
    let weekLabelText: (AIListWeekItem) -> String
    let onSelectMonth: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(months) { month in
                    Button("\(String(format: "%d", month.year))년 \(month.month)월") {
                        onSelectMonth(month.id)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "calendar")
                    Text(monthLabelText)
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Menu {
                ForEach(weeks) { week in
                    Button(weekLabelText(week)) {
                        selectedWeekStart = week.start
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "list.bullet")
                    Text(weekLabelDisplay)
                }
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedMonthID: String = "2026-2"
        @State private var selectedWeekStart: Date? = Calendar.current.startOfDay(for: Date())

        private var months: [AIListMonthKey] {
            [
                AIListMonthKey(year: 2026, month: 2),
                AIListMonthKey(year: 2026, month: 1)
            ]
        }

        private var weeks: [AIListWeekItem] {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date())
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            return [AIListWeekItem(start: start, end: end, count: 3)]
        }

        var body: some View {
            AISavedSchedulesSelectorRow(
                months: months,
                selectedMonthID: $selectedMonthID,
                weeks: weeks,
                selectedWeekStart: $selectedWeekStart,
                monthLabelText: "2026년 2월",
                weekLabelDisplay: "2/1 ~ 2/7 3건",
                weekLabelText: { week in
                    return "\(week.start.monthDayText) ~ \(week.end.monthDayText) \(week.count)건"
                },
                onSelectMonth: { monthID in
                    selectedMonthID = monthID
                    selectedWeekStart = weeks.first?.start
                }
            )
            .padding()
        }
    }

    return PreviewWrapper()
}
