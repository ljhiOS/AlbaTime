import Foundation

enum ScheduleEditMode: Equatable {
    case newJobInitialSchedules
    case existingJobAIImport
    case existingSavedAIEdit
}

struct ScheduleEditDraft {
    var mode: ScheduleEditMode
    var targetWeekStart: Date?
    var items: [ScheduleEditItem]
}

extension ScheduleEditDraft {
    static func empty(
        mode: ScheduleEditMode,
        targetWeekStart: Date? = nil
    ) -> ScheduleEditDraft {
        ScheduleEditDraft(
            mode: mode,
            targetWeekStart: targetWeekStart,
            items: []
        )
    }

    static func fromSavedAISchedules(
        job: Workplace,
        targetWeekStart: Date? = nil
    ) -> ScheduleEditDraft {
        ScheduleEditDraft(
            mode: .existingSavedAIEdit,
            targetWeekStart: targetWeekStart,
            items: job.workSchedules
                .filter(\.isFromAIImport)
                .sorted {
                    if $0.date != $1.date { return $0.date < $1.date }
                    return $0.startTime < $1.startTime
                }
                .map(ScheduleEditItem.init(workSchedule:))
        )
    }
}
