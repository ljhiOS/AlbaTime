//
//  WorkCardDetail.swift
//  AlbaTime
//
//  Created by 이준희 on 12/9/25.
//

import SwiftUI

struct WorkCardDetail: View {
    
    let job: Workplace
    let hours: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(.white)
                
                Text("\(job.name)")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Spacer()
                
            }.padding(.top)
             .padding(.leading)
            
            VStack(alignment: .leading) {
                Text("시급")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    
                
                Text("\(job.hourlyWage)원")
                    .foregroundStyle(.yellow)
                    .font(.title)
                    .bold()
            }.padding(.horizontal)
            
            Divider()
                .frame(height: 1)
                .background(Color.white)
                .padding(.horizontal)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.workType == .fixed ? "기본 근무 시간" : "근무 패턴")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    if job.workType == .fixed {
                        Text(fixedDaysText)
                            .foregroundStyle(.white)
                            .bold(true)
                        
                        Text("\(job.defaultStartTime.format("HH:mm")) - \(job.defaultEndTime.format("HH:mm"))")
                            .foregroundStyle(.white)
                            .bold(true)
                    } else {
                        Text("주 \(job.targetWeeklyCount ?? 0)회")
                            .foregroundStyle(.white)
                            .bold(true)
                        
                        Text("평균 \(String(format: "%.1f", job.expectedDailyHours ?? 0))시간")
                            .foregroundStyle(.white)
                            .bold(true)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("이번 달")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text(String(format: "%.1f시간", hours))
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .bold()
                    
                    if let restTime = job.defaultRestTime {
                        
                        Text("휴게시간")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        
                        Text("\(restTime)분")
                            .foregroundStyle(.white)
                            .font(.system(size: 20))
                            .bold()
                    }
                }
                
                Spacer()
            }.padding()
        }.background(Color.theme.primary)
            .frame(maxWidth: .infinity)
            .cornerRadius(20)
    }
    
    private var fixedDaysText: String {
        let order = ["월", "화", "수", "목", "금", "토", "일"]
        let days = Array(Set(job.regularSchedules.map(\.dayOfWeek)))
            .sorted { (order.firstIndex(of: $0) ?? 99) < (order.firstIndex(of: $1) ?? 99) }
        
        if !days.isEmpty { return days.joined(separator: "/") }
        
        let raw = job.defaultDays.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "요일 미설정" : raw
    }
}

#Preview("휴게시간 있음") {
    
    // 2. 휴게시간 있는 버전 (예: 60분)
    WorkCardDetail(
        job: Workplace(
            name: "GS25 강남점 (휴게O)",
            hourlyWage: 10030,
            defaultDays: "월/수/금",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            defaultRestTime: 60, // 여기에 값을 입력
            taxType: .none
        ),
        hours: 48
    )
}
#Preview("휴게시간 없음") {
    WorkCardDetail(
        job: Workplace(
            name: "GS25 강남점 (휴게X)",
            hourlyWage: 10030,
            defaultDays: "월/수/금",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            defaultRestTime: nil,
            taxType: .none
        ),
        hours: 48
    )
}
