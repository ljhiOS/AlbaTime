//
//  ScheduleImportBottomButtons.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct ScheduleImportBottomButtons: View {
    let isSaveDisabled: Bool
    let onSave: () -> Void
    let onManualInput: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 저장하기 버튼
            Button {
                onSave()
            } label: {
                Text("저장하기")
                    .font(.headline).bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isSaveDisabled
                        ? Color.theme.disabled
                        : Color.theme.primary
                    )
                    .cornerRadius(12)
            }
            .disabled(isSaveDisabled)
            
            // 취소 버튼
            Button {
                onManualInput()
            } label: {
                Text("취소하고 수기로 입력하기")
                    .font(.subheadline).bold()
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(Color.theme.surface)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}

#Preview("Bottom Buttons") {
    return VStack {
        Spacer()

        ScheduleImportBottomButtons(
            isSaveDisabled: false,
            onSave: {},
            onManualInput: {}
        )
    }
}
