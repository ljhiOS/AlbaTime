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
                     
                     // 직장 정보가 있다면 바로 분석 시작
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
                        ? "스케줄 형식을 찾지 못했습니다.\n(콘솔 로그의 Row 데이터를 확인해주세요)"
                        : "'\(targetName)'님의 스케줄을 찾지 못했습니다.\n이름이 정확한지 확인해주세요."
                    self.showAlert = true
                } else {
                    print("최종 파싱 성공: \(schedules.count)건")
                }
                
            } catch {
                self.isProcessing = false
                print("분석 에러: \(error)")
                self.errorMessage = "분석 중 오류가 발생했습니다: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }

    func addNewSchedule() {
        let calendar = Calendar.current
        var targetDate = Date()
        
        // 1. 이미 리스트에 데이터가 있다면, '마지막 날짜 + 1일'로 설정
        if let lastSchedule = parsedSchedules.sorted(by: { $0.date < $1.date }).last {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: lastSchedule.date) {
                targetDate = nextDay
            }
        }
        
        // 2. 기본 시간: 09:00 ~ 18:00
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate)!
        let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDate)!
        
        let newSchedule = ParsedSchedule(
            date: targetDate,
            startTime: start,
            endTime: end,
            scheduleName: nil
        )
        
        parsedSchedules.append(newSchedule)
        
        // 3. 날짜순 정렬 (추가된 게 중간에 끼어들 수도 있으므로)
        parsedSchedules.sort { $0.date < $1.date }
    }
    
    func saveToWorkplace(context: ModelContext) {
        guard let job = targetJob else { return }
        let calendar = Calendar.current
        
        if job.modelContext == nil {
            context.insert(job)
        }
        
        for parsed in parsedSchedules {
            let finalStart = combineDateAndTime(date: parsed.date, time: parsed.startTime)
            var finalEnd = combineDateAndTime(date: parsed.date, time: parsed.endTime)
            
            if finalEnd < finalStart {
                finalEnd = calendar.date(byAdding: .day, value: 1, to: finalEnd)!
            }
            
            // 배열을 직접 건드리지 말고, DB에서 삭제 명령만 내림
            let duplicates = job.workSchedules.filter {
                calendar.isDate($0.date, inSameDayAs: parsed.date)
            }
            
            for dup in duplicates {
                context.delete(dup) // DB에서 삭제하면 배열에서도 알아서 빠짐 (SwiftData의 마법)
            }
            
            // 새 스케줄 생성
            let newSchedule = WorkSchedule(
                date: parsed.date,
                startTime: finalStart,
                endTime: finalEnd,
                breakTime: job.defaultRestTime ?? 0,
                memo: parsed.scheduleName
            )
            
            newSchedule.workplace = job
            // job.workSchedules.append(newSchedule)
            context.insert(newSchedule)
        }
        
        do {
            try context.save()
            print("✅ DB 저장 완료")
        } catch {
            print("❌ DB 저장 실패: \(error)")
            errorMessage = "저장 중 오류가 발생했습니다."
            showAlert = true
        }
    }
    
    // Helper: 날짜(YMD) + 시간(HMS) 합치기
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: date) ?? date
    }
    
    func addEmptySchedule() {
        let newSchedule = ParsedSchedule(
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!,
            scheduleName: "직접 입력"
        )
        self.parsedSchedules.append(newSchedule)
        self.objectWillChange.send()
    }
}
