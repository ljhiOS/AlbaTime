//
//  ScheduleDetailCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/13/25.
//

import SwiftUI

struct ScheduleDetailCard: View {
    let selectedDate: Date
    let schedules: [CalendarScheduleState]
    let totalPay: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 헤더 영역 (날짜 + 총 급여)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.format("M월 d일 (E)"))
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if schedules.isEmpty {
                        Text("예정된 근무가 없습니다")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("총 \(schedules.count)개의 알바")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if !schedules.isEmpty {
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
            if schedules.isEmpty {
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
                        ForEach(schedules) { schedule in
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(schedule.workPlaceName)
                                        .font(.headline)
                                    
                                    HStack(spacing: 6) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                            // 선택 날짜 기준 근무 시간대
                                            Text(schedule.timeRange)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    // 뷰모델의 getEstimatedPay 사용
                                    Text("₩\(schedule.estimatedPay.formatted())")
                                        .fontWeight(.semibold)
                                    
                                    Text("시급 \(schedule.hourlyWage.formatted())원")
                                        .font(.caption2)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                            }
                            .padding()
                            .background(Color.theme.surface)
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
        .background(Color.theme.field)
        .cornerRadius(12, antialiased: true)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
}

// MARK: - Preview

#Preview("근무 있음") {
    let today = Date()
    let schedules = [
        CalendarScheduleState(
            id: UUID(),
            workPlaceName: "GS25 강남점",
            timeRange: "09:00 - 14:00",
            estimatedPay: 44370,
            hourlyWage: 9860
        ),
        CalendarScheduleState(
            id: UUID(),
            workPlaceName: "스타벅스",
            timeRange: "18:00 - 22:00",
            estimatedPay: 44000,
            hourlyWage: 11000
        )
    ]
    
    return ZStack {
        Color.black // 배경색 확인용
        
        ScheduleDetailCard(
            selectedDate: today,
            schedules: schedules,
            totalPay: schedules.map(\.estimatedPay).reduce(0, +)
        )
    }
}

#Preview("근무 없음 (빈 상태)") {
    return ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        ScheduleDetailCard(
            selectedDate: Date(),
            schedules: [],
            totalPay: 0
        )
    }
}
