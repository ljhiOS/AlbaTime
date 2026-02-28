//
//  PayCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/15/25.
//

import SwiftUI

struct PayCard: View {
    
    var totalPay: Int
    var totalHours: Double
    var averageWage: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Text("이번 달 누적 급여")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.top)
            
                Text("\(totalPay.formatted())원")
                    .foregroundStyle(.yellow)
                    .font(.title)
                    .bold()
            }.padding(.horizontal)
            
            Divider()
                .frame(height: 1)
                .background(Color.white)
                .padding(.horizontal)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("총 근무 시간")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text(String(format: "%.1f시간", totalHours))
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("평균 시급")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text("\(averageWage.formatted())원")
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .bold(true)
                }
                
                Spacer()
            }.padding()
        }.background(Color.theme.primary)
            .frame(maxWidth: .infinity)
            .cornerRadius(20)
    }
}

#Preview {
    PayCard(
        totalPay: 1143220,    // 임시 급여 데이터
        totalHours: 108.5,    // 임시 시간 데이터
        averageWage: 10530    // 임시 평균 시급
    )
    .padding() // 프리뷰에서 여백을 두어 보기 좋게 설정
}
