//
//  ScheduleImportEmptyView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct ScheduleImportEmptyView: View {
    @Binding var myName: String
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("표에 적힌 내 이름 (선택)")
                    .font(.caption).foregroundStyle(.gray).padding(.leading, 4)
                TextField("예: 홍길동 (비워두면 전체 인식)", text: $myName)
                    .textFieldStyle(.roundedBorder)
            }
            .frame(maxWidth: 300)
            .padding()
            
            ContentUnavailableView("",
                systemImage: "photo.badge.arrow.down",
                description: Text("우측 상단 앨범 버튼을 눌러\n근무표 사진을 선택하면 자동으로 분석합니다.")
            )
            
            Button { dismiss() } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("인식이 잘 안 되나요? 수기로 입력하기")
                }
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Color.theme.primary)
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color.theme.primary.opacity(0.1)).cornerRadius(10)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @Environment(\.dismiss) var dismiss
        @State var name = ""
        
        var body: some View {
            ScheduleImportEmptyView(myName: $name, dismiss: dismiss)
        }
    }
    
    return PreviewWrapper()
}
