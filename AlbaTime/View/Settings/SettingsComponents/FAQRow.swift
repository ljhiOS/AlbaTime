//
//  FAQRow.swift
//  AlbaTime
//
//  Created by 이준희 on 1/13/26.
//

import SwiftUI

struct FAQRow: View {
    let faq: FAQItem
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Q.")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.primary)
                    
                    Text(faq.question)
                        .fontWeight(.medium)
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0)) // 회전 애니메이션
                }
                .padding()
                .background(Color.white)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    HStack(alignment: .top) {
                        Text("A.")
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        Text(faq.answer)
                            .foregroundStyle(.gray)
                            .font(.callout)
                            .lineSpacing(4) // 줄 간격
                    }
                    .padding()
                }
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top))) // 등장효과 이펙트
            }
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    FAQRow(faq: FAQItem.init(question: "1", answer: "1"))
}
