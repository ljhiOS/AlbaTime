//
//  BottomButton.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct BottomButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        VStack {
            Button(action: action) {
                Text(title)
                    .bold()
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.theme.primary)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .shadow(radius: 2)
            }
        }
        .padding(.vertical)
        .background(Color.theme.surface)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -5)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea() // 배경색 깔아서 그림자 확인
        
        VStack {
            Spacer()
            BottomButton(title: "저장하기") {
                print("버튼 클릭됨")
            }
        }
    }
}
