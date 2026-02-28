//
//  HeaderView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct HeaderView: View {
    let title: String
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title)
                .bold()
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title)
                    .foregroundStyle(Color.theme.textPrimary)
            }
        }.padding()
    }
}

// DismissAction을 테스트하기 위한 래퍼 뷰
struct HeaderView_PreviewWrapper: View {
    @Environment(\.dismiss) var dismiss // 환경 변수에서 dismiss 가져오기
    
    var body: some View {
        HeaderView(title: "알바 등록", dismiss: dismiss)
    }
}

#Preview {
    HeaderView_PreviewWrapper()
}
