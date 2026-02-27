//
//  EtcGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI
import SwiftData

struct EtcGroup: View {
    @Bindable var job: Workplace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading) {
                Text("휴게 시간 (선택)")
                    .font(.callout)
                    .padding(.horizontal)
                HStack(spacing: 10) {
                    TextField("예: 60", value: $job.defaultRestTime, format: .number)
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
                .padding(.horizontal)
            }
            
            Divider().padding(.horizontal)
            
            VStack(alignment: .leading) {
                Text("메모 (선택)").font(.callout).padding(.horizontal)
                TextField("특이사항 입력", text: Binding(
                    get: { job.defaultMemo ?? "" },
                    set: { job.defaultMemo = $0 }
                ), axis: .vertical
                )
                    .padding(10)
                    .padding(.bottom, 100)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    
    let sampleJob = Workplace(
        name: "스타벅스",
        hourlyWage: 10000,
        defaultDays: "",
        defaultStartTime: Date(),
        defaultEndTime: Date(),
        defaultRestTime: 60,
        defaultMemo: "사장님이 화요일에 오심"
    )
    
    return EtcGroup(job: sampleJob)
        .modelContainer(container)
}
