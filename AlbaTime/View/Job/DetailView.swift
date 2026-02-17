//
//  DetailView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/9/25.
//

// 상세 보기 뷰

import SwiftUI

struct DetailView: View {
    let job: Workplace
    
    var salaryData: SalaryBreakdown {
            // 단일 근무지 기준 이번 달 누적 급여를 계산한다.
            return SalaryCalculator.calculateAccruedMonthlyPay(
                workplaces: [job],
                targetMonth: Date(),
                asOf: Date()
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
        .toolbar(.hidden, for: .tabBar)
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
