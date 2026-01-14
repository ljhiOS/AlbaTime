//
//  ScheduleDetailCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/13/25.
//

import SwiftUI
import SwiftData

struct ScheduleDetailCard: View {
    @ObservedObject var cvm: CalendarViewModel
    var allWorkplaces: [Workplace] // 전체 가게 목록을 받음
    
    var body: some View {
        // 오늘 해야할 일
        let scheduledJobs = cvm.getScheduledWorkplaces(for: cvm.selectedDate, allWorkplaces: allWorkplaces)
        let totalPay = cvm.getTotalEstimatedPay(for: cvm.selectedDate, allWorkplaces: allWorkplaces)
        
        VStack(alignment: .leading, spacing: 16) {
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cvm.selectedDate.format("M월 d일 (E)"))
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if scheduledJobs.isEmpty {
                        Text("예정된 근무가 없습니다")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("총 \(scheduledJobs.count)개의 알바")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } //:VStack
                
                Spacer()
                
                if !scheduledJobs.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("₩\(totalPay)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("오늘의 예상 급여")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } //:VStack
                }
            } //:HStack
            
            Divider()
            
            if scheduledJobs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("오늘은 쉬는 날이에요! 🎉")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                } //:HStack
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(scheduledJobs) { job in
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(job.name)
                                        .font(.headline)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                        Text(cvm.getWorkTimeRange(for: job))
                                    } //:HStack
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                } //:VStack
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    
                                    Text("₩\(SalaryCalculator.calculateExpectedPay(workplace: job))")
                                        .fontWeight(.semibold)
                                    
                                    Text("시급 \(job.hourlyWage)원")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.8))
                                } //:VStack
                            } //:HStack
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                        } //:Loop
                    } //:VStack
                    .padding(.top, 4)
                } //:ScrollViewEnd
                .frame(maxHeight: 250)
            }
        }
        .padding(24)
        .background(Color(uiColor: .systemGray6).opacity(0.6))
        .cornerRadius(12, antialiased: true)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
}

#Preview("상세 카드") {
    // 1. 뷰모델 준비
    let cvm = CalendarViewModel()
    cvm.selectedDate = Date() // 오늘 날짜
    
    // 2. 데이터 준비 (PreviewHelper 컨테이너 사용)
    let container = PreviewHelper.container
    let context = container.mainContext
    
    // 데이터 가져오기 (에러 방지를 위해 try? 사용하고 실패시 빈 배열 반환)
    let workplaces = (try? context.fetch(FetchDescriptor<Workplace>())) ?? []
    
    return ScheduleDetailCard(cvm: cvm, allWorkplaces: workplaces)
        .padding()
        .background(Color.white)
        // 중요: 프리뷰가 안정적으로 돌도록 컨테이너 주입
        .modelContainer(container)
}
