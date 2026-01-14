//급여 계산 로직
import Foundation

struct SalaryCalculator {
    
    // 일급 계산 (단순 시급 * 시간) - 캘린더 표시용
    static func calculateExpectedPay(workplace: Workplace) -> Int {
        let basePay = Int(workplace.dailyWorkingHours * Double(workplace.hourlyWage))
        // 일급 표시에는 보통 수당을 다 합쳐서 보여줄지, 기본급만 보여줄지 결정해야 함
        // 여기서는 '예상 수령액'이므로 야간/연장 수당을 포함해서 계산해줌
        
        let nightAllowance = Int(workplace.dailyNightHours * Double(workplace.hourlyWage) * 0.5)
        let overtimeAllowance = Int(workplace.dailyOvertimeHours * Double(workplace.hourlyWage) * 0.5)
        
        return basePay + nightAllowance + overtimeAllowance
    }
    
    // [수정] 월급 명세서 계산 (연장 수당 추가)
    static func calculateExpectedMonthlyPay(workplaces: [Workplace], targetMonth: Date) -> SalaryBreakdown {
        var totalBasic = 0
        var totalNight = 0
        var totalOvertime = 0 // 추가된 항목
        var totalHoliday = 0
        var totalTax = 0
        var grandTotalHours = 0.0
        var grandWorkingDays = 0
        
        let calendar = Calendar.current
        
        guard let range = calendar.range(of: .day, in: .month, for: targetMonth),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth)) else {
            return SalaryBreakdown.empty
        }
        
        for place in workplaces {
            let weekdays = place.activeWeekdays
            let hourlyWage = Double(place.hourlyWage)
            let dailyHours = place.dailyWorkingHours
            let nightHours = place.dailyNightHours
            let overtimeHours = place.dailyOvertimeHours // 연장시간 (8시간 초과분)
            
            var placeWorkingDays = 0
            
            // 1. 근무 일수 카운트
            for day in range {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                    let weekday = calendar.component(.weekday, from: date)
                    if weekdays.contains(weekday) {
                        placeWorkingDays += 1
                    }
                }
            }
            
            // 1) 4.345: 한 달 평균 주수(주휴수당 계산용)
            // 2) 40.0: 법정 주간 최대 근로시간
            // 3) 8.0: 하루 기준 근로시간
            // 4) 0.5: 가산 수당 비율(야간/연장)
            // 2. 기본급 (총 근무시간 * 시급)
            // 주의: 기본급에는 이미 연장시간에 대한 1.0배 급여가 포함되어 있음
            let monthTotalHours = Double(placeWorkingDays) * dailyHours
            let basicPay = Int(monthTotalHours * hourlyWage)
            
            // 3. 야간 수당 (야간시간 * 0.5)
            let monthNightHours = Double(placeWorkingDays) * nightHours
            let nightAllowance = Int(monthNightHours * hourlyWage * 0.5)
            
            // 4. [신규] 연장 수당 (8시간 초과분 * 0.5)
            // 근로기준법: 하루 8시간 초과 시 통상임금의 50% 가산
            let monthOvertimeHours = Double(placeWorkingDays) * overtimeHours
            let overtimeAllowance = Int(monthOvertimeHours * hourlyWage * 0.5)
            
            // 5. 주휴 수당 (기존 로직 유지 - 완벽함)
            var holidayAllowance = 0
            let weeklyHours = dailyHours * Double(weekdays.count)
            
            if weeklyHours >= 15 {
                let calcHours = min(weeklyHours, 40.0)
                let weeklyHolidayPay = (calcHours / 40.0) * 8.0 * hourlyWage
                holidayAllowance = Int(weeklyHolidayPay * 4.345)
            }
            
            let placeGrossPay = basicPay + nightAllowance + overtimeAllowance + holidayAllowance
            // 세금 계산 (원 단위 절사 등 정밀한 세법보다는 예상치 제공)
            let tax = Int(Double(placeGrossPay) * place.taxType.rate)
            
            
            totalBasic += basicPay
            totalNight += nightAllowance
            totalOvertime += overtimeAllowance
            totalHoliday += holidayAllowance
            totalTax += tax
            
            grandTotalHours += monthTotalHours
            grandWorkingDays += placeWorkingDays
        }
        
        let grossTotal = totalBasic + totalNight + totalOvertime + totalHoliday
        let netTotal = grossTotal - totalTax
        
        return SalaryBreakdown(
            basicPay: totalBasic,
            nightPay: totalNight,
            overtimePay: totalOvertime, // 구조체에 이 필드 추가 필요
            holidayPay: totalHoliday,
            taxAmount: totalTax,
            totalPay: netTotal,
            totalHours: grandTotalHours,
            workingDays: grandWorkingDays
        )
    }
    
    // ... calculateAverageWage 등은 그대로 사용
    static func calculateAverageWage(basicPay: Int, totalHours: Double) -> Int {
         guard totalHours > 0 else { return 0 }
         return Int(Double(basicPay) / totalHours)
     }
}

