//
//  WorkShift.swift
//  AlbaTime
//
//  Created by 이준희 on 12/10/25.
//

import SwiftUI
import SwiftData

struct WorkEditView: View {
    
    @Bindable var job: Workplace
    
//    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    let stateName: String = "근무 수정"

    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 30) {
                
                // [상단 헤더]
                HStack {
                    Text(stateName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                            .font(.title)
                    }
                }.padding()
                
                Divider()
                    .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text("매장명")
                        .font(.callout)
                        .padding(.horizontal)
                    
                    TextField("예) 스타벅스 강남점", text: $job.name)
                        .padding(10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal)
                } //:VStack

                VStack(alignment: .leading) {
                    Text("시급")
                        .font(.callout)
                        .padding(.horizontal)
                    
                    TextField("예) 10030", value: $job.hourlyWage, format: .number.grouping(.never))
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal)
                } //:VStack
                
                VStack(alignment: .leading) {
                    Text("세금 적용")
                        .font(.callout)
                        .padding(.horizontal)
                    
                    Picker("세금 종류", selection: $job.taxType) {
                        ForEach(TaxType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.black)
                    .padding(5)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)
                    .padding(.horizontal)
                } //:VStack
                
                VStack(alignment: .leading) {
                    Text("주 근무 요일")
                        .font(.callout)
                        .padding(.horizontal)
  
                    HStack(spacing: 8) {
                        ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                            CustomButton_day(
                                day: day,
                                isSelected: job.isDaySelected(day),
                                action: { job.toggleDay(day) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                } //:VStack

                HStack(spacing: 10){
                    VStack(spacing: 0) {
                        TimePickerButton(title: "출근 시간", time: $job.defaultStartTime)
                            .padding(.bottom)
                        
                        Divider() // 구분선
                            .padding(.horizontal)
                        
                        TimePickerButton(title: "퇴근 시간", time: $job.defaultEndTime)
                            .padding(.top)
                    }
                } //:HStack
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("휴게 시간 (선택)")
                        .font(.callout)
                    
                    HStack(spacing: 10) {
                        TextField("예) 60", value: Binding(
                            get: { job.defaultRestTime ?? 0 },
                            set: { job.defaultRestTime = $0 == 0 ? nil : $0 }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.trailing)
                        
                        Text("분")
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text("메모 (선택)")
                        .font(.callout)
                    
                    TextField("특이사항이나 메모를 입력하세요.", text: Binding(
                        get: { job.defaultMemo ?? "" },
                        set: { job.defaultMemo = $0 }
                    ), axis: .vertical) // 여러 줄 입력 가능
                    .padding(10)
                    .padding(.bottom, 50)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            //:VStack
        } //:ScrollViewEnd
        
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 20) {
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("취소")
                        .foregroundStyle(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.leading)
                        .padding(.bottom)
                        .shadow(radius: 2)
                }
                
                // 수정 완료 버튼
                Button {
                    // 1. 기존 알림 제거
                    NotificationManager.shared.removeNotifications(for: job)
                    
                    // 2. 수정된 내용으로 알림 재등록
                    NotificationManager.shared.scheduleWorkNotification(for: job)
                    dismiss()
                } label: {
                    Text("수정 완료")
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.theme.primary)
                        .cornerRadius(8)
                        .padding(.trailing)
                        .padding(.bottom)
                        .shadow(radius: 2)
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    // 테스트 용 프리뷰 코드 ai 복붙
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    
    let sampleJob = Workplace(
        name: "스타벅스 강남점",
        hourlyWage: 10030,
        defaultDays: "월,수,금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        defaultMemo: "사장님이 친절함"
    )
    
    WorkEditView(job: sampleJob)
        .modelContainer(container)
}
