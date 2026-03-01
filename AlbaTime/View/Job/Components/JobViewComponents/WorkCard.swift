//
//  WorkCard.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct WorkCard: View {
    
    
    let job: Workplace
    
    var onDelete: () -> Void
    var onPin: () -> Void
    var onShowDetail: () -> Void
    var onShowEdit: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.theme.field : Color.theme.surface
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. [상단 영역] 이름(좌) vs 시급+메뉴(우)
            HStack(alignment: .top) {
                // (좌) 가게 이름
                HStack(spacing: 8) {
                    Text(job.name)
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
                    
                    Text("₩\(job.hourlyWage)")
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
                                    Label(job.isPinned ? "고정 해제" : "상단 고정", systemImage: job.isPinned ? "pin.slash" : "pin")
                                }
                                Button(role: .destructive) { onDelete() } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                                Button {
                                    job.isAlarmEnabled.toggle()
                                    NotificationManager.shared.refreshNotifications(for: job)
                                    try? job.modelContext?.save()
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                } label: {
                                    Label(job.isAlarmEnabled ? "알람 해제" : "알람 허용", systemImage: job.isAlarmEnabled ? "bell.slash" : "bell")
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
                    .padding(.top, 2)
                
                // 요일 순으로 정렬된 스케줄 텍스트
                Text(getUnifiedScheduleText())
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
                
                Button {
                    onShowEdit()
                } label: {
                    Text("근무 수정")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.theme.primary).cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.088), radius: 10, x: 0, y: 7)
    }
        
    // MARK: - Logic (스케줄 텍스트 표시)
        
    private func getUnifiedScheduleText() -> String {
        // [A] 자율 근무 (Flexible)
        if job.workType == .flexible {
            let count = job.targetWeeklyCount ?? 0
            let hours = job.expectedDailyHours ?? 0
            return "주 \(count)회 / 일 평균 \(String(format: "%.1f", hours))시간"
        }
        
        // [B] 고정 근무 (Fixed) - 기존 로직 유지 (요구사항 3)
        else {
            var timeGroups: [String: Set<String>] = [:]
            
            for schedule in job.regularSchedules {
                let timeStr = "\(formatTime(schedule.startTime)) ~ \(formatTime(schedule.endTime))"
                timeGroups[timeStr, default: []].insert(schedule.dayOfWeek)
            }
            
            if timeGroups.isEmpty && !job.defaultDays.isEmpty {
                let start = formatTime(job.defaultStartTime)
                let end = formatTime(job.defaultEndTime)
                return "\(job.defaultDays): \(start) ~ \(end)"
            }
            
            if timeGroups.isEmpty { return "설정된 근무가 없습니다" }
            
            return formatGroupsToText(timeGroups)
        }
    }
    
    // 공통: 그룹화된 데이터를 텍스트로 변환 (월,화,수 정렬 포함)
    private func formatGroupsToText(_ groups: [String: Set<String>]) -> String {
        let dayOrder = ["월", "화", "수", "목", "금", "토", "일"]
        
        let sortedLines = groups.compactMap { (time, daysSet) -> (String, Int)? in
            // 요일 내부 정렬 (월,수,금)
            let sortedDays = daysSet.sorted {
                (dayOrder.firstIndex(of: $0) ?? 99) < (dayOrder.firstIndex(of: $1) ?? 99)
            }
            guard let firstDay = sortedDays.first else { return nil }
            
            // 줄 정렬 기준 (가장 빠른 요일)
            let sortIndex = dayOrder.firstIndex(of: firstDay) ?? 99
            
            let text = "\(sortedDays.joined(separator: "/")): \(time)"
            return (text, sortIndex)
        }
        
        return sortedLines
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
            .joined(separator: "\n")
    }
    
    private func formatTime(_ date: Date) -> String {
        return date.time24h
    }
}

#Preview {
    let job = Workplace(
        name: "GS25 강남점",
        hourlyWage: 10030,
        defaultDays: "",
        defaultStartTime: Date(),
        defaultEndTime: Date()
    )
    return WorkCard(job: job, onDelete: {}, onPin: {}, onShowDetail: {}, onShowEdit: {})
}
