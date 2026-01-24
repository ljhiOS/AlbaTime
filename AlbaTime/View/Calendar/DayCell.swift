//
//  DayCell.swift
//  AlbaTime
//
//  Created by 이준희 on 12/13/25.
//

import SwiftUI
import SwiftData

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let todayJobs: [Workplace]
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? Color.theme.primary : .black)
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.theme.primary.opacity(0.1) : Color.clear)
                .clipShape(Circle())
            
            if !todayJobs.isEmpty {
                Circle()
                    .fill(Color.theme.primary)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        } //:VStack
    }
}

#Preview("DayCell 모음") {
    // 1. 데이터 준비 (PreviewHelper 컨테이너 사용)
    let container = PreviewHelper.container
    let context = container.mainContext
    
    // 2. 가짜 가게 데이터 가져오기
    let workplaces = (try? context.fetch(FetchDescriptor<Workplace>())) ?? []
    
    return HStack(spacing: 20) {
        // Case 1: 선택됨 + 오늘 근무 있음 (점 찍힘)
        DayCell(
            date: Date(),
            isSelected: true,
            todayJobs: workplaces // [Workplace] 전달
        )
        
        // Case 2: 선택 안 됨 + 오늘 근무 있음 (점 찍힘)
        DayCell(
            date: Date(),
            isSelected: false,
            todayJobs: workplaces
        )
        
        // Case 3: 선택 안 됨 + 근무 없음 (점 없음)
        DayCell(
            date: Date(),
            isSelected: false,
            todayJobs: [] // 빈 배열 전달
        )
    }
    .padding()
    .modelContainer(container) // ⭐️ 프리뷰 크래시 방지용
}
