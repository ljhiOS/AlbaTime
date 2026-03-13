//
//  ScheduleImportViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import Vision
import SwiftData
import PhotosUI

@MainActor
class ScheduleImportViewModel: ObservableObject {
    
    @Published var selectedImage: UIImage?
    @Published var parsedSchedules: [ParsedSchedule] = []
    @Published var isProcessing: Bool = false
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    // preset 연관 변수
    @Published var isAddingPreset: Bool = false
    @Published var newPresetLabel: String = ""
    @Published var newPresetStart: Date = Date.makeTime(9, 0)
    @Published var newPresetEnd: Date = Date.makeTime(18, 0)
    
    var targetJob: Workplace?
    
    func setTargetJob(_ job: Workplace) {
        self.targetJob = job
    }

    func processSelectedPhoto(item: PhotosPickerItem?, targetJob: Workplace?, targetName: String) async {
        guard let item else { return }
        
        isProcessing = true        
        
        do {
            // Transferable 프로토콜을 이용해 데이터 로드
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                
                self.selectedImage = image
                
                // 근무지 정보가 있다면 바로 분석 시작
                if let job = targetJob {
                    self.setTargetJob(job)
                    self.analyzeImage(targetName: targetName)
                }
            } else {
                self.errorMessage = "이미지 데이터를 불러올 수 없습니다."
                self.showAlert = true
            }
        } catch {
            print("사진 로드 에러: \(error)")
            self.errorMessage = "사진 로드 중 오류 발생.\n권한을 확인해주세요."
            self.showAlert = true
        }
    }
    
    func analyzeImage(targetName: String = "") {
        guard let image = selectedImage else { return }
        guard let job = targetJob else {
            errorMessage = "근무지 정보가 없습니다."
            showAlert = true
            return
        }
        
        isProcessing = true
        parsedSchedules = [] // 초기화
        
        Task {
            do {
                // [1단계] 이미지 전처리 및 OCR (Raw Data 추출)
                print("[Step 1] OCR 인식 시작...")
                let rawBoxes = try await OCRService.shared.recognize(from: image)
                print("인식된 텍스트 박스: \(rawBoxes.count)개")
                
                // [2단계] 텍스트 레이아웃 분석 (행 그룹화)
                print("[Step 2] 텍스트 행(Row) 구조화 중...")
                let textRows = TextLayoutAnalyzer.groupByRow(rawBoxes)
                
                // 디버깅: 그룹화된 행 출력
                print("----- LAYOUT ANALYSIS START -----")
                for (index, row) in textRows.enumerated() {
                    print("Row \(index): \(row.fullText)")
                }
                print("----- LAYOUT ANALYSIS END -----")
                
                // [3단계] 의미 해석 및 스케줄 추출
                print("[Step 3] 스케줄 파싱 및 필터링...")
                let schedules = ScheduleParser.shared.parse(
                    rows: textRows,
                    presets: job.timePresets,
                    targetName: targetName
                )
                
                // 결과 업데이트
                self.parsedSchedules = schedules
                self.isProcessing = false
                
                if schedules.isEmpty {
                    self.errorMessage = targetName.isEmpty
                    ? "스케줄 형식을 찾지 못했어요."
                    : "'\(targetName)'님의 스케줄을 찾지 못했어요.\n이름이 정확한지 확인해주세요."
                    self.showAlert = true
                } else {
                    print("최종 파싱 성공: \(schedules.count)건")
                }
                
            } catch {
                self.isProcessing = false
                print("분석 에러: \(error)")
                self.errorMessage = "분석 중 오류가 발생했어요: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    func addNewSchedule(targetWeekStart: Date? = nil) {
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: targetWeekStart ?? Date())
        let weekEndExclusive = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        var targetDate = weekStart
        
        let schedulesInWeek = parsedSchedules
            .filter { $0.date >= weekStart && $0.date < weekEndExclusive }
            .sorted(by: { $0.date < $1.date })
        
        if let lastSchedule = schedulesInWeek.last {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: lastSchedule.date) {
                targetDate = nextDay
            }
        }
        
        if targetDate >= weekEndExclusive {
            targetDate = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        }
        
        // 2. 기본 시간: 09:00 ~ 18:00 // guard let 구문으로 강제언래핑 제거
        guard let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate),
              let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDate)
        else {
            errorMessage = "기본 시간 생성에 실패했어요."
            showAlert = true
            return
        }
        
        let newSchedule = ParsedSchedule(
            date: targetDate,
            startTime: start,
            endTime: end,
            workLabel: nil
        )
        
        parsedSchedules.append(newSchedule)
        
        // 3. 날짜순 정렬 (추가된 게 중간에 끼어들 수도 있으므로)
        parsedSchedules.sort { $0.date < $1.date }
    }
    
    func saveToWorkplace(context: ModelContext, targetWeekStart: Date? = nil, isFromAIImport: Bool = true) -> Bool {
        guard let job = targetJob else {
            errorMessage = "근무지 정보가 없습니다."
            showAlert = true
            return false
        }
        let calendar = Calendar.current
        let batchID = UUID().uuidString
        
        if job.modelContext == nil {
            context.insert(job)
        }
        
        for parsed in parsedSchedules {
            let mappedDate = mappedDateForTargetWeek(originalDate: parsed.date, targetWeekStart: targetWeekStart)
            let finalStart = combineDateAndTime(date: mappedDate, time: parsed.startTime)
            var finalEnd = combineDateAndTime(date: mappedDate, time: parsed.endTime)
            
            if finalEnd < finalStart {
                finalEnd = calendar.date(byAdding: .day, value: 1, to: finalEnd) ?? finalEnd
            }
            
            // 배열을 직접 건드리지 말고, DB에서 삭제 명령만 내림
            let duplicates = job.workSchedules.filter {
                calendar.isDate($0.date, inSameDayAs: mappedDate)
            }
            
            for dup in duplicates {
                context.delete(dup) // DB에서 삭제하면 배열에서도 알아서 빠짐 (SwiftData의 마법)
            }
            
            // 새 스케줄 생성
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
        
        NotificationManager.shared.refreshNotifications(for: job)
        
        do {
            try context.save()
            let workplaces = try context.fetch(FetchDescriptor<Workplace>())
            NextShiftSyncService.sync(workplaces: workplaces)
            print("✅ DB 저장 완료")
            return true
        } catch {
            print("❌ DB 저장 실패: \(error)")
            errorMessage = "저장 중 오류가 발생했습니다."
            showAlert = true
            return false
        }
    }
    
    // Helper: 날짜(YMD) + 시간(HMS) 합치기
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: date) ?? date
    }
    
    private func mappedDateForTargetWeek(originalDate: Date, targetWeekStart: Date?) -> Date {
        guard let targetWeekStart else { return originalDate }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: originalDate) // 1:일 ... 7:토
        let mondayBasedOffset = (weekday + 5) % 7 // 월:0 ... 일:6
        let start = calendar.startOfDay(for: targetWeekStart)
        return calendar.date(byAdding: .day, value: mondayBasedOffset, to: start) ?? originalDate
    }
    
    // MARK: preset 연관 메서드
    
    func addNewPreset() {
        guard let job = targetJob, !newPresetLabel.isEmpty else { return }
        let preset = WorkTimePreset(label: newPresetLabel, startTime: newPresetStart, endTime: newPresetEnd)
        preset.workplace = job
        job.timePresets.append(preset)
        newPresetLabel = ""
        isAddingPreset = false
    }

    func deletePreset(_ preset: WorkTimePreset) {
        guard let job = targetJob,
              let index = job.timePresets.firstIndex(of: preset) else { return }
        job.timePresets.remove(at: index)
    }
}