struct SalaryBreakdown {
    var basicPay: Int       // 기본 급여
    var nightPay: Int       // 야간 수당
    var overtimePay: Int    // [추가] 연장 수당 (8시간 초과 가산분)
    var holidayPay: Int     // 주휴 수당
    var taxAmount: Int      // 세금 비율
    var totalPay: Int       // 총 합계
    var totalHours: Double  // 총 근무 시간
    var workingDays: Int    // 근무 일수
    
    // 빈 데이터 편의 생성자
    static var empty: SalaryBreakdown {
        return SalaryBreakdown(basicPay: 0, nightPay: 0, overtimePay: 0, holidayPay: 0, taxAmount: 0, totalPay: 0, totalHours: 0, workingDays: 0)
    }
}

extension Workplace {
    // 요일 변환
    var activeWeekdays: [Int] {
        let mapping: [String: Int] = ["일": 1, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7]
        let days = self.defaultDays.components(separatedBy: CharacterSet(charactersIn: ",/ ")).filter { !$0.isEmpty }
        return days.compactMap { mapping[$0] }
    }
    
    // 1. 하루 총 근무 시간 (휴게시간 차감)
    var dailyWorkingHours: Double {
        let diff = defaultEndTime.timeIntervalSince(defaultStartTime)
        let adjustedDiff = diff < 0 ? diff + 86400 : diff // 24시간 보정
        let breakSeconds = Double(defaultRestTime ?? 0) * 60
        return max(0, (adjustedDiff - breakSeconds) / 3600.0)
    }
    
    // 2. [수정] 연장 근무 시간 (하루 8시간 초과분)
    var dailyOvertimeHours: Double {
        return max(0, dailyWorkingHours - 8.0)
    }
    
    // 3. [수정] 하루 야간 근무 시간 (22:00 ~ 06:00) 완벽 계산 로직
    var dailyNightHours: Double {
        let calendar = Calendar.current
        
        // 시/분 추출
        let startHour = calendar.component(.hour, from: defaultStartTime)
        let startMinute = calendar.component(.minute, from: defaultStartTime)
        let endHour = calendar.component(.hour, from: defaultEndTime)
        let endMinute = calendar.component(.minute, from: defaultEndTime)
        
        // 분 단위로 변환 (00:00 = 0, 01:00 = 60 ...)
        let startMins = startHour * 60 + startMinute
        var endMins = endHour * 60 + endMinute
        
        // 종료 시간이 시작 시간보다 작으면(새벽 넘김) 24시간(1440분) 더함
        if endMins < startMins {
            endMins += 1440
        }
        
        // 휴게시간이 있다면 단순히 비율로 차감하거나, 정확한 휴게시간 대역을 알아야 하지만
        // 시뮬레이터 특성상 전체 근무시간 비율로 야간시간을 약간 깎아주는 것이 안전함
        // (여기서는 일단 휴게시간 고려 없이 순수 시간대 겹침만 계산 후 리턴)
        
        var nightMinutes = 0
        
        // 근무 시간의 모든 '분'을 순회하며 야간 대역인지 체크 (가장 정확함)
        // 22:00(1320분) ~ 06:00(360분)
        // 하루를 넘기는 케이스 고려: 22:00 ~ 30:00(다음날 06:00)
        
        for t in startMins..<endMins {
            // 하루 단위로 정규화 (0~1439)
            let normalizedTime = t % 1440
            
            // 00:00 ~ 06:00 (0 ~ 360) 또는 22:00 ~ 24:00 (1320 ~ 1440)
            if normalizedTime < 360 || normalizedTime >= 1320 {
                nightMinutes += 1
            }
        }
        
        return Double(nightMinutes) / 60.0
    }
}
