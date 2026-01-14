//
//  WorkCardView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct WorkCard: View {
    
    let job: Workplace
    
    var onDelete: () -> Void
    var onPin: () -> Void
    
    @State var isDetailShowing: Bool = false
    @State var isShiftShowing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. [상단 영역] 이름(좌) vs 시간정보(우)
            HStack(alignment: .top) {
                // (좌) 가게 이름
                HStack(spacing: 8) {
                    Text(job.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
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
                    
                    Text("₩\(job.hourlyWage)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    // 점 3개 메뉴 (터치 영역 확장 적용됨)
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.title2)
                        .foregroundColor(Color.theme.primary)
                        .overlay {
                            Menu {
                                Button {
                                    onPin()
                                } label: {
                                    Label(job.isPinned ? "고정 해제" : "상단 고정",
                                          systemImage: job.isPinned ? "pin.slash" : "pin")
                                }
                                
                                Button(role: .destructive) {
                                    onDelete()
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                                
                                Button {
                                    job.isAlarmEnabled.toggle()
                                    
                                    // 2. 실제 시스템 알림 동기화
                                    if job.isAlarmEnabled {
                                        NotificationManager.shared.scheduleWorkNotification(for: job)
                                        print("🔔 \(job.name) 알림 ON")
                                    } else {
                                        NotificationManager.shared.removeNotifications(for: job)
                                        print("🔕 \(job.name) 알림 OFF")
                                    }
                                    
                                    // 햅틱 피드백
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                } label: {
                                    Label(job.isAlarmEnabled ? "알람 해제" : "알람 허용",
                                          systemImage: job.isAlarmEnabled ? "bell.slash" : "bell")
                                }
                            } label: {
                                // 투명 터치 영역
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                        }
                }
                .layoutPriority(1) // 우측 정보가 밀리지 않도록 우선순위 높임
            }
            
            // 2. 구분선 (Rectangle로 교체하여 잘 보이게 수정)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3))
            
            // 3. [정보 영역] 아이콘 + 텍스트
            VStack(alignment: .leading, spacing: 8) {
                // 시간 정보
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text("\(job.defaultDays) \(job.defaultStartTime.format("HH:mm"))-\(job.defaultEndTime.format("HH:mm"))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            // 4. [버튼 영역]
            HStack(spacing: 10) {
                // 상세보기 버튼
                Button {
                    isDetailShowing = true
                    print("상세보기 클릭")
                } label: {
                    Text("상세보기")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .sheet(isPresented: $isDetailShowing) {
                    DetailView(job: job)
                }
                .buttonStyle(.plain)
                
                // 근무 수정 버튼
                Button {
                    isShiftShowing = true
                    print("근무 수정 클릭")
                } label: {
                    Text("근무 수정")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.theme.primary)
                        .cornerRadius(8)
                }
                .sheet(isPresented: $isShiftShowing) {
                    WorkEditView(job: job)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.088), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    WorkCard(job: Workplace(
        name: "GS25 강남점",
        hourlyWage: 10030,
        defaultDays: "월,수,금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0)
    ), onDelete: {
        print("삭제")
    }, onPin: {
        print("상단 고정")
    })
}
