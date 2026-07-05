//
//  PayDashboardView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct PayDashboardView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    private let workPlaces: [WorkPlace]

    @StateObject private var pvm: PayViewModel

    init(
        workPlaces: [WorkPlace],
        viewModel: PayViewModel
    ) {
        self.workPlaces = workPlaces
        _pvm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    PayCard(
                        pvm: pvm,
                        onToggle: nil
                    )
                    .spotlightTarget(.payDashboardCard)
                    .padding(.top)
                    
                    PayDetailCard(
                        basicPay: pvm.salaryData.basicPay,
                        nightPay: pvm.salaryData.nightPay,
                        holidayPay: pvm.salaryData.holidayPay,
                        taxAmount: pvm.salaryData.taxAmount,
                        totalPay: pvm.salaryData.totalPay,
                        totalHours: pvm.salaryData.accruedWorkHours,
                        workingDays: pvm.salaryData.workingDays
                    )
                    
                    RealAchivePay()
                }
                .padding(.horizontal)
            }
            .background(Color.theme.surface)
            // 데이터가 로드되거나 변경될 때마다 ViewModel 업데이트
            .onAppear {
                pvm.updateData(workPlaces: workPlaces)
            }
            .onChange(of: workPlaces) { oldValue, newValue in
                
                pvm.updateData(workPlaces: newValue)
            }
            // 월이 바뀌었을 때도 업데이트 필요하다면 추가
            .onChange(of: pvm.currentMonth) { oldValue, newValue in
                pvm.updateData(workPlaces: workPlaces)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    pvm.updateData(workPlaces: workPlaces)
                }
            }
        }
        .spotlightOnboarding(steps: [
            SpotlightOnboardingStep(
                key: .payDashboardCard,
                message: "카드를 터치하면 이번 달 누적 급여와 예상 급여, 근무시간 표시가 함께 전환돼요."
            )
        ])
    }
}

#Preview {
    NavigationStack {
        PayDashboardView(
            workPlaces: [
                WorkPlace(
                    name: "GS25 강남점",
                    hourlyWage: 10000,
                    defaultDays: "월,수,금",
                    defaultStartTime: Date(),
                    defaultEndTime: Date().addingTimeInterval(3600 * 8)
                )
            ],
            viewModel: PayViewModel()
        )
    }
}
