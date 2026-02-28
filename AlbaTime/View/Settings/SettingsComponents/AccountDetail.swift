//
//  SwiftUIView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/29/25.
//

import SwiftUI
import SwiftData

struct AccountDetail: View {
    @AppStorage("isAppAlarmOn") var isAppAlarmOn: Bool = true
    @Query var workplaces: [Workplace]
    var body: some View {
        VStack(alignment: .leading) {
            Text("계정")
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
                           if newValue {
                               print("앱 알림 허용")
                               for place in workplaces {
                                   // 기존에 알림 켜둔 알바처만 다시 등록
                                   if place.isAlarmEnabled {
                                       NotificationManager.shared.refreshNotifications(for: place)
                                   }
                               }
                           } else {
                               print("앱 알림 해제")
                               NotificationManager.shared.removeAllNotifications()
                           }
                       }
            }
            .padding()
            .background(Color.theme.field)
            .cornerRadius(20)
            
        }
    }
}

#Preview {
    AccountDetail()
}
