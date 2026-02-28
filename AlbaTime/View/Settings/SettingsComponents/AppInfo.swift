//
//  AppInfo.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import SwiftUI

struct AppInfo: View {
    
    // 앱 버전 가져오기
    private var appVersion: String {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String else { return "1.0.0" }
        return version
    }
    
    // 카카오톡 오픈채팅 열기 기능
    private func openKakaoChat() {
        let kakaoUrl = "https://open.kakao.com/o/sMuoCVai"
        
        if let url = URL(string: kakaoUrl) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                
                // 1. 앱 로고 및 버전 정보
                VStack(spacing: 16) {
                    Image(uiImage: UIImage(named: "AppIconImage") ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 6) {
                        Text("AlbaTime")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("v\(appVersion)")
                            .font(.body)
                            .foregroundColor(.gray)
                            .onLongPressGesture {
                                // 버전 꾹 누르면 복사
                                UIPasteboard.general.string = appVersion
                            }
                    }
                }
                .padding(.top, 40)
                
                // 2. 카카오톡 문의하기 버튼
                Button {
                    openKakaoChat()
                } label: {
                    HStack(spacing: 12) {
                        // 말풍선 아이콘
                        Image(systemName: "bubble.right.fill")
                            .font(.title3)
                        
                        Text("카카오톡으로 문의하기")
                            .font(.headline)
                    }
                    .foregroundColor(Color.theme.textPrimary) // 글자색
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(uiColor: .systemYellow)) // 카카오톡 노란색 느낌
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 3. 하단 저작권 표시
                VStack {
                    Text("AlbaTime")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("알바생 맞춤 출퇴근 스케줄러 & 급여계산기")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Copyright © 2026 AlbaTime.\nAll rights reserved.")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("앱 정보")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let content: String?
    var showArrow: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 아이콘 박스
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.theme.textPrimary)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(Color.theme.textPrimary)
            
            Spacer()
            
            if let content = content {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    AppInfo()
}
