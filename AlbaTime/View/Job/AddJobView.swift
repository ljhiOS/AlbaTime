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
        @Bindable var job = ajvm.job
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    HeaderView(title: stateName, dismiss: dismiss)
                    
                    Divider().padding(.horizontal)
                    
                    // 1. 기본 정보
                    BasicInfoGroup(job: ajvm.job)
                    
                    Divider().padding(.horizontal)
                    
                    // 2. 근무 형태에 따른 UI 자동 분기
                    if ajvm.job.workType == .fixed {
                        ScheduleGroup(ajvm: ajvm)
                    } else {
                        FlexibleInfoGroup(ajvm: ajvm)
                    }
                    
                    Divider().padding(.horizontal)
                    
                    // 3. 프리셋
                    PresetGroup(ajvm: ajvm)
                    
                    Divider().padding(.horizontal)
                    
                    // 4. 기타
                    EtcGroup(job: ajvm.job)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarBackButtonHidden(true)
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
            .sheet(isPresented: $ajvm.isAIImportPresented, onDismiss: {
                ajvm.refreshSchedulesFromAI(context: modelContext)
            }) {
                ScheduleImportView(targetJob: ajvm.job)
            }
            .safeAreaInset(edge: .bottom) {
                BottomButton(title: "저장하기", action: {
                    if ajvm.saveJob(context: modelContext) { dismiss() }
                })
            }
        }
        .alert("알림", isPresented: $ajvm.showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(ajvm.errorMessage)
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, WorkTimePreset.self, configurations: config)
    
    // 프리뷰 수정
    return AddJobView(stateName: "알바 등록", selectedType: .fixed)
        .modelContainer(container)
}
