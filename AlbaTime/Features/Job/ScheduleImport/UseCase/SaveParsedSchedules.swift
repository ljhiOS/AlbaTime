//
//  ImportParsedSchedulesUseCase.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation
import SwiftData

enum SaveParsedSchedulesError: Error {
    case missingJob
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingJob:
            return "근무지 정보가 없어요."
        case .saveFailed(let message):
            return "저장 중 오류가 발생했어요.\n\(message)"
        }
    }
}

struct SaveParsedSchedules {
    let appWriteCoordinator: AppWriteCoordinator
    @MainActor
    func execute(
        job: Workplace?,
        parsedSchedules: [ParsedSchedule],
        targetWeekStart: Date?,
        context: ModelContext,
        isFromAIImport: Bool = true
    ) throws {
        guard let job else {
            throw SaveParsedSchedulesError.missingJob
        }
        
        let calendar = Calendar.current
        let batchID = UUID().uuidString
        
        if job.modelContext == nil {
            context.insert(job)
        }
        
        for parsed in parsedSchedules {
            let mappedDate = mappedDateForTargetWeek(
                originalDate: parsed.date,
                targetWeekStart: targetWeekStart
            )
            
            let finalStart = combineDateAndTime(date: mappedDate, time: parsed.startTime)
            var finalEnd = combineDateAndTime(date: mappedDate, time: parsed.endTime)
            
            if finalEnd < finalStart {
                finalEnd = calendar.date(byAdding: .day, value: 1, to: finalEnd) ?? finalEnd
            }
            
            let duplicates = job.workSchedules.filter {
                calendar.isDate($0.date, inSameDayAs: mappedDate)
            }
            
            for dup in duplicates {
                context.delete(dup)
            }
            
            let newSchedule = WorkSchedule(
                date: mappedDate,
                startTime: finalStart,
                endTime: finalEnd,
                breakTime: job.defaultRestTime ?? 0,
                memo: parsed.workLabel,
                isFromAIImport: isFromAIImport,
                aiImportBatchID: batchID,
                isEditedAfterAIImport: false
            )
            
            newSchedule.workplace = job
            
            if !job.workSchedules.contains(where: { $0.id == newSchedule.id }) {
                job.workSchedules.append(newSchedule)
            }
            
            context.insert(newSchedule)
        }
        
        do {
            try appWriteCoordinator.commit(context: context, affectedWorkplace: job)
        } catch {
            throw SaveParsedSchedulesError.saveFailed(error.localizedDescription)
        }
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
    
    private func mappedDateForTargetWeek(originalDate: Date, targetWeekStart: Date?) -> Date {
        guard let targetWeekStart else { return originalDate }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: originalDate)
        let mondayBasedOffset = (weekday + 5) % 7
        let start = calendar.startOfDay(for: targetWeekStart)
        
        return calendar.date(byAdding: .day, value: mondayBasedOffset, to: start) ?? originalDate
    }
}
