//
//  HelpView.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct HelpView: View {
    
    // 자주 묻는 질문 데이터
    let faqs: [FAQItem] = [
        FAQItem(
            question: "AI 스케줄 등록은 어떻게 하나요?",
            answer: "근무지 추가(또는 수정) 화면의 오른쪽 상단에 있는 [AI 스케줄] 아이콘을 눌러주세요.\n\n사진첩에서 근무표 사진을 선택하면, AI가 자동으로 날짜와 시간을 인식하여 등록해줍니다. (사진이 선명할수록 인식률이 올라가요!)"
        ),
        
        FAQItem(
            question: "AI가 날짜를 잘못 인식했어요.",
            answer: "손글씨나 흐릿한 사진의 경우 인식이 정확하지 않을 수 있습니다. \n\nAI가 불러온 결과 화면에서 잘못된 시간은 터치하여 직접 수정할 수 있으니, 저장하기 전에 꼭 확인해 주세요."
        ),
        
        FAQItem(
            question: "주휴수당은 어떻게 계산되나요?",
            answer: "주휴수당은 1주일 동안 15시간 이상 근무했을 때 발생합니다.\n\n계산식: (1주 근무시간 / 40) × 8 × 시급\n\n알바타임은 근무지 등록 시 주휴수당 적용을 선택한 경우에만 주휴수당을 계산합니다."
        ),

        FAQItem(
            question: "야간 수당 기준이 궁금해요.",
            answer: "야간수당은 밤 10시(22:00)부터 다음 날 오전 6시(06:00) 사이 근무에 대해 통상임금의 1.5배(0.5배 가산)가 적용됩니다.\n\n알바타임은 근무지 등록 시 야간수당 적용을 선택한 경우에만 계산합니다."
        ),
        
        FAQItem(
            question: "이번달 누적 금액 및 월 예상 금액이 실제 급여와 달라요.",
            answer: "위 금액은 입력된 근무 시간을 기준으로 계산된 단순 참고용이며, 실제 급여와 차이가 발생할 수 있습니다. \n또한 카드를 터치하면 누적 급여와 월 예상 급여를 전환해 볼 수 있습니다."
        ),
        
        FAQItem(
            question: "알림이 울리지 않아요.",
            answer: "설정 > 알림 설정에서 '알림 받기'가 켜져 있는지 확인해 주세요.\n\n또한 아이폰 설정 > 알림 > 알바타임에서 알림 권한이 허용되어 있어야 정상적으로 작동합니다."
        ),
        
        FAQItem(
            question: "근무지를 삭제하고 싶어요.",
            answer: "근무지 카드의 오른쪽 상단에 있는 세로 점 3개(⋮) 더보기 버튼을 눌러주세요. 메뉴에서 [삭제]를 선택하면 됩니다. \n\n(실수로 기록이 삭제되는 것을 방지하기 위해 스와이프 기능 대신 편집 버튼을 사용하고 있어요!)"
        ),
        
        FAQItem(
            question: "데이터는 안전한가요?",
            answer: "모든 데이터는 서버가 아닌 고객님의 아이폰 내부에만 저장됩니다. 앱을 삭제하면 데이터도 함께 삭제되니 주의해 주세요."
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 1. 상단 안내 문구
                VStack(spacing: 8) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.theme.primary)
                        .padding(.bottom, 8)
                    
                    Text("무엇을 도와드릴까요?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("자주 묻는 질문들을 모아봤어요.")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .padding(.top, 20)
                
                // 2. FAQ 리스트 (아코디언 스타일)
                VStack(spacing: 16) {
                    ForEach(faqs) { faq in
                        FAQRow(faq: faq)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 10)
                
                // 3. 해결이 안 되었나요? (문의하기 연결)
                VStack(spacing: 16) {
                    Text("원하는 답변을 찾지 못하셨나요?")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                    
                    Button {
                        openKakaoChat()
                    } label: {
                        HStack {
                            Image(systemName: "bubble.right.fill")
                            Text("개발자에게 직접 물어보기")
                        }
                        .fontWeight(.medium)
                        .foregroundStyle(Color.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .systemYellow))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("도움말")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.theme.surface)
    }
    
    // 카카오톡 열기
    private func openKakaoChat() {
        let kakaoUrl = "https://open.kakao.com/o/sMuoCVai"
        if let url = URL(string: kakaoUrl) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    HelpView()
}
