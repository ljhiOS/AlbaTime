//
//  CustomButton.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct CustomButton: View {
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ingButtonStyle2: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.25 : 1.0)
            .animation(.easeInOut(duration: 0.05), value: configuration.isPressed)
    }
}

// 점선 색깔 바꾸기 위한 버튼 스타일 커스텀 및 사용자 UX 고려 버튼 터치시 작아지는 애니메이션 기능 첨가
struct ingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(35)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(configuration.isPressed ? Color.theme.primary : .gray)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .padding()
    }
}


struct PlusButton: View {
    
    // 밖에서 버튼을 눌렀을 때 실행할 행동을 전달받습니다.
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .foregroundStyle(.gray.opacity(0.08))
                        .overlay (
                            Image(systemName: "plus")
                                .foregroundStyle(Color.theme.primary)
                        )
                        .frame(width: 50, height: 50)
                }
                
                Text("새 알바 추가하기")
                    .foregroundStyle(.gray)
            }
        }
        .buttonStyle(ingButtonStyle())
    }
}

#Preview("customButton") {
    CustomButton()
}

#Preview("PlusButton") {
    PlusButton{print("버튼 눌림")}
}
