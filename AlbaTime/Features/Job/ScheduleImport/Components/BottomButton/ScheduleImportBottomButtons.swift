//
//  ScheduleImportBottomButtons.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI
import SwiftData

struct ScheduleImportBottomButtons: View {
    @ObservedObject var sivm: ScheduleImportViewModel
    @Environment(\.modelContext) var modelContext
    let selectedWeekStart: Date?
    let onSaved: () -> Void
    let onManualInput: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 저장하기 버튼
            Button {
                if sivm.session.editingJob == nil {
                    onSaved()
                    return
                }
                
                let didSave = sivm.saveToWorkplace(
                    context: modelContext,
                    targetWeekStart: selectedWeekStart,
                    isFromAIImport: true
                )
                if didSave {
                    onSaved()
                }
            } label: {
                Text("저장하기")
                    .font(.headline).bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        sivm.session.scheduleImportDraft.parsedSchedule.isEmpty
                        ? Color.theme.disabled
                        : Color.theme.primary
                    )
                    .cornerRadius(12)
            }
            .disabled(sivm.session.scheduleImportDraft.parsedSchedule.isEmpty)
            
            // 취소 버튼
            Button {
                onManualInput()
            } label: {
                Text("취소하고 수기로 입력하기")
                    .font(.subheadline).bold()
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(Color.theme.surface)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}

#Preview("Bottom Buttons") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)

    let viewModel = ScheduleImportViewModel(
        session: JobEditingSession(type: .fixed)
    )

    viewModel.session.scheduleImportDraft.parsedSchedule = [
        ParsedSchedule(
            date: Date(),
            startTime: Date.makeTime(9, 0),
            endTime: Date.makeTime(18, 0),
            workLabel: "테스트"
        )
    ]

    return VStack {
        Spacer()

        ScheduleImportBottomButtons(
            sivm: viewModel,
            selectedWeekStart: nil,
            onSaved: {},
            onManualInput: {}
        )
    }
    .modelContainer(container)
}
