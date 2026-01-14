//
//  RealAchivePay.swift
//  AlbaTime
//
//  Created by 이준희 on 12/15/25.
//

import SwiftUI

struct RealAchivePay: View {
    
    var body: some View {
        NavigationLink(destination: RealAchiveRecord()) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("월별 수령액")
                        .font(.headline)
                        .foregroundStyle(.black)
                    
                    Text("실제 입금된 급여를 기록하세요")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.theme.primary)
            }
            .padding(20)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(20)
        }
        .buttonStyle(.plain) // 버튼 깜빡임 방지 및 자연스러운 터치감
    }
}

#Preview {
    NavigationStack{
        
        ZStack {
            Color.gray.opacity(0.1).ignoresSafeArea()
            RealAchivePay()
                .padding()
        }
    }
}
