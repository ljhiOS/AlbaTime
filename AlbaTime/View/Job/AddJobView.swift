//
//  AddJobView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData

struct AddJobView: View {
    @StateObject private var ajvm: AddJobViewModel
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var stateName: String
    
    // job을 받을 수 있도록 생성자(init)를 수정해야 합니다.
    init(stateName: String = "알바 등록", job: Workplace? = nil, selectedType: WorkType? = nil) {
        
        if let existingJob = job {
            // [A] 수정 모드: job이 들어오면 '수정용' 뷰모델 생성
            self.stateName = "알바 수정"
            _ajvm = StateObject(wrappedValue: AddJobViewModel(editingJob: existingJob))
        } else {
            // [B] 신규 모드: job이 없으면 '신규 생성용' 뷰모델 생성
            self.stateName = stateName
            let type = selectedType ?? .fixed
            _ajvm = StateObject(wrappedValue: AddJobViewModel(type: type))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {

                BasicInfoGroup(job: ajvm.job)
                    .padding(.horizontal)
                
                Divider().padding(.horizontal)

                if ajvm.job.workType == .fixed {
                    ScheduleGroup(ajvm: ajvm)
                        .padding(.horizontal)
                } else {
                    
                    FlexibleInfoGroup(ajvm: ajvm)
                        .padding(.horizontal)
                }

                Divider().padding(.horizontal)

                EtcGroup(job: ajvm.job)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color.theme.surface)
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    ajvm.validateAndOpenAI()
                } label: {
                    HStack(spacing: 4) { Image(systemName: "sparkles"); Text("AI 스케줄") }
                        .font(.caption).bold()
                        .foregroundStyle(Color.theme.primary)
                        .padding(6)
                        .background(Color.theme.primary.opacity(0.1))
                        .cornerRadius(20)
                }
            }
        }
        .navigationTitle(stateName)
        .navigationDestination(isPresented: $ajvm.isAIImportPresented) {
            ScheduleImportView(targetJob: ajvm.job)
        }
        .safeAreaInset(edge: .bottom) {
            BottomButton(title: "저장하기", action: {
                if ajvm.saveJob(context: modelContext) { dismiss() }
            })
        }
        .alert("알림", isPresented: $ajvm.showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(ajvm.errorMessage)
        }
    }
}

// MARK: - Preview
#Preview("고정 근무") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, WorkTimePreset.self, configurations: config)
    
    return AddJobView(stateName: "알바 등록", selectedType: .fixed)
        .modelContainer(container)
}

#Preview("비고정 근무") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, WorkTimePreset.self, configurations: config)
    
    return AddJobView(stateName: "알바 등록", selectedType: .flexible)
        .modelContainer(container)
}
