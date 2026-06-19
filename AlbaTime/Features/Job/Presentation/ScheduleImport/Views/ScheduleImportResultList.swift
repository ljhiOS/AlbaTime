//
//  ScheduleImportResultList.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct ScheduleImportResultList: View {
    @ObservedObject var sivm: ScheduleImportViewModel
    
    // 키보드가 올라왔을 때 리스트 스크롤을 제어하기 위한 포커스 상태
    @FocusState private var focusedField: String?
    
    var body: some View {
        List {
            // 1. 이미지 미리보기 섹션
            if let image = sivm.selectedImage {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.theme.field)
                }
            }
            
            // 2. 스케줄 리스트 섹션 (인라인 편집)
            Section {
                if sivm.session.scheduleImportDraft.schedules.isEmpty {
                    emptyStateView
                        .listRowBackground(Color.theme.field)
                } else {
                    // 배열 Binding으로 각 행을 인라인 편집한다.
                    ForEach($sivm.session.scheduleImportDraft.schedules) { scheduleBinding in
                        InlineEditRow(schedule: scheduleBinding)
                            .focused($focusedField, equals: scheduleBinding.wrappedValue.id.uuidString)
                            .listRowBackground(Color.theme.field)
                    }
                    .onDelete(perform: deleteSchedule) // 스와이프 삭제 지원
                }
            } header: {
                VStack(alignment: .leading) {
                    
                    HStack {
                        Text("인식된 스케줄 (\(sivm.session.scheduleImportDraft.schedules.count)건)")
                        Spacer()
                        // 헤더에 [+] 버튼 배치
                        Button {
                            sivm.addNewSchedule()
                        } label: {
                            Label("추가", systemImage: "plus")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                    if !sivm.session.scheduleImportDraft.schedules.isEmpty {
                        Text("시간을 터치하여 수정하고, 왼쪽으로 밀어서 삭제하세요.")
                            .font(.footnote)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.theme.surface)
        .onTapGesture {
            // 빈 공간 터치 시 키보드 내리기
            focusedField = nil
        }
    }
    
    // MARK: - Actions
    private func deleteSchedule(at offsets: IndexSet) {
        sivm.session.scheduleImportDraft.schedules.remove(atOffsets: offsets)
    }
    
    // MARK: - Subviews
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("인식된 스케줄이 없습니다.")
                .foregroundStyle(.secondary)
            Text("오른쪽 상단의 '추가' 버튼을 눌러보세요.")
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 8)
    }
}

#Preview("데이터 없음") {
    let viewModel = ScheduleImportViewModel(
        session: JobEditingSession(type: .fixed)
    )

    return ScheduleImportResultList(sivm: viewModel)
}

#Preview("데이터 있음") {
    let viewModel = ScheduleImportViewModel(
        session: JobEditingSession(type: .fixed)
    )

    let calendar = Calendar.current
    let base = calendar.startOfDay(for: Date())
    let start1 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: base) ?? base
    let end1 = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: base) ?? base
    let day2 = calendar.date(byAdding: .day, value: 1, to: base) ?? base
    let start2 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: day2) ?? day2
    let end2 = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: day2) ?? day2

    viewModel.session.scheduleImportDraft.schedules = [
        ScheduleDraftItem(
            parsedSchedule: ParsedSchedule(
                date: base,
                startTime: start1,
                endTime: end1,
                workLabel: "오픈"
            ),
            breakTime: 0,
            source: .aiImport
        ),
        ScheduleDraftItem(
            parsedSchedule: ParsedSchedule(
                date: day2,
                startTime: start2,
                endTime: end2,
                workLabel: "마감"
            ),
            breakTime: 0,
            source: .aiImport
        )
    ]

    return ScheduleImportResultList(sivm: viewModel)
}
