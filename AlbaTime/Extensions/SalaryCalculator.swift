//
//  SalaryCalculator.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import Foundation

struct SalaryCalculator {
    
    // MARK: - 1. 하루 급여 계산 (캘린더 상세용)
    static func calculateDailyPay(schedule: WorkSchedule, hourlyWage: Int) -> Int {
        let hours = calculateWorkingHours(start: schedule.startTime, end: schedule.endTime, restTime: schedule.breakTime)
        let payData = calculatePayFromHours(hours: hours, hourlyWage: hourlyWage)
        return payData.totalPay
    }
    
    // MARK: - 2. [핵심] 이번 달 총 예상 급여 시뮬레이션
    // 원칙: 기록된 스케줄(AI/수기)은 100% 반영하고, 설정된 목표보다 부족할 때만 예측값으로 채움
    static func calculateTotalMonthlyPay(workplaces: [Workplace], targetMonth: Date) -> SalaryBreakdown {
        var grandTotal = SalaryBreakdown.empty
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: targetMonth) else { return .empty }
        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end
        
        for job in workplaces {
            var jobBreakdown = SalaryBreakdown.empty
            
            // A. 이번 달에 기록된(AI/수기) 모든 스케줄 가져오기
            // (SwiftData에 저장된 실제 데이터)
            let actualSchedules = job.workSchedules.filter {
                calendar.isDate($0.date, equalTo: targetMonth, toGranularity: .month)
            }
            
            // ---------------------------------------------------
            // [Case 1] 고정 근무 (Fixed): 1일부터 말일까지 하루씩 돌면서 체크
            // ---------------------------------------------------
            if job.workType == .fixed {
                // 기록된 날짜들 (중복 계산 방지용)
                let recordedDates = Set(actualSchedules.map { calendar.startOfDay(for: $0.date) })
                
                // 1. 실제 기록된 스케줄 계산 (우선 순위 1)
                for schedule in actualSchedules {
                    let pay = calculateSchedulePay(schedule, hourlyWage: job.hourlyWage)
                    jobBreakdown.add(pay)
                }
                
                // 2. 기록이 없는 날은 설정(RegularSchedule)으로 예측 (우선 순위 2)
                var currentDate = startOfMonth
                while currentDate < endOfMonth {
                    // 기록이 없는 날만 예측값 적용
                    if !recordedDates.contains(calendar.startOfDay(for: currentDate)) {
                        let weekday = currentDate.koreanWeekday
                        
                        // (A) 상세 요일 설정 확인
                        if let regular = job.regularSchedules.first(where: { $0.dayOfWeek == weekday }) {
                            let hours = calculateWorkingHours(
                                start: regular.startTime,
                                end: regular.endTime,
                                restTime: job.defaultRestTime ?? 0
                            )
                            jobBreakdown.add(calculatePayFromHours(hours: hours, hourlyWage: job.hourlyWage))
                        }
                        // (B) 간편 요일 설정 확인
                        else if job.regularSchedules.isEmpty && job.defaultDays.contains(weekday) {
                            let hours = calculateWorkingHours(
                                start: job.defaultStartTime,
                                end: job.defaultEndTime,
                                restTime: job.defaultRestTime ?? 0
                            )
                            jobBreakdown.add(calculatePayFromHours(hours: hours, hourlyWage: job.hourlyWage))
                        }
                    }
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                }
            }
            
            // ---------------------------------------------------
            // [Case 2] 자율 근무 (Flexible): 주(Week) 단위 하이브리드 계산
            // ---------------------------------------------------
            else {
                // 이번 달의 주(Week) 범위를 순회
                if let weekRange = calendar.range(of: .weekOfMonth, in: .month, for: targetMonth) {
                    let targetCount = job.targetWeeklyCount ?? 0
                    let avgHours = job.expectedDailyHours ?? 0.0
                    
                    for week in weekRange {
                        // 1. 이 주(Week)에 실제로 일한 기록들 찾기
                        let schedulesInThisWeek = actualSchedules.filter {
                            calendar.component(.weekOfMonth, from: $0.date) == week
                        }
                        
                        // 2. 🔥 [중요] 실제 기록된 건 횟수 제한 없이 무조건 다 더함
                        // (예: 목표가 3회여도, 5회 일했으면 5회분 급여 인정)
                        for schedule in schedulesInThisWeek {
                            let pay = calculateSchedulePay(schedule, hourlyWage: job.hourlyWage)
                            jobBreakdown.add(pay)
                        }
                        
                        // 3. 모자란 횟수 확인 (Target - Actual)
                        // (예: 목표 3회 - 실제 1회 = 2회 부족 -> 2회만 예측값 추가)
                        // (예: 목표 3회 - 실제 5회 = -2 -> 0회 추가 -> 예측값 없음)
                        let workedCount = schedulesInThisWeek.count
                        let remainingCount = max(0, targetCount - workedCount)
                        
                        // 4. 부족한 만큼만 평균 시간으로 채워넣기
                        if remainingCount > 0 {
                            let predictedBasicPay = Int(Double(remainingCount) * avgHours * Double(job.hourlyWage))
                            let predictedHours = Double(remainingCount) * avgHours
                            
                            jobBreakdown.basicPay += predictedBasicPay
                            jobBreakdown.totalHours += predictedHours
                            jobBreakdown.workingDays += remainingCount
                        }
                    }
                }
            }
            
            // ---------------------------------------------------
            // [Step 3] 세금 및 합계 처리
            // ---------------------------------------------------
            let gross = jobBreakdown.basicPay + jobBreakdown.nightPay + jobBreakdown.overtimePay + jobBreakdown.holidayPay
            let tax = Int(Double(gross) * job.taxType.rate)
            jobBreakdown.taxAmount = tax
            jobBreakdown.totalPay = gross - tax
            
            grandTotal.add(jobBreakdown)
        }
        
