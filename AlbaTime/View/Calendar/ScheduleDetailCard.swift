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
    var allWorkplaces: [Workplace]
    
    var body: some View {
        // 뷰모델을 통해 해당 날짜의 알바 목록과 급여를 가져옴
        let scheduledJobs = cvm.getScheduledWorkplaces(for: cvm.selectedDate, allWorkplaces: allWorkplaces)
        let totalPay = cvm.getTotalEstimatedPay(for: cvm.selectedDate, allWorkplaces: allWorkplaces)
        
        VStack(alignment: .leading, spacing: 16) {
            
            // 헤더 영역 (날짜 + 총 급여)
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
                }
                
                Spacer()
                
                if !scheduledJobs.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("₩\(totalPay.formatted())")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("선택한 날짜의 예상 급여")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Divider()
            
            // 본문 영역 (리스트 or 빈 화면)
            if scheduledJobs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("오늘은 쉬는 날이에요!")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(scheduledJobs) { job in
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(job.name)
                                        .font(.headline)
                                    
                                    HStack(spacing: 6) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                            // 선택 날짜 기준 근무 시간대
                                            Text(cvm.getWorkTimeRange(for: job, on: cvm.selectedDate))
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    // 뷰모델의 getEstimatedPay 사용
                                    Text("₩\(cvm.getEstimatedPay(for: job, on: cvm.selectedDate).formatted())")
                                        .fontWeight(.semibold)
                                    
                                    Text("시급 \(job.hourlyWage.formatted())원")
                                        .font(.caption2)
                                        .foregroundColor(.gray.opacity(0.8))
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxHeight: 250)
            }
        }
        .padding(24)
        .background(Color(uiColor: .systemGray6).opacity(0.6))
        .cornerRadius(12, antialiased: true)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
}

// MARK: - Preview

#Preview("근무 있음") {
    // 1. 메모리 전용 DB 컨테이너 생성
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, WorkSchedule.self, WorkTimePreset.self, configurations: config)
    
    // 2. 가짜 데이터 생성
    // Case A: 편의점 (고정 근무)
    let job1 = Workplace(
        name: "GS25 강남점",
        hourlyWage: 9860,
        defaultDays: "월,수,금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(14, 0),
        defaultRestTime: 30,
        workType: .fixed
    )
    
    // Case B: 카페 (자율 근무 + 메모 포함)
    let job2 = Workplace(
        name: "스타벅스",
        hourlyWage: 11000,
        defaultDays: "",
        defaultStartTime: Date.makeTime(18, 0),
        defaultEndTime: Date.makeTime(22, 0),
        workType: .flexible
    )
    
    container.mainContext.insert(job1)
    container.mainContext.insert(job2)
    
    // 3. 오늘 날짜에 스케줄 강제 주입 (프리뷰에서 항상 보이게 하기 위함)
    let today = Date()
    
    // 편의점 스케줄 (09:00 - 14:00)
    let schedule1 = WorkSchedule(
        date: today,
        startTime: Date.makeTime(9, 0),
        endTime: Date.makeTime(14, 0),
        breakTime: 30,
        workplace: job1
    )
    job1.workSchedules.append(schedule1)
    
    // 카페 스케줄 (18:00 - 22:00, 오픈 메모)
    let schedule2 = WorkSchedule(
        date: today,
        startTime: Date.makeTime(18, 0),
        endTime: Date.makeTime(22, 0),
        breakTime: 0,
        memo: "마감 대타",
        workplace: job2
    )
    job2.workSchedules.append(schedule2)
    
    // 4. 뷰모델 설정 및 캐시 업데이트
    let cvm = CalendarViewModel()
    cvm.selectedDate = today
    // 프리뷰에서는 캐시를 수동으로 갱신한다.
    cvm.updateCache(workplaces: [job1, job2])
    
    return ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea() // 배경색 확인용
        
        ScheduleDetailCard(cvm: cvm, allWorkplaces: [job1, job2])
    }
    .modelContainer(container)
}

#Preview("근무 없음 (빈 상태)") {
    let cvm = CalendarViewModel()
    cvm.selectedDate = Date()
    
    return ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        ScheduleDetailCard(cvm: cvm, allWorkplaces: [])
    }
}
