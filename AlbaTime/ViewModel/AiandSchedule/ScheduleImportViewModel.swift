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
    
    // ScheduleImportResultList에 사용
    @Published var parsedSchedules: [ParsedSchedule] = []
    
    // processSelectedPhoto에서 사용
    @Published var selectedImage: UIImage? // ScheduleImportResultList에 사진 보여주기
    @Published var isProcessing: Bool = false
    
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    // preset 연관 변수
    @Published var isAddingPreset: Bool = false
    @Published var newPresetLabel: String = "" // 프리셋 이름
    @Published var newPresetStart: Date = Date.makeTime(9, 0)
    @Published var newPresetEnd: Date = Date.makeTime(18, 0)
    
    var targetJob: Workplace?
    
    // .onAppear로 뷰 진입시 모델 연결
    func setTargetJob(_ job: Workplace) {
        self.targetJob = job
    }

    // 뷰에서 .onChange로 뷰 상태 변경시 호출
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
    
    // processSelectedPhoto에서 사용
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
    
    // SceduleImportResultList에서 ai로 인식한 스케줄 외 추가시에 호출
    func addNewSchedule(targetWeekStart: Date? = nil) {
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: targetWeekStart ?? Date())
        let weekEndExclusive = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        var targetDate = weekStart
        
        // 날짜순 정렬
        let schedulesInWeek = parsedSchedules
            .filter { $0.date >= weekStart && $0.date < weekEndExclusive }
            .sorted(by: { $0.date < $1.date })
        
        // UX 관점 이미 인식된 날짜 다음 날로 자동 생성 ex) 월 화 있으면 추가 버튼 누르면 수요일 자동생성
        if let lastSchedule = schedulesInWeek.last {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: lastSchedule.date) {
                targetDate = nextDay
            }
        }
        
        // 주 넘어가면 마지막날로 보정하기
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
        
        // 추가
        parsedSchedules.append(newSchedule)
        
        // 날짜순 정렬 (추가된 게 중간에 끼어들 수도 있으므로)
        parsedSchedules.sort { $0.date < $1.date }
    }
    
    // ScheduleImportBottomButtons에서 저장버튼 누를시에 호출
    func saveToWorkplace(context: ModelContext, targetWeekStart: Date? = nil, isFromAIImport: Bool = true) -> Bool {
        guard let job = targetJob else {
            errorMessage = "근무지 정보가 없어요."
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
            
            // 다음날 처리
            if finalEnd < finalStart {
                finalEnd = calendar.date(byAdding: .day, value: 1, to: finalEnd) ?? finalEnd
            }
            
            // 배열을 직접 건드리지 말고, DB에서 삭제 명령만 내림 (중복 저장 처리)
            let duplicates = job.workSchedules.filter {
                calendar.isDate($0.date, inSameDayAs: mappedDate)
            }
            
            // 겹치는거 DB 삭제
            for dup in duplicates {
                context.delete(dup)
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
        
        // 알림 갱신
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
    
    // MARK: VM에서 쓰임(헬퍼메서드)
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
    // ScheduleImportPresetGroup에서 사용
    
    func addNewPreset() {
        guard let job = targetJob, !newPresetLabel.isEmpty else { return }
        let preset = WorkTimePreset(label: newPresetLabel, startTime: newPresetStart, endTime: newPresetEnd)
        preset.workplace = job
        job.timePresets.append(preset)
        newPresetLabel = "" // 입력창 초기화 다음 프리셋 추가를 위해
        isAddingPreset = false
    }

    func deletePreset(_ preset: WorkTimePreset) {
        guard let job = targetJob,
              let index = job.timePresets.firstIndex(of: preset) else { return }
        job.timePresets.remove(at: index)
    }
}
