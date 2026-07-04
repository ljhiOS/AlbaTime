//
//  SettingView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct SettingView: View {
    let workPlaces: [WorkPlace]
    @StateObject private var accountViewModel: AccountDetailViewModel

    init(
        workPlaces: [WorkPlace],
        accountViewModel: AccountDetailViewModel
    ) {
        self.workPlaces = workPlaces
        _accountViewModel = StateObject(wrappedValue: accountViewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("설정")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                Spacer()
            }
            
            
            
            AccountDetail(
                workPlaces: workPlaces,
                viewModel: accountViewModel
            )
                .padding(.horizontal)
            
            ServiceDetail()
                .padding(.horizontal)
            Spacer()
            
            VStack(alignment: .center) {
                
                Text("알바타임")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("알바생 맞춤 출퇴근 스케줄러 & 급여계산기")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Copyright © 2026 알바타임.\nAll rights reserved.")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }.padding()
            
        }
        .background(Color.theme.surface)
    }
}

#Preview {
    NavigationStack {
        SettingView(
            workPlaces: [],
            accountViewModel: AccountDetailViewModel(
                appAlarmToggling: PreviewSettingAppAlarmToggling()
            )
        )
    }
}

@MainActor
private struct PreviewSettingAppAlarmToggling: AppAlarmToggling {
    func execute(isEnabled: Bool, workPlaces: [WorkPlace]) { }
}
