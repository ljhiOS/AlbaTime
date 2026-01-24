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
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 12) {
            // 저장하기 버튼
            Button {
                sivm.saveToWorkplace(context: modelContext)
                dismiss()
            } label: {
                Text("저장하기")
                    .font(.headline).bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        sivm.parsedSchedules.isEmpty
                        ? Color.gray.opacity(0.5)
                        : Color.theme.primary
                    )
                    .cornerRadius(12)
            }
            .disabled(sivm.parsedSchedules.isEmpty)
            
            // 취소 버튼
            Button {
                dismiss()
            } label: {
                Text("취소하고 수기로 입력하기")
                    .font(.subheadline).bold()
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}

#Preview {
    // 1. DismissAction 환경 변수를 주입하기 위한 래퍼 뷰
    struct PreviewWrapper: View {
        @Environment(\.dismiss) var dismiss
        @StateObject var vm = ScheduleImportViewModel()
        
        var body: some View {
            VStack {
                Spacer()
                
                
                // 3. 테스트 대상 뷰
                ScheduleImportBottomButtons(sivm: vm, dismiss: dismiss)
            }
            .onAppear {
                // 4. [UX 확인용] 가짜 데이터가 있어야 '저장하기' 버튼이 활성화됨
                // 주석을 해제하면 버튼이 활성화되는 것을 볼 수 있습니다.
                
                 vm.parsedSchedules.append(ParsedSchedule(
                     date: Date(),
                     startTime: Date(),
                     endTime: Date(),
                     scheduleName: "테스트"
                 ))
                 
            }
        }
    }
    
    // 2. 가상 SwiftData 컨테이너 생성
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    
    return PreviewWrapper()
        .modelContainer(container)
}
