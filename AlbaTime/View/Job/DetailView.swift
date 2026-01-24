//
//  SwiftUIView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/9/25.
//

// 상세 보기 뷰

import SwiftUI

struct DetailView: View {
    let job: Workplace
    
    @Environment(\.dismiss) var dismiss
    
    var salaryData: SalaryBreakdown {
            // [핵심] 여기서 계산기를 돌려서 결과 꾸러미를 받아옵니다.
            return SalaryCalculator.calculateTotalMonthlyPay(
                workplaces: [job],
                targetMonth: Date()
            )
        }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                HStack {
                    Text("상세보기")
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
                } //:HStack
                .padding()
                
                WorkCardDetail(job: job, hours: salaryData.totalHours)
                
                StaticDetailView(
                    totalDays: salaryData.workingDays,  // 뷰모델의 일수 변수
                    totalHours: salaryData.totalHours,       // 계산된 총 근무 시간
                    totalWage: salaryData.totalPay   // 뷰모델의 급여 변수
                )
                
                PlusInfo(job: job)
                
            } //:VStack
        } //:ScrollViewEnd
    }
}

#Preview {
    DetailView(job: Workplace(
        name: "GS25 강남점",
        hourlyWage: 10320,
        defaultDays: "월/수/금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0)
//        allTimes: "48시간"
    ))
}
