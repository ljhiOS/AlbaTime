import Foundation

struct WorkScheduleFactory {
    func make(
        from item: ScheduleEditItem,
        targetWeekStart: Date? = nil,
        aiImportBatchID: String
    ) -> WorkSchedule {
        let mappedDate = mappedDate(
            originalDate: item.date,
            targetWeekStart: targetWeekStart
        )
        let finalTimes = normalizedTimes(
            date: mappedDate,
            startTime: item.startTime,
            endTime: item.endTime
        )

        return WorkSchedule(
            date: mappedDate,
            startTime: finalTimes.start,
            endTime: finalTimes.end,
            breakTime: item.breakTime,
            memo: item.memo,
            isFromAIImport: item.source == .aiImport,
            aiImportBatchID: item.source == .aiImport ? aiImportBatchID : nil,
            isEditedAfterAIImport: item.changeState == .updated
        )
    }

    func apply(
        _ item: ScheduleEditItem,
        to schedule: WorkSchedule,
        targetWeekStart: Date? = nil
    ) {
        let mappedDate = mappedDate(
            originalDate: item.date,
            targetWeekStart: targetWeekStart
        )
        let finalTimes = normalizedTimes(
            date: mappedDate,
            startTime: item.startTime,
            endTime: item.endTime
        )

        schedule.date = mappedDate
        schedule.startTime = finalTimes.start
        schedule.endTime = finalTimes.end
        schedule.breakTime = item.breakTime
        schedule.memo = item.memo
        schedule.isFromAIImport = item.source == .aiImport
        schedule.isEditedAfterAIImport = true
    }

    func mappedDate(originalDate: Date, targetWeekStart: Date?) -> Date {
        guard let targetWeekStart else { return originalDate }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: originalDate)
        let mondayBasedOffset = (weekday + 5) % 7
        let start = calendar.startOfDay(for: targetWeekStart)

        return calendar.date(byAdding: .day, value: mondayBasedOffset, to: start) ?? originalDate
    }

    private func normalizedTimes(
        date: Date,
        startTime: Date,
        endTime: Date
    ) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let finalStart = combineDateAndTime(date: date, time: startTime)
        var finalEnd = combineDateAndTime(date: date, time: endTime)

        if finalEnd < finalStart {
            finalEnd = calendar.date(byAdding: .day, value: 1, to: finalEnd) ?? finalEnd
        }

        return (finalStart, finalEnd)
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        return calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: date
        ) ?? date
    }
}
