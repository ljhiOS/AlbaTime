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
    
    @AppStorage("hasSeenPayCardHint") private var hasSeenPayCardHint: Bool = false
    @State private var showPayCardHint: Bool = false

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
                        onToggle: {
                            if showPayCardHint {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPayCardHint = false
                                }
                            }
                            hasSeenPayCardHint = true
                        }
                    )
                    .padding(.top)
                    .overlay(alignment: .topTrailing) {
                        if showPayCardHint {
                            Text("카드를 터치하면\n누적/예상총액을 전환해요")
                                .font(.caption)
                                .foregroundStyle(Color.theme.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.theme.primary.opacity(0.35), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 4)
                                .padding(.top, 6)
                                .padding(.trailing, 6)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPayCardHint = false
                                    }
                                    hasSeenPayCardHint = true
                                }
                        }
                    }
                    
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
                if !hasSeenPayCardHint {
                    showPayCardHint = true
                }
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
