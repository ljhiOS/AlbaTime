//
//  StaticDetailView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/10/25.
//

import SwiftUI

struct StaticDetailView: View {
    var totalDays: Int
    var totalHours: Double
    var totalWage: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("이번 달 통계")
                .font(.title2)
                .padding()
                
            
            HStack {
                Spacer()
                StaticDetailComponents(icon: "calendar", title: "누적 근무일", caption: "\(totalDays)일", color: .blue)
                Spacer()
                StaticDetailComponents(icon: "clock.fill", title: "누적 시간", caption: String(format: "%.f시간", totalHours), color: .green)
                Spacer()
                StaticDetailComponents(icon: "wonsign.circle.fill", title: "누적 급여", caption: "\(totalWage / 10000)만원", color: .red
                )
                Spacer()
            } //:HStack
            .padding()
            .frame(maxWidth: .infinity)
        } //:VStack
        .background(Color.theme.field)
        .frame(maxWidth: .infinity)
        .cornerRadius(20)
    }
}

struct StaticDetailComponents: View {
    let icon: String
    let title: String
    let caption: String
    let color: Color
    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .foregroundStyle(color)
                .frame(width: 20, height: 20)
                .padding(10)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            Text(title)
                .font(.caption)
            Text(caption)
        
        }.padding()
            .background(Color.theme.surface)
            .cornerRadius(20)
    }
}

#Preview {
    StaticDetailView(totalDays: 12, totalHours: 45.5, totalWage: 540000)
}
