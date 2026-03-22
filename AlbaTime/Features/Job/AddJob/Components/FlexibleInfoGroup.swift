//
//  FlexibleInfoGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI
import SwiftData

struct FlexibleInfoGroup: View {
    @ObservedObject var ajvm: AddJobViewModel
    
    var estimatedWeeklyPay: Int {
            let wage = ajvm.job.hourlyWage
            let count = ajvm.targetWeeklyCount
            let hours = ajvm.expectedDailyHours
            return Int(Double(wage) * Double(count) * hours)
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 1. 주 몇 회 근무?
            VStack(alignment: .leading) {
                HStack {
                    Text("일주일에 몇 번 가나요?")
                    Spacer()
                    Text("주 \(ajvm.targetWeeklyCount)회")
                        .bold()
                        .foregroundStyle(Color.theme.primary)
                }
                .font(.callout)
                
                HStack(spacing: 0) {
                    ForEach(1...7, id: \.self) { day in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                ajvm.targetWeeklyCount = day
                            }
                        } label: {
                            Circle()
                                .fill(ajvm.targetWeeklyCount == day ? Color.theme.primary : Color.gray.opacity(0.1))
                                .overlay(
                                    Text("\(day)")
                                        .font(.subheadline).bold()
                                        .foregroundStyle(ajvm.targetWeeklyCount == day ? .white : .gray)
                                )
                                .frame(height: 44)
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            
            Divider()
            
            // 2. 하루 평균 몇 시간?
            VStack(alignment: .leading) {
                HStack {
                    Text("하루 평균 근무 시간")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", ajvm.expectedDailyHours)) 시간")
                        .bold()
                        .foregroundStyle(Color.theme.primary)
                }
                .font(.callout)
                
                Slider(value: $ajvm.expectedDailyHours, in: 1...12, step: 0.5) {
                    Text("Hours")
                } minimumValueLabel: {
                    Text("1h")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                } maximumValueLabel: {
                    Text("12h")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .tint(Color.theme.primary)
            }
            if ajvm.job.hourlyWage > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("예상 주급")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.white.opacity(0.8))
                        Text("약 \(estimatedWeeklyPay.formatted())원")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "wonsign.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [Color.theme.primary, Color.theme.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                        )
                        .shadow(color: Color.theme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
        }
        .padding(20)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, WorkTimePreset.self, configurations: config)
    
    let vm = AddJobViewModel(type: .flexible)
    vm.job.hourlyWage = 10350 // 2026년 최저시급 가정
    
    return ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        FlexibleInfoGroup(ajvm: vm)
    }
    .modelContainer(container)
}
