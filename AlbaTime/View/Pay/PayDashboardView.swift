//
//  PayDashboardView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData

struct PayDashboardView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @Query var workplaces: [Workplace]
    
    @StateObject private var pvm = PayViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                PayCard(
                    totalPay: pvm.salaryData.totalPay,
                    totalHours: pvm.salaryData.totalHours,
                    averageWage: pvm.averageWage
                )
                .padding(.top)
                
                PayDetailCard(
                    basicPay: pvm.salaryData.basicPay,
                    nightPay: pvm.salaryData.nightPay,
                    holidayPay: pvm.salaryData.holidayPay,
                    taxAmount: pvm.salaryData.taxAmount,
                    totalPay: pvm.salaryData.totalPay,
                    totalHours: pvm.salaryData.totalHours,
                    workingDays: pvm.salaryData.workingDays
                )
            
                RealAchivePay()
            }
            .padding(.horizontal)
        }
        .background(Color.theme.surface)
        // 데이터가 로드되거나 변경될 때마다 ViewModel 업데이트
        .onAppear {
            pvm.updateData(workplaces: workplaces)
        }
        .onChange(of: workplaces) { oldValue, newValue in

            pvm.updateData(workplaces: newValue)
        }
        // 월이 바뀌었을 때도 업데이트 필요하다면 추가
        .onChange(of: pvm.currentMonth) { oldValue, newValue in
            pvm.updateData(workplaces: workplaces)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                pvm.updateData(workplaces: workplaces)
            }
        }
    }
}

#Preview {
    NavigationStack{
        
        // 1. 메모리 전용 SwiftData 컨테이너 설정
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // ❌ WorkRecord.self 제거
        let container = try! ModelContainer(for: Workplace.self, configurations: config)
        
        // 2. 샘플 근무지(Workplace) 생성
        let place = Workplace(
            name: "GS25 강남점",
            hourlyWage: 10000,
            defaultDays: "월,수,금",
            defaultStartTime: Date(),
            defaultEndTime: Date().addingTimeInterval(3600 * 8) // 8시간 근무
        )
        container.mainContext.insert(place)
        
        // ❌ WorkRecord 생성 및 insert 코드 전부 삭제
        
        // 4. 컨테이너를 주입한 뷰 반환
        return PayDashboardView()
            .modelContainer(container)
    }
}
