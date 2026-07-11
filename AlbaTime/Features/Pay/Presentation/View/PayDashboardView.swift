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
    @State private var showExpected = false

    init(
        workPlaces: [WorkPlace],
        viewModel: PayViewModel
    ) {
        self.workPlaces = workPlaces
        _pvm = StateObject(wrappedValue: viewModel)
    }

    private var showsNightAllowance: Bool {
        workPlaces.contains { $0.allowanceType.includesNight }
    }

    private var showsHolidayAllowance: Bool {
        workPlaces.contains { $0.allowanceType.includesHoliday }
    }
    
    var body: some View {
        VStack {
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    PayCard(
                        pvm: pvm,
                        showExpected: $showExpected
                    )
                    .spotlightTarget(.payDashboardBreakdown)
                    .padding(.top)
                    
                    PayDetailCard(
                        breakdown: showExpected ? pvm.projectedSalaryData : pvm.salaryData,
                        isExpected: showExpected,
                        showsNightAllowance: showsNightAllowance,
                        showsHolidayAllowance: showsHolidayAllowance
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
                key: .payDashboardBreakdown,
                message: "카드를 터치하면 누적·예상 급여와 아래 산정 내역이 함께 전환돼요. 기본급, 수당, 세금 공제까지 확인할 수 있어요."
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
