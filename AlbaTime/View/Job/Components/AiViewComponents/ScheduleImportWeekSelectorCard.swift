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
