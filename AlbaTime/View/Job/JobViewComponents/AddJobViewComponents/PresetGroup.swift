//
//  PresetGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI
import SwiftData

struct PresetGroup: View {
    @ObservedObject var ajvm: AddJobViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("근무 시간 타입 (선택)")
                    .font(.callout)
                Spacer()
                if ajvm.job.timePresets.isEmpty { Text("오픈, 마감 등 설정")
                    .font(.caption)
                    .foregroundStyle(.gray) }
            }
            .padding(.horizontal)
            
            ForEach(ajvm.job.timePresets) { preset in
                PresetRow(preset: preset) { ajvm.deletePreset(preset) }
            }
            
            if ajvm.isAddingPreset {
                VStack(spacing: 10) {
                    TextField("타입 이름 (예: 오픈)", text: $ajvm.newPresetLabel)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    HStack {
                        DatePicker("", selection: $ajvm.newPresetStart, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Text("~")
                        DatePicker("", selection: $ajvm.newPresetEnd, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    HStack {
                        Button("취소") { withAnimation { ajvm.isAddingPreset = false } }
                            .foregroundStyle(.red)
                            .font(.caption)
                        Spacer()
                        Button("추가") { ajvm.addNewPreset() }
                            .bold()
                            .foregroundStyle(Color.theme.primary)
                            .disabled(ajvm.newPresetLabel.isEmpty)
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(8)
                .padding(.horizontal)
            } else {
                Button { withAnimation { ajvm.isAddingPreset = true }
                } label: {
                    HStack { Image(systemName: "plus.circle.fill"); Text("새로운 시간 타입 추가하기") }
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, WorkTimePreset.self, configurations: config)
    
    // 🔥 [수정] type 지정 필수
    let vm = AddJobViewModel(type: .fixed)
    
    // 샘플 데이터 추가
    let preset = WorkTimePreset(
        label: "오픈",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600 * 4)
    )
    vm.job.timePresets.append(preset)
    
    return PresetGroup(ajvm: vm)
        .modelContainer(container)
}
