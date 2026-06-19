//
//  ScheduleImportLoadingView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct ScheduleImportLoadingView: View {
    let targetName: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.5)
            Text("AI가 '\(targetName.isEmpty ? "전체" : targetName)' 스케줄을 찾는 중...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.surface)
    }
}

#Preview {
    ScheduleImportLoadingView(targetName: "준희")
}
