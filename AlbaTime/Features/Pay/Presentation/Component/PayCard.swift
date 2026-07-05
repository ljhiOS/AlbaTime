//
//  PayCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/15/25.
//

import SwiftUI

struct PayCard: View {
    
    @ObservedObject var pvm: PayViewModel
    var onToggle: (() -> Void)? = nil
    
    @State private var showExpected: Bool = false
    @State private var headerOffsetY: CGFloat = 0
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Text(showExpected ? "이번 달 총 예상 급여" : "이번 달 누적 급여")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.top)
            
                Text("\((showExpected ? pvm.projectedSalaryData.totalPay : pvm.salaryData.totalPay).formatted())원")
                    .foregroundStyle(.yellow)
                    .font(.title)
                    .bold()
            }
            .padding(.horizontal)
            .offset(y: headerOffsetY)
            
            Divider()
                .frame(height: 1)
                .background(Color.white)
                .padding(.horizontal)
            
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(showExpected ? "이번 달 총 근무시간" : "이번 달 누적 근무시간")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text(String(
                        format: "%.1f시간",
                        showExpected ? pvm.projectedSalaryData.monthlyWorkHours : pvm.salaryData.accruedWorkHours
                        )
                    )
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("평균 시급")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text("\(pvm.averageWage.formatted())원")
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .bold(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }.padding()
        }
        .background(Color.theme.primary)
        .frame(maxWidth: .infinity)
        .cornerRadius(20)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            bounceHeaderAndToggleValue()
        }
    }

    private func bounceHeaderAndToggleValue() {
        guard !isAnimating else { return }
        isAnimating = true
        Haptics.impact(.light)

        withAnimation(.easeIn(duration: 0.14)) {
            headerOffsetY = 10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            showExpected.toggle()
            onToggle?()

            withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                headerOffsetY = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isAnimating = false
            }
        }
    }
}

#Preview {
    let pvm = PayViewModel()
    pvm.salaryData = SalaryBreakdown(
        basicPay: 1050000,
        nightPay: 93220,
        holidayPay: 120000,
        taxAmount: 120500,
        totalPay: 1142720,
        monthlyWorkHours: 200.0,
        accruedWorkHours: 108.5,
        workingDays: 12
    )
    pvm.projectedSalaryData = SalaryBreakdown(
        basicPay: 1240000,
        nightPay: 110000,
        holidayPay: 160000,
        taxAmount: 138800,
        totalPay: 1371200,
        monthlyWorkHours: 200.0,
        accruedWorkHours: 128.0,
        workingDays: 14
    )
    pvm.averageWage = 10530

    return PayCard(pvm: pvm)
        .padding()
}
