//
//  ScheduleImportEmptyView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct ScheduleImportEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            ContentUnavailableView("",
                systemImage: "photo.badge.arrow.down",
                description: Text("우측 상단 앨범 버튼을 눌러\n근무표 사진을 선택하면 자동으로 분석합니다.")
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ScheduleImportEmptyView()
}
