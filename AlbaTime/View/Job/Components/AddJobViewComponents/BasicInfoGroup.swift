//
//  BasicInfoGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI
import SwiftData

struct BasicInfoGroup: View {
    @Bindable var job: Workplace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading) {
                Text("매장명").font(.callout)
                TextField("예) 스타벅스 강남점", text: $job.name)
                    .padding(10)
                    .background(Color.theme.field)
                    .cornerRadius(8)
            }
            VStack(alignment: .leading) {
                Text("시급")
                    .font(.callout)
                
                let wageProxy = Binding<String>(
                    get: { job.hourlyWage == 0 ? "" : String(job.hourlyWage) },
                    set: { job.hourlyWage = Int($0) ?? 0 }
                )
                
                
                TextField("예) 10320", text: wageProxy) // value가 아니라 text 사용
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color.theme.field)
                    .cornerRadius(8)
                
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("세금 적용")
                        .font(.callout)
                    Picker("세금 종류", selection: $job.taxType) {
                        ForEach(TaxType.allCases, id: \.self) { type in Text(type.rawValue).tag(type) }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.theme.textPrimary)
                    .padding(5)
                    .background(Color.theme.field).cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("수당 적용")
                        .font(.callout)
                    Picker("수당 종류", selection: $job.allowanceType) {
                        ForEach(AllowanceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.theme.textPrimary)
                    .padding(5)
                    .background(Color.theme.field)
                    .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    // 1. 가상 DB 컨테이너 생성
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    
    // 2. 샘플 데이터 생성
    let sampleJob = Workplace(
        name: "GS25 강남점",
        hourlyWage: 10300,
        defaultDays: "",
        defaultStartTime: Date(),
        defaultEndTime: Date()
    )
    
    // 3. 뷰 리턴
    return BasicInfoGroup(job: sampleJob)
        .modelContainer(container)
}
