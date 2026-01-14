//
//  PayDetailCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/15/25.
//

import SwiftUI

struct PayDetailCard: View {
    // 외부에서 데이터를 받도록 변수 추가
    var basicPay: Int
    var nightPay: Int
    var overtimePay: Int
    var holidayPay: Int
    var taxAmount: Int
    var totalPay: Int
    var totalHours: Double
    var workingDays: Int
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("급여 상세")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.bottom, 10)
            
            HStack(alignment: .top) {
                Text("예상 근무 일수")
                    .font(.body)
                    
                Spacer()
                Text("\(workingDays)일")
                    .font(.body)
                    .bold()
            }
            
            // 기본 급여
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("기본 급여")
                        .font(.body)
                    Text("\(String(format: "%.1f", totalHours))시간")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("₩\(basicPay.formatted())")
                    .font(.body)
            }
            
            // 야간 수당
            if nightPay > 0 {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("야간 수당")
                            .font(.body)
                        Text("야간 시간 x 1.5")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("₩\(nightPay.formatted())")
                        .font(.body)
                }
            }
            
            if overtimePay > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("연장 수당") // 8시간 초과분
                            .font(.body)
                        Text("근무 시간 8시간 초과")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("₩\(overtimePay)")
                        .font(.body)
                }
            }
            
            // 주휴 수당
            if holidayPay > 0 {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("주휴 수당")
                            .font(.body)
                        Text("조건 충족")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("₩\(holidayPay.formatted())")
                        .font(.body)
                }
            }
            
            if taxAmount > 0 {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("세금 공제")
                                        .font(.body)
                                        .foregroundColor(.red)
                                    Text("예상 공제액")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("- ₩\(taxAmount.formatted())")
                                    .font(.body)
                                    .foregroundColor(.red)
                            }
                        }
            
            Divider()
                .padding(.vertical, 5)
            
            // 총 합계
            HStack {
                Text("총 합계")
                    .fontWeight(.semibold)
                Spacer()
                Text("₩\(totalPay.formatted())")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.primary)
            }
        }
        .padding(24)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(20)
    }
}

#Preview {
    ZStack {
        PayDetailCard(
            basicPay: 960000,   
            nightPay: 50000,
            overtimePay: 30000,
            holidayPay: 35000,
            taxAmount: 90000,
            totalPay: 1045000,
            totalHours: 98.5,
            workingDays: 3
        )
    }
}
