//
//  PayCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/15/25.
//

import SwiftUI

struct PayCard: View {
    
    var totalPay: Int
    var expectedPay: Int
    var totalHours: Double
    var averageWage: Int
    var onToggle: (() -> Void)? = nil
    
    @State private var showExpected: Bool = false
    @State private var headerOffsetY: CGFloat = 0
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Text(showExpected ? "이번 달 예상 급여" : "이번 달 누적 급여")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.top)
            
                Text("\((showExpected ? expectedPay : totalPay).formatted())원")
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
    PayCard(
        totalPay: 1143220,    // 임시 급여 데이터
        expectedPay: 115000,
        totalHours: 108.5,    // 임시 시간 데이터
        averageWage: 10530    // 임시 평균 시급
    )
    .padding() // 프리뷰에서 여백을 두어 보기 좋게 설정
}
