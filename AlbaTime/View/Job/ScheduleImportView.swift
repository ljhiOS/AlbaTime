//
//  ScheduleImportView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ScheduleImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var targetJob: Workplace?
    
    @AppStorage("myScheduleName") private var myName: String = ""
    @StateObject private var sivm = ScheduleImportViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    init(targetJob: Workplace? = nil) {
        self.targetJob = targetJob
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if sivm.selectedImage == nil {
                    ScheduleImportEmptyView(myName: $myName, dismiss: dismiss)
                } else if sivm.isProcessing {
                    ScheduleImportLoadingView(targetName: myName)
                } else {
                    ScheduleImportResultList(viewModel: sivm)
                }
                
                if sivm.selectedImage != nil {
                    ScheduleImportBottomButtons(sivm: sivm, dismiss: dismiss)
                }
            }
            .navigationTitle("스케줄 불러오기")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("앨범 선택", systemImage: "photo.badge.plus")
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await sivm.processSelectedPhoto(item: newItem, targetJob: targetJob, targetName: myName)
                }
            }
            // 🔥 에러 해결의 핵심: alert 내부에서 타입을 명확히 분리
            .alert("알림", isPresented: Binding(
                get: { sivm.showAlert },
                set: { sivm.showAlert = $0 }
            )) {
                Button("수기로 입력하기", role: .destructive) {
                    let isFixed = targetJob?.workType == .fixed
                    if isFixed {
                        dismiss()
                    } else {
                        // 자율 근무 시 현재 뷰의 로직 실행
                        sivm.isProcessing = false
                        if sivm.parsedSchedules.isEmpty {
                            sivm.addEmptySchedule()
                        }
                    }
                }
                Button("확인", role: .cancel) { }
            } message: {
                if let type = targetJob?.workType, type == .flexible {
                    Text(sivm.errorMessage + "\n하단의 '직접 추가' 버튼으로 스케줄을 완성할 수 있습니다.")
                } else {
                    Text(sivm.errorMessage)
                }
            }
        }
    }
}

// ✅ 프리뷰 코드 (관련 모델 모두 포함)
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, WorkTimePreset.self, configurations: config)
    
    let sampleJob = Workplace(
        name: "테스트 매장",
        hourlyWage: 10320,
        defaultDays: "",
        defaultStartTime: Date(),
        defaultEndTime: Date(),
        workType: .flexible
    )
    container.mainContext.insert(sampleJob)
    
    return ScheduleImportView(targetJob: sampleJob)
        .modelContainer(container)
}
