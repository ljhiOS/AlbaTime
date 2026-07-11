//
//  ScheduleImportPresetGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 2/27/26.
//

import SwiftUI

struct ScheduleImportPresetGroup: View {
    @ObservedObject var sivm: ScheduleImportViewModel
    let preset: [TimePresetDraft]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text("근무 시간 타입 (선택)")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textPrimary)
                    .bold()
                Text("오픈, 마감 등 설정하면 AI가 시간 대신 인식할 수 있어요")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            ForEach(preset) { preset in
                PresetRow(preset: preset) {
                    sivm.deletePreset(preset)
                }
            }
            
            if sivm.isAddingPreset {
                VStack(spacing: 10) {
                    TextField("타입 이름 (예: 오픈)", text: $sivm.newPresetLabel)
                        .padding(10)
                        .background(Color.theme.field)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.theme.border, lineWidth: 1)
                        )
                    
                    HStack {
                        DatePicker("", selection: $sivm.newPresetStart, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Text("~")
                        DatePicker("", selection: $sivm.newPresetEnd, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Button("취소") {
                            withAnimation { sivm.isAddingPreset = false }
                        }
                        .foregroundStyle(.red)
                        .font(.caption)
                        
                        Spacer()
                        
                        Button("추가") { sivm.addNewPreset() }
                            .bold()
                            .foregroundStyle(Color.theme.primary)
                            .disabled(sivm.newPresetLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(10)
                .background(Color.theme.surface)
                .cornerRadius(8)
            } else {
                Button {
                    withAnimation { sivm.isAddingPreset = true }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("새로운 시간 타입 추가하기")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.theme.surface)
                    .cornerRadius(8)
                }
            }
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

#Preview("ScheduleImport Preset Group") {
    let viewModel = ScheduleImportViewModel(
        session: WorkPlaceEditingSession(type: .fixed),
        analyzeScheduleImage: WorkPlaceFeatureComposition.makeScheduleImageAnalyzer()
    )

    viewModel.session.scheduleImportDraft.presetDrafts = [
        TimePresetDraft(
            id: UUID(),
            label: "오픈",
            startTime: Date.makeTime(9, 0),
            endTime: Date.makeTime(15, 0)
        ),
        TimePresetDraft(
            id: UUID(),
            label: "마감",
            startTime: Date.makeTime(17, 0),
            endTime: Date.makeTime(23, 0)
        )
    ]

    return ScheduleImportPresetGroup(
        sivm: viewModel,
        preset: viewModel.session.scheduleImportDraft.presetDrafts
    )
    .padding()
}
