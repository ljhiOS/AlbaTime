//
//  FlexibleInfoGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct FlexibleInfoGroup: View {
    @ObservedObject var session: WorkPlaceEditingSession

    var estimatedWeeklyPay: Int {
        let draft = session.workPlaceDraft
        return Int(Double(draft.hourlyWage) * Double(draft.targetWeeklyCount) * draft.expectedDailyHours)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 1. 주 몇 회 근무?
            VStack(alignment: .leading) {
                HStack {
                    Text("일주일에 몇 번 가나요?")
                    Spacer()
                    Text("주 \(session.workPlaceDraft.targetWeeklyCount)회")
                        .bold()
                        .foregroundStyle(Color.theme.primary)
                }
                .font(.callout)

                HStack(spacing: 0) {
                    ForEach(1...7, id: \.self) { day in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                session.workPlaceDraft.targetWeeklyCount = day
                            }
                        } label: {
                            Circle()
                                .fill(session.workPlaceDraft.targetWeeklyCount == day ? Color.theme.primary : Color.gray.opacity(0.1))
                                .overlay(
                                    Text("\(day)")
                                        .font(.subheadline).bold()
                                        .foregroundStyle(session.workPlaceDraft.targetWeeklyCount == day ? .white : .gray)
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
                    Text("\(String(format: "%.1f", session.workPlaceDraft.expectedDailyHours)) 시간")
                        .bold()
                        .foregroundStyle(Color.theme.primary)
                }
                .font(.callout)

                Slider(value: $session.workPlaceDraft.expectedDailyHours, in: 1...12, step: 0.5) {
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
            if session.workPlaceDraft.hourlyWage > 0 {
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
    let viewModel = AddWorkPlaceViewModel(
        type: .flexible,
        workPlaceSaving: PreviewFlexibleInfoWorkPlaceSaving(),
        analyticsTracker: NoopAnalyticsTracker()
    )
    viewModel.session.workPlaceDraft.hourlyWage = 10350
    viewModel.session.workPlaceDraft.targetWeeklyCount = 4
    viewModel.session.workPlaceDraft.expectedDailyHours = 6.5

    return ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        FlexibleInfoGroup(session: viewModel.session)
    }
}

@MainActor
private struct PreviewFlexibleInfoWorkPlaceSaving: WorkPlaceSaving {
    func execute(_ command: SaveWorkPlaceCommand) throws { }
}
