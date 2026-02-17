//
//  MainTabView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct MainTabView: View {
    
    
    
    var body: some View {
        TabView {
            // 1번 탭: 캘린더
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("캘린더")
            }
            
            // 2번 탭: 근무지 관리
            NavigationStack {
                JobListView()
            }
            .tabItem {
                Image(systemName: "briefcase.fill")
                Text("근무지")
            }
            
            // 3번 탭: 급여
            NavigationStack {
                PayDashboardView()
            }
            .tabItem {
                Image(systemName: "wonsign.circle.fill")
                Text("급여")
            }
            
            // 4번 탭: 설정
            NavigationStack {
                SettingView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("설정")
            }
        }
        .tint(Color.theme.primary) // 탭 선택 색상
    }
}

#Preview {
    MainTabView()
}
