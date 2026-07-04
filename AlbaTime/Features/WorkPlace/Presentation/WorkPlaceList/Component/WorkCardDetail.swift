//
//  WorkCardDetail.swift
//  AlbaTime
//
//  Created by 이준희 on 12/9/25.
//

import SwiftUI

struct WorkCardDetail: View {
    let state: WorkPlaceDetailViewState
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(.white)
                
                Text("\(state.name)")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Spacer()
                
            }.padding(.top)
             .padding(.leading)
            
            VStack(alignment: .leading) {
                Text("시급")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    
                
                Text("\(state.hourlyWage)원")
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
                    Text(state.workType == .fixed ? "기본 근무 시간" : "근무 패턴")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    if state.workType == .fixed {
                        Text(state.fixedDaysText)
                            .foregroundStyle(.white)
                            .bold(true)
                        
                        Text("\(state.defaultStartTime.format("HH:mm")) - \(state.defaultEndTime.format("HH:mm"))")
                            .foregroundStyle(.white)
                            .bold(true)
                    } else {
                        Text("주 \(state.targetWeeklyCount)회")
                            .foregroundStyle(.white)
                            .bold(true)
                        
                        Text("평균 \(String(format: "%.1f", state.expectedDailyHours))시간")
                            .foregroundStyle(.white)
                            .bold(true)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("총 근무 시간")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text(String(format: "%.1f시간", state.monthlyWorkHours))
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .bold()
                    
                    if let restTime = state.defaultRestTime {
                        
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
}

#Preview("휴게시간 있음") {
    WorkCardDetail(
        state: WorkPlaceDetailViewState(
            id: UUID(),
            name: "GS25 강남점 (휴게O)",
            hourlyWage: 10030,
            workType: .fixed,
            fixedDaysText: "월/수/금",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            targetWeeklyCount: 0,
            expectedDailyHours: 0,
            defaultRestTime: 60,
            memo: "",
            totalDays: 12,
            accruedWorkHours: 32,
            monthlyWorkHours: 48,
            totalWage: 480000
        )
    )
}
#Preview("휴게시간 없음") {
    WorkCardDetail(
        state: WorkPlaceDetailViewState(
            id: UUID(),
            name: "GS25 강남점 (휴게X)",
            hourlyWage: 10030,
            workType: .fixed,
            fixedDaysText: "월/수/금",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            targetWeeklyCount: 0,
            expectedDailyHours: 0,
            defaultRestTime: nil,
            memo: "",
            totalDays: 12,
            accruedWorkHours: 32,
            monthlyWorkHours: 48,
            totalWage: 480000
        )
    )
}
