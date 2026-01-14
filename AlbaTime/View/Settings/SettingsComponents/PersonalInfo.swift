//
//  personalInfo.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import SwiftUI

struct PersonalInfo: View {
    @Environment(\.dismiss) var dismiss
    
    // 날짜 포맷터 (오늘 날짜 기준)
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 1. 헤더 영역
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                        .padding(.bottom, 4)
                    
                    Text("AlbaTime\n개인정보처리방침")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("최종 수정일: 2026년 1월 11일")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // 2. 본문 카드 리스트
                VStack(spacing: 16) {
                    
                    // 서문
                    PolicySectionView(
                        title: "개요",
                        content: "'AlbaTime'(이하 '본 앱')은 사용자의 개인정보를 소중히 여기며, 『개인정보 보호법』 등 관련 법령을 준수합니다. 본 앱은 별도의 서버를 운영하지 않으며, 사용자의 기기에 저장된 데이터를 외부로 전송하거나 수집하지 않습니다."
                    )
                    
                    // 1. 수집 항목
                    PolicySectionView(
                        title: "1. 수집하는 개인정보 항목",
                        content: "본 앱은 회원가입 절차가 없으며, 사용자의 어떠한 개인정보(이름, 연락처, 기기 정보 등)도 수집하거나 서버로 전송하지 않습니다."
                    )
                    
                    // 2. 저장 및 관리
                    PolicySectionView(
                        title: "2. 데이터의 저장 및 관리",
                        content: "본 앱을 통해 입력한 모든 데이터(근무지 정보, 급여 내역, 근무 기록 등)는 사용자의 스마트폰 내부 저장소(SwiftData/CoreData)에만 암호화되어 저장됩니다.\n\n앱을 삭제할 경우 해당 데이터는 기기에서 즉시 영구적으로 삭제되며 복구할 수 없습니다."
                    )
                    
                    // 3. 권한 안내
                    PolicySectionView(
                        title: "3. 권한 사용 안내",
                        content: "본 앱은 기능 수행을 위해 최소한의 권한만을 요청합니다.\n\n• 알림(Notifications): 사용자가 설정한 출근 시간 알림을 발송하기 위해 사용됩니다. 이 알림은 기기 내부에서만 작동하며 외부로 정보를 보내지 않습니다."
                    )
                    
                    // 4. 문의처
                    ContactSectionView()
                }
                .padding(.horizontal)
                
                // 하단 여백
                Spacer().frame(height: 50)
            }
        }
        .navigationTitle("개인정보처리방침")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground)) // 설정 화면과 비슷한 배경색
    }
}

// 🎨 재사용 가능한 정책 섹션 카드 디자인
struct PolicySectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
            
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .lineSpacing(4) // 줄 간격 늘려서 가독성 확보
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// 📧 문의처 섹션 (이메일 복사 기능 포함)
struct ContactSectionView: View {
    let email = "ljh230c@naver.com"
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("4. 문의처")
                .font(.headline)
                .foregroundStyle(.black)
            
            Text("본 앱의 개인정보 처리와 관련하여 문의사항이 있으신 경우 아래 연락처로 문의해 주시기 바랍니다.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .lineSpacing(4)
            
            Divider()
            
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(Color.theme.primary)
                
                Text(email)
                    .font(.callout)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = email
                    isCopied = true
                    
                    // 2초 뒤 복사 완료 표시 원복
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                } label: {
                    Text(isCopied ? "복사됨" : "복사")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(isCopied ? .green : Color.theme.primary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(isCopied ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    PersonalInfo()
}
