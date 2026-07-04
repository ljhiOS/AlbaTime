//
//  SwiftUIView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/29/25.
//

import SwiftUI

// TODO: 나중에 로그인 기능 추가 시 알람에서 계정으로 Text 변경
struct AccountDetail: View {
    @AppStorage("isAppAlarmOn") var isAppAlarmOn: Bool = true
    let workPlaces: [WorkPlace]
    @ObservedObject var viewModel: AccountDetailViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("알람")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top)
            
            HStack {
                // 1. 아이콘
                Image(systemName: isAppAlarmOn ? "bell.fill" : "bell.slash.fill") // 켜짐/꺼짐 아이콘 변경
                    .foregroundStyle(isAppAlarmOn ? Color.theme.primary : .gray)
                
                // 2. 텍스트
                Text("알림설정")
                    .foregroundStyle(Color.theme.textPrimary)
                
                Spacer()
                
                // 3. 토글 스위치 (여기가 핵심!)
                Toggle("", isOn: $isAppAlarmOn)
                    .labelsHidden() // 토글 옆의 빈 라벨 공간 숨기기
                    .tint(Color.theme.primary)    // 스위치 켰을 때 색상
                    .onChange(of: isAppAlarmOn) { oldValue, newValue in
                        viewModel.toggleAppAlarm(
                            isEnabled: newValue,
                            workPlaces: workPlaces
                        )
                    }
            }
            .padding()
            .background(Color.theme.field)
            .cornerRadius(20)
            
        }
    }
}

#Preview {
    AccountDetail(
        workPlaces: [],
        viewModel: AccountDetailViewModel(
            appAlarmToggling: PreviewAppAlarmToggling()
        )
    )
}

@MainActor
private struct PreviewAppAlarmToggling: AppAlarmToggling {
    func execute(isEnabled: Bool, workPlaces: [WorkPlace]) { }
}
