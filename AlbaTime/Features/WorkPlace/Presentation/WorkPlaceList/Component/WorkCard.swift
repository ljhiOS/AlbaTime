//
//  WorkCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct WorkCard: View {
    let state: WorkPlaceCardViewState

    var onDelete: () -> Void
    var onPin: () -> Void
    var onToggleAlarm: () -> Void
    var onShowDetail: () -> Void
    var onShowEdit: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.theme.field : Color.theme.surface
    }

    @Environment(\.analyticsTracker) private var analyticsTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // 1. [상단 영역] 이름(좌) vs 시급+메뉴(우)
            HStack(alignment: .top) {
                // (좌) 가게 이름
                HStack(spacing: 8) {
                    Text(state.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .truncationMode(.tail)
                }

                Spacer()

                // (우) 시급 + 메뉴 버튼
                HStack {
                    Text("시급")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("₩\(state.hourlyWage)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    // 점 3개 메뉴
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.title2)
                        .foregroundColor(Color.theme.primary)
                        .overlay {
                            Menu {
                                Button { onPin() } label: {
                                    Label(state.isPinned ? "고정 해제" : "상단 고정", systemImage: state.isPinned ? "pin.slash" : "pin")
                                }
                                Button(role: .destructive) { onDelete() } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                                Button {
                                    onToggleAlarm()
                                } label: {
                                    Label(state.isAlarmEnabled ? "알람 해제" : "알람 허용", systemImage: state.isAlarmEnabled ? "bell.slash" : "bell")
                                }
                            } label: {
                                Color.clear.frame(width: 44, height: 44)
                            }
                        }
                }
                .layoutPriority(1)
            }

            // 2. 구분선
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3))

            // 3. [정보 영역] 아이콘 + 그룹화된 스케줄 텍스트
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "clock")
                    .foregroundColor(.gray)

                // 요일 순으로 정렬된 스케줄 텍스트
                Text(state.scheduleSummary)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            // 4. [버튼 영역]
            HStack(spacing: 10) {
                Button {
                    onShowDetail()
                } label: {
                    Text("상세보기")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(Color.theme.textPrimary)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.theme.surface).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.theme.borderSoft, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .spotlightTarget(.workPlaceListDetailButton)

                Button {
                    onShowEdit()
                    analyticsTracker.track(.workplaceEdit)
                } label: {
                    Text("근무 수정")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.theme.primary).cornerRadius(8)
                }
                .buttonStyle(.plain)
                .spotlightTarget(.workPlaceListEditButton)
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.088), radius: 10, x: 0, y: 7)
    }
}

#Preview {
    let state = WorkPlaceCardViewState(
        id: UUID(),
        name: "GS25 강남점",
        hourlyWage: 10030,
        isPinned: false,
        isAlarmEnabled: true,
        scheduleSummary: "월/수/금: 09:00 ~ 18:00"
    )
    return WorkCard(state: state, onDelete: {}, onPin: {}, onToggleAlarm: {}, onShowDetail: {}, onShowEdit: {})
}
