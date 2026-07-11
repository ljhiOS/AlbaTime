//
//  PayDetailCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/15/25.
//

import SwiftUI

struct PayDetailCard: View {
    let breakdown: SalaryBreakdown
    let isExpected: Bool
    let showsNightAllowance: Bool
    let showsHolidayAllowance: Bool

    private var totalHours: Double {
        isExpected ? breakdown.monthlyWorkHours : breakdown.accruedWorkHours
    }

    private var grossPay: Int {
        breakdown.basicPay + breakdown.nightPay + breakdown.holidayPay
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(isExpected ? "예상 급여 산정 내역" : "누적 급여 산정 내역")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            HStack {
                Text("근무 \(breakdown.workingDays)일 · \(String(format: "%.1f", totalHours))시간")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.textSecondary)
                Spacer()
            }

            payRow(
                title: "기본급",
                subtitle: "근무시간 기준",
                amount: breakdown.basicPay
            )
            if showsNightAllowance {
                payRow(
                    title: "야간수당",
                    subtitle: "22:00 ~ 06:00 가산",
                    amount: breakdown.nightPay
                )
            }
            if showsHolidayAllowance {
                payRow(
                    title: "주휴수당",
                    subtitle: "주휴 조건 충족분",
                    amount: breakdown.holidayPay
                )
            }

            Divider()

            payRow(
                title: "지급 합계",
                subtitle: "기본급 + 수당",
                amount: grossPay,
                emphasized: true
            )
            payRow(
                title: "세금 공제",
                subtitle: "적용 세금 기준",
                amount: breakdown.taxAmount,
                isDeduction: true
            )
            
            Divider()
            
            HStack {
                Text(isExpected ? "예상 실수령액" : "누적 실수령액")
                    .fontWeight(.semibold)
                Spacer()
                Text("₩\(breakdown.totalPay.formatted())")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.primary)
            }
        }
        .padding(24)
        .background(Color.theme.field)
        .cornerRadius(20)
    }

    private func payRow(
        title: String,
        subtitle: String,
        amount: Int,
        emphasized: Bool = false,
        isDeduction: Bool = false
    ) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(emphasized ? .body.weight(.semibold) : .body)
                    .foregroundStyle(isDeduction ? .red : Color.theme.textPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            Spacer()
            Text("\(isDeduction ? "- " : "")₩\(amount.formatted())")
                .font(emphasized ? .body.weight(.semibold) : .body)
                .foregroundStyle(isDeduction ? .red : Color.theme.textPrimary)
        }
    }
}

#Preview {
    ZStack {
        PayDetailCard(
            breakdown: SalaryBreakdown(
                basicPay: 960_000,
                nightPay: 50_000,
                holidayPay: 35_000,
                taxAmount: 90_000,
                totalPay: 955_000,
                monthlyWorkHours: 98.5,
                accruedWorkHours: 98.5,
                workingDays: 3
            ),
            isExpected: false,
            showsNightAllowance: true,
            showsHolidayAllowance: true
        )
    }
}
