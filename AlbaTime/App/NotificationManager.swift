import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    
    // 알림 권한 요청
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("알림 권한 오류:", error.localizedDescription)
            }
            print("알림 권한 상태:", granted)
        }
    }
    
    // 출근 15분 전 알림 스케줄
    func scheduleWorkNotification(for workplace: Workplace) {
        print("🚨 scheduleWorkNotification CALLED")
        removeNotifications(for: workplace)
        
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        let dayStrings = workplace.defaultDays.components(separatedBy: "/")
        
        // iOS 기준 요일 매핑 (일=1)
        let weekdayMap: [String: Int] = [
            "일": 1,
            "월": 2,
            "화": 3,
            "수": 4,
            "목": 5,
            "금": 6,
            "토": 7
        ]
        
        for dayString in dayStrings {
            guard let weekday = weekdayMap[dayString] else { continue }
            
            // 이번 주 기준 요일 + 출근 시간
            var components = calendar.dateComponents(
                [.year, .month, .weekOfYear],
                from: Date()
            )
            components.weekday = weekday
            
            let timeComponents = calendar.dateComponents(
                [.hour, .minute],
                from: workplace.defaultStartTime
            )
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            guard let workDate = calendar.date(from: components) else { continue }
            
            // 이미 지났으면 다음 주로 보정
            let adjustedWorkDate: Date
            if workDate < Date() {
                adjustedWorkDate = calendar.date(byAdding: .weekOfYear, value: 1, to: workDate)!
            } else {
                adjustedWorkDate = workDate
            }
            
            // 15분 전
            guard let triggerDate = calendar.date(
                byAdding: .minute,
                value: -15,
                to: adjustedWorkDate
            ) else { continue }
            
            // 알림 트리거 (단발)
            let triggerComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: triggerComponents,
                repeats: true
            )
            
            // 알림 내용
            let content = UNMutableNotificationContent()
            content.title = "출근 15분 전"
            content.body = "\(workplace.name) 출근 준비하세요!"
            content.sound = .default
            
            let identifier = "\(workplace.id.uuidString)_\(weekday)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("❌ 알림 등록 실패:", error.localizedDescription)
                } else {
                    print("✅ 알림 등록:", dayString)
                    if let next = trigger.nextTriggerDate() {
                        print("   → 울리는 시간:", next.formatted())
                    }
                }
            }
        }
    }
    
    // 기존 알림 삭제
    func removeNotifications(for workplace: Workplace) {
        let center = UNUserNotificationCenter.current()
        let identifiers = (1...7).map {
            "\(workplace.id.uuidString)_\($0)"
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // 모든 알람 허용 X
    func removeAllNotifications() {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("모든 알림 허용의 해제")
        }
    
    // 디버깅용
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 예약된 알림 \(requests.count)개")
            for req in requests {
                if let trigger = req.trigger as? UNCalendarNotificationTrigger,
                   let date = trigger.nextTriggerDate() {
                    print("• \(req.identifier) → \(date.formatted())")
                }
            }
        }
    }
}
