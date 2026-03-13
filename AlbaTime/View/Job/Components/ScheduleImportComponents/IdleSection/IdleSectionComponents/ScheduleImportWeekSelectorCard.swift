import SwiftUI

// ScheduleImportView에서 사용하는 주차 선택 전용 카드 UI.
// 년/월/주 선택 이벤트는 클로저로 전달받아 상위 뷰 상태를 변경한다.
struct ScheduleImportWeekSelectorCard: View {
    @ObservedObject var ssvm: ScheduleImportSelectionViewModel
    let onTapManualInput: () -> Void
    
    private var selectedYearBinding: Binding<Int> {
        Binding(
            get: { ssvm.selectedYear },
            set: { ssvm.selectedYear = $0 }
        )
    }
    
    private var selectedMonthBinding: Binding<Int> {
        Binding(
            get: { ssvm.selectedMonth },
            set: { ssvm.selectedMonth = $0 }
        )
    }
    
    private var selectedWeekStartBinding: Binding<Date?> {
        Binding(
            get: { ssvm.selectedWeekStart },
            set: { ssvm.selectedWeekStart = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("저장 기준 주차 (월~일)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(spacing: 8) {
                Menu {
                    ForEach(ssvm.yearCandidates, id: \.self) { year in
                        Button("\(String(format: "%d", year))년") {
                            ssvm.selectedYear = year
                            ssvm.applySelectedYearMonth()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("\(String(format: "%d", ssvm.selectedYear))년")
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack(spacing: 8) {
                Menu {
                    ForEach(ssvm.monthCandidates, id: \.self) { month in
                        Button("\(month)월") {
                            ssvm.selectedMonth = month
                            ssvm.applySelectedYearMonth()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        Text("\(ssvm.selectedMonth)월")
                    }
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Menu {
                    ForEach(ssvm.monthWeeks, id: \.self) { week in
                        Button(ssvm.weekLabel(week)) {
                            ssvm.selectedWeekStart = week
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text(ssvm.selectedWeekStart.map(ssvm.weekLabel) ?? "주 선택")
                    }
                    .font(.caption)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            Button("수기로 추가") {
                onTapManualInput()
            }
            .font(.subheadline).bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .background(Color.theme.field)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("주차 선택 카드") {
    struct PreviewWrapper: View {
        @StateObject private var ssvm = ScheduleImportSelectionViewModel()

        var body: some View {
            ScheduleImportWeekSelectorCard(
                ssvm: ssvm,
                onTapManualInput: {
                    print("수기로 추가 tapped")
                }
            )
            .padding()
            .onAppear {
                ssvm.ensureInitialSelection()
            }
        }
    }

    return PreviewWrapper()
}