        return grandTotal
    }
    
    // MARK: - Helpers (계산 보조)
    
    static func calculateAverageWage(basicPay: Int, totalHours: Double) -> Int {
        guard totalHours > 0 else { return 0 }
        // 기본급 / 총 시간 = 평균 시급
        return Int(Double(basicPay) / totalHours)
    }
    
    // 스케줄 객체 하나 급여 계산 (래퍼 함수)
    private static func calculateSchedulePay(_ schedule: WorkSchedule, hourlyWage: Int) -> SalaryBreakdown {
        let hours = calculateWorkingHours(
            start: schedule.startTime,
            end: schedule.endTime,
            restTime: schedule.breakTime
        )
        return calculatePayFromHours(hours: hours, hourlyWage: hourlyWage)
    }
    
    // 근무 시간 계산 로직 (야간, 연장, 휴게시간 포함)
    private static func calculateWorkingHours(start: Date, end: Date, restTime: Int) -> (total: Double, night: Double, overtime: Double) {
        let calendar = Calendar.current
        let startH = calendar.component(.hour, from: start)
        let startM = calendar.component(.minute, from: start)
        let endH = calendar.component(.hour, from: end)
        let endM = calendar.component(.minute, from: end)
        
        let startMins = startH * 60 + startM
        var endMins = endH * 60 + endM
        // 날짜 넘어가는 경우(새벽 퇴근) 처리
        if endMins < startMins { endMins += 1440 }
        
        let rawDiffMins = Double(endMins - startMins)
        let netDiffMins = max(0, rawDiffMins - Double(restTime))
        let totalHours = netDiffMins / 60.0
        
        // 연장 근무 (8시간 초과분)
        let overtimeHours = max(0, totalHours - 8.0)
        
        // 야간 근무 (22:00 ~ 06:00)
        var nightMinsCount = 0
        for t in startMins..<endMins {
            let normalized = t % 1440
            // 0~360분(00시~06시) 또는 1320분 이상(22시~24시)
            if normalized < 360 || normalized >= 1320 { nightMinsCount += 1 }
        }
        
        // 휴게시간 비율만큼 야간시간도 차감
        let ratio = rawDiffMins > 0 ? netDiffMins / rawDiffMins : 1.0
        let nightHours = (Double(nightMinsCount) * ratio) / 60.0
        
        return (totalHours, nightHours, overtimeHours)
    }
    
    // 시간 정보 -> 금액 정보 변환 (시급 적용)
    private static func calculatePayFromHours(hours: (total: Double, night: Double, overtime: Double), hourlyWage: Int) -> SalaryBreakdown {
        let wage = Double(hourlyWage)
        let basic = Int(hours.total * wage)
        let night = Int(hours.night * wage * 0.5)    // 0.5배 가산
        let overtime = Int(hours.overtime * wage * 0.5) // 0.5배 가산
        let total = basic + night + overtime
        
        return SalaryBreakdown(
            basicPay: basic,
            nightPay: night,
            overtimePay: overtime,
            holidayPay: 0,
            taxAmount: 0,
            totalPay: total,
            totalHours: hours.total,
            workingDays: 1
        )
    }
}
