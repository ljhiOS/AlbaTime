@preconcurrency import UserNotifications
import Foundation

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    private let appAlarmKey = "isAppAlarmOn"
    
    private struct WorkPlaceNotificationSnapshot {
        let id: String
        let name: String
        let isAlarmEnabled: Bool
        let upcomingShifts: [ShiftNotificationTime]
    }

    private struct ShiftNotificationTime {
        let start: Date
        let end: Date
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
    func scheduleWorkNotification(for workPlace: WorkPlace) {
        let snapshot = makeSnapshot(from: workPlace)
        scheduleWorkNotification(using: snapshot)
    }
    
    private func scheduleWorkNotification(using snapshot: WorkPlaceNotificationSnapshot) {
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
            
            Task { @MainActor in
                self.scheduleUpcomingNotifications(using: snapshot)
            }
        }
    }
    
    func refreshNotifications(for workPlace: WorkPlace) {
        let snapshot = makeSnapshot(from: workPlace)
        removeNotifications(prefix: "\(snapshot.id)_") { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.scheduleWorkNotification(using: snapshot)
            }
        }
    }
    
    private func scheduleUpcomingNotifications(using snapshot: WorkPlaceNotificationSnapshot) {
        let calendar = Calendar.current
        let now = Date()
        let center = UNUserNotificationCenter.current()

        let upcomingShifts = snapshot.upcomingShifts
            .filter { $0.start > now || $0.end > now }
            .sorted { $0.start < $1.start }

        guard !upcomingShifts.isEmpty else {
            print("다가오는 근무 스케줄이 없어 알림을 건너뜁니다. workPlace=\(snapshot.name)")
            return
        }

        for shift in upcomingShifts {
            if let triggerDate = calendar.date(byAdding: .minute, value: -15, to: shift.start),
               triggerDate > now {
                addNotification(
                    center: center,
                    identifier: "\(snapshot.id)_start_\(Int(shift.start.timeIntervalSince1970))",
                    content: makeStartContent(workPlaceName: snapshot.name),
                    triggerDate: triggerDate
                )
            }

            if shift.end > now {
                addNotification(
                    center: center,
                    identifier: "\(snapshot.id)_end_\(Int(shift.end.timeIntervalSince1970))",
                    content: makeEndContent(workPlaceName: snapshot.name),
                    triggerDate: shift.end
                )
            }
        }
    }

    private func addNotification(
        center: UNUserNotificationCenter,
        identifier: String,
        content: UNMutableNotificationContent,
        triggerDate: Date
    ) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ 알림 등록 실패:", error.localizedDescription)
            }
        }
    }

    private func makeStartContent(workPlaceName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "출근 15분 전"
        content.body = "\(workPlaceName) 출근 준비하세요!"
        content.sound = .default
        return content
    }

    private func makeEndContent(workPlaceName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(workPlaceName) 근무 종료!"
        content.body = "\(workPlaceName) 근무가 끝났어요.\n변경된 누적금액을 확인해보세요."
        content.sound = .default
        return content
    }
    
    // 기존 알림 삭제
    func removeNotifications(for workPlace: WorkPlace) {
        removeNotifications(prefix: "\(workPlace.id.uuidString)_", completion: nil)
    }
    
    private func removeNotifications(prefix: String, completion: (@Sendable () -> Void)?) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }

            if !identifiers.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiers)
            }

            if let completion {
                Task { @MainActor in
                    completion()
                }
            }
        }
    }
    
    private func makeSnapshot(from workPlace: WorkPlace) -> WorkPlaceNotificationSnapshot {
        WorkPlaceNotificationSnapshot(
            id: workPlace.id.uuidString,
            name: workPlace.name,
            isAlarmEnabled: workPlace.isAlarmEnabled,
            upcomingShifts: upcomingShiftTimes(for: workPlace, daysAhead: 30)
        )
    }

    private func upcomingShiftTimes(for workPlace: WorkPlace, daysAhead: Int) -> [ShiftNotificationTime] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        var results: [ShiftNotificationTime] = []

        for offset in 0...daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            
            guard let schedule = workPlace.getSchedule(for: day) else { continue }

            let start = combineDateAndTime(date: day, time: schedule.startTime)
            var end = combineDateAndTime(date: day, time: schedule.endTime)

            if end < start {
                end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
            }

            guard start > now || end > now else { continue }
            results.append(ShiftNotificationTime(start: start, end: end))
        }

        return results.sorted { $0.start < $1.start }
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: timeComp.hour ?? 0,
            minute: timeComp.minute ?? 0,
            second: 0,
            of: date
        ) ?? date
    }

    
    // 모든 알람 허용 X
    func removeAllNotifications() {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("모든 알림 허용의 해제")
        }
    
    // 디버깅용
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("예약된 알림 \(requests.count)개")
            for req in requests {
                if let trigger = req.trigger as? UNCalendarNotificationTrigger,
                   let date = trigger.nextTriggerDate() {
                    print("• \(req.identifier) → \(date.formatted())")
                }
            }
        }
    }
}
