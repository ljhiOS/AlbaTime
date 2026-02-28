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
            answer: "주휴수당은 일주일 동안 15시간 이상 근무했을 때 발생합니다.\n\n계산식: (1주 근무시간 / 40) × 8 × 시급\n\nAlbaTime은 저장된 근무 시간을 바탕으로 주 15시간이 넘는지 자동으로 체크하여 계산해 줍니다."
        ),
        
        FAQItem(
            question: "야간 수당 기준이 궁금해요.",
            answer: "밤 10시(22:00)부터 다음 날 오전 6시(06:00) 사이의 근무에 대해서는 통상 임금의 1.5배(0.5배 가산)가 적용됩니다.\n\n근무지 설정에서 시간을 입력하면 자동으로 야간 근무 시간을 발라내어 계산합니다."
        ),
        
        FAQItem(
            question: "이번달 누적 금액이 실제 급여와 달라요.",
            answer: "위 금액은 입력된 근무 시간을 기준으로 계산된 단순 참고용이며, 실제 급여와 차이가 발생할 수 있습니다."
        ),
        
        FAQItem(
            question: "알림이 울리지 않아요.",
            answer: "설정 > 알림 설정에서 '알림 받기'가 켜져 있는지 확인해 주세요.\n\n또한 아이폰 설정 > 알림 > AlbaTime에서 알림 권한이 허용되어 있어야 정상적으로 작동합니다."
        ),
        
        FAQItem(
            question: "근무지를 삭제하고 싶어요.",
            answer: "근무지 목록 화면의 오른쪽 상단에 있는 [편집] 버튼(또는 아이콘)을 눌러주세요. 버튼을 누르면 각 근무지 옆에 **삭제 버튼(-)**이 나타납니다. \n\n(실수로 기록이 삭제되는 것을 방지하기 위해 스와이프 기능 대신 편집 버튼을 사용하고 있어요!)"
        ),
        
        FAQItem(
            question: "데이터는 안전한가요?",
            answer: "네, 모든 데이터는 서버가 아닌 고객님의 아이폰 내부에만 저장됩니다. 앱을 삭제하면 데이터도 함께 삭제되니 주의해 주세요."
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
