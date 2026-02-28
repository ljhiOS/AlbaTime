//
//  WidgetView.swift
//  AlbaTime
//
//  Created by 이준희 on 2/6/26.
//

import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: NextShiftWidgetEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        // 생명주기 관리할 대상이 아니며 가벼운 값 객체 생성은 비용이 작아서 바디에 넣어도 상관없을거 같다
        let wvm = WidgetViewModel(model: entry.model)
        
        VStack(alignment: .leading) {
            HStack {
                
                Image(systemName: "clock.fill")
                    .resizable()
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 20, height: 20)
                    .padding(7)
                    .background(
                        Circle()
                            .fill(Color.theme.field)
                    )
                
                Text("다음 근무")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding(.bottom, 8)

            Text(wvm.workplaceText)
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)
                .lineLimit(1)
            
            Text(wvm.primaryTimeText)
                .font(.system(size: family == .systemSmall ? 28 : 34, weight: .bold))
                .foregroundStyle(Color.theme.textPrimary)
            
            Text(wvm.scheduleLabelText)
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
                .lineLimit(1)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .containerBackground(Color.theme.surface, for: .widget)
    }
}

#Preview(as: .systemSmall) {
    NextShiftWidget()
} timeline: {
    NextShiftWidgetEntry(
        model: WidgetModel(
            workplaceName: "GS25 강남점",
            shiftStart: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            shiftEnd: Calendar.current.date(byAdding: .hour, value: 7, to: Date()),
            plannedHours: 4.0
        ),
        date: Date()
    )
}
