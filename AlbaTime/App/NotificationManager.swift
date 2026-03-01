import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    private let appAlarmKey = "isAppAlarmOn"
    
    private struct WorkplaceNotificationSnapshot {
        struct FixedEntry {
            let weekday: Int
            let hour: Int
            let minute: Int
        }
        
        let id: String
        let name: String
        let workType: WorkType
        let isAlarmEnabled: Bool
        let fixedEntries: [FixedEntry]
        let upcomingStartTimes: [Date]
    }

    private var isAppAlarmEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: appAlarmKey) == nil {
            return true
        }
        return defaults.bool(forKey: appAlarmKey)
    }
    
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
        let snapshot = makeSnapshot(from: workplace)
        scheduleWorkNotification(using: snapshot)
    }
    
    private func scheduleWorkNotification(using snapshot: WorkplaceNotificationSnapshot) {
        let center = UNUserNotificationCenter.current()
        
        guard isAppAlarmEnabled else {
            print("앱 알림이 꺼져있어 \(snapshot.name) 알람을 등록하지 않습니다.")
            return
        }
        
        guard snapshot.isAlarmEnabled else {
            print("근무지 알림이 꺼져있어 \(snapshot.name) 알람을 등록하지 않습니다.")
            return
        }
        
        center.getNotificationSettings { [weak self, snapshot] settings in
            let allowed: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]
            guard allowed.contains(settings.authorizationStatus) else {
                print("시스템 알림 권한 미허용 상태:", settings.authorizationStatus.rawValue)
                return
            }
            guard let self else { return }
            
            if snapshot.workType == .flexible {
                self.scheduleFlexibleNotifications(using: snapshot, center: center)
            } else {
                self.scheduleFixedNotifications(using: snapshot, center: center)
            }
        }
    }
    
    func refreshNotifications(for workplace: Workplace) {
        let snapshot = makeSnapshot(from: workplace)
        removeNotifications(prefix: "\(snapshot.id)_") { [weak self] in
            self?.scheduleWorkNotification(using: snapshot)
        }
    }
    
    private func scheduleFixedNotifications(using snapshot: WorkplaceNotificationSnapshot, center: UNUserNotificationCenter) {
        guard !snapshot.fixedEntries.isEmpty else {
            print("등록 가능한 고정 스케줄이 없어 알림을 건너뜁니다. workplace=\(snapshot.name)")
            return
        }
        
        for entry in snapshot.fixedEntries {
            var triggerWeekday = entry.weekday
            var totalMinutes = (entry.hour * 60 + entry.minute) - 15
            if totalMinutes < 0 {
                totalMinutes += 24 * 60
                triggerWeekday = entry.weekday == 1 ? 7 : entry.weekday - 1
            }
            let triggerHour = totalMinutes / 60
            let triggerMinute = totalMinutes % 60
            
            var triggerComponents = DateComponents()
            triggerComponents.weekday = triggerWeekday
            triggerComponents.hour = triggerHour
            triggerComponents.minute = triggerMinute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(snapshot.id)_fixed_\(triggerWeekday)_\(triggerHour)_\(triggerMinute)",
                content: makeContent(workplaceName: snapshot.name),
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("❌ 고정 알림 등록 실패:", error.localizedDescription)
                }
            }
        }
    }
    
    private func scheduleFlexibleNotifications(using snapshot: WorkplaceNotificationSnapshot, center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        let now = Date()
        
        let upcomingSchedules = snapshot.upcomingStartTimes
            .filter { $0 > now }
        
        guard !upcomingSchedules.isEmpty else {
            print("다가오는 자율 근무 스케줄이 없어 알림을 건너뜁니다. workplace=\(snapshot.name)")
            return
        }
        
        for startTime in upcomingSchedules {
            guard let triggerDate = calendar.date(byAdding: .minute, value: -15, to: startTime),
                  triggerDate > now else { continue }
            
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(snapshot.id)_shift_\(Int(startTime.timeIntervalSince1970))",
                content: makeContent(workplaceName: snapshot.name),
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("❌ 자율 알림 등록 실패:", error.localizedDescription)
                }
            }
        }
    }
    
    private func fixedScheduleEntries(for workplace: Workplace) -> [(weekday: Int, hour: Int, minute: Int)] {
        let calendar = Calendar.current
        let weekdayMap: [String: Int] = ["일": 1, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7]
        
        if !workplace.regularSchedules.isEmpty {
            return workplace.regularSchedules.compactMap { schedule in
                guard let weekday = weekdayMap[schedule.dayOfWeek] else { return nil }
                let time = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
                return (weekday, time.hour ?? 9, time.minute ?? 0)
            }
        }
        
        let tokens = workplace.defaultDays
            .components(separatedBy: CharacterSet(charactersIn: ",/ "))
            .filter { !$0.isEmpty }
        
        return tokens.compactMap { day in
            guard let weekday = weekdayMap[day] else { return nil }
            let time = calendar.dateComponents([.hour, .minute], from: workplace.defaultStartTime)
            return (weekday, time.hour ?? 9, time.minute ?? 0)
        }
    }
    
    private func makeContent(workplaceName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "출근 15분 전"
        content.body = "\(workplaceName) 출근 준비하세요!"
        content.sound = .default
        return content
    }
    
    // 기존 알림 삭제
    func removeNotifications(for workplace: Workplace) {
        removeNotifications(prefix: "\(workplace.id.uuidString)_", completion: nil)
    }
    
    private func removeNotifications(prefix: String, completion: (() -> Void)?) {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            
            if !identifiers.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            completion?()
        }
    }
    
    private func makeSnapshot(from workplace: Workplace) -> WorkplaceNotificationSnapshot {
        let calendar = Calendar.current
        let weekdayMap: [String: Int] = ["일": 1, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7]
        
        let fixedEntries: [WorkplaceNotificationSnapshot.FixedEntry]
        if !workplace.regularSchedules.isEmpty {
            fixedEntries = workplace.regularSchedules.compactMap { schedule in
                guard let weekday = weekdayMap[schedule.dayOfWeek] else { return nil }
                let time = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
                return WorkplaceNotificationSnapshot.FixedEntry(
                    weekday: weekday,
                    hour: time.hour ?? 9,
                    minute: time.minute ?? 0
                )
            }
        } else {
            let tokens = workplace.defaultDays
                .components(separatedBy: CharacterSet(charactersIn: ",/ "))
                .filter { !$0.isEmpty }
            
            fixedEntries = tokens.compactMap { day in
                guard let weekday = weekdayMap[day] else { return nil }
                let time = calendar.dateComponents([.hour, .minute], from: workplace.defaultStartTime)
                return WorkplaceNotificationSnapshot.FixedEntry(
                    weekday: weekday,
                    hour: time.hour ?? 9,
                    minute: time.minute ?? 0
                )
            }
        }
        
        return WorkplaceNotificationSnapshot(
            id: workplace.id.uuidString,
            name: workplace.name,
            workType: workplace.workType,
            isAlarmEnabled: workplace.isAlarmEnabled,
            fixedEntries: fixedEntries,
            upcomingStartTimes: workplace.workSchedules.map(\.startTime)
        )
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
