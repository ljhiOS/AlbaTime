//
//  WorkPlaceComponent.swift
//  AlbaTime
//
//  Created by 이준희 on 7/11/26.
//

import SwiftUI

struct WorkPlaceComponent: View {
    
    let schedule: CalendarScheduleState
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.workPlaceName)
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                
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
                Text("₩\(schedule.estimatedPay.formatted())")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.textPrimary)
                
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

//#Preview {
//    WorkPlaceComponent()
//}
