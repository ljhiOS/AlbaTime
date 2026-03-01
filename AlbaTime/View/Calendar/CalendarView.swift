//
//  CalendarView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @StateObject private var cvm = CalendarViewModel()
    @Query var workplaces: [Workplace] // 데이터베이스 감지
    @Query var workSchedules: [WorkSchedule]
    @State private var showMonthPicker: Bool = false
    @State private var pickedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var pickedMonth: Int = Calendar.current.component(.month, from: Date())
    
    let weekDays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 상단 헤더
            HStack {
                Text("캘린더")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                Spacer()
            }
            
            // 월 이동 버튼
            ZStack {
                HStack {
                    Button(action: { cvm.changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left").foregroundColor(Color.theme.textPrimary)
                    }
                    Spacer()
                    Button(action: { cvm.changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right").foregroundColor(Color.theme.textPrimary)
                    }
                }

                Button {
                    let calendar = Calendar.current
                    pickedYear = calendar.component(.year, from: cvm.currentMonth)
                    pickedMonth = calendar.component(.month, from: cvm.currentMonth)
                    showMonthPicker = true
                } label: {
                    HStack(spacing: 4) {
                        // 좌우 균형용 더미 아이콘 (텍스트를 화면 정중앙에 고정)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .opacity(0)
                        Text(cvm.currentMonth.format("yyyy년 M월"))
                            .font(.headline)
                            .fontWeight(.bold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // 요일 표시
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 10)
            .padding(.horizontal)
            
            // 달력 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 20) {
                let days = cvm.generateDaysInMonth()
                
                ForEach(0..<days.count, id: \.self) { index in
                    if let day = days[index] {
                        let jobsOnThisDay = cvm.getScheduledWorkplaces(for: day, allWorkplaces: workplaces)
                        
                        DayCell(
                            date: day,
                            isSelected: cvm.selectedDate.isSameDay(as: day),
                            todayJobs: jobsOnThisDay
                        )
                        .onTapGesture {
                            cvm.selectedDate = day
                        }
                    } else {
                        Text("")
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        
            // 하단 상세 카드
            ScheduleDetailCard(cvm: cvm, allWorkplaces: workplaces)
        }
        .background(Color.theme.surface)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < -40 {
                        cvm.changeMonth(by: 1)
                    } else if value.translation.width > 40 {
                        cvm.changeMonth(by: -1)
                    }
                }
        )
        .onAppear { cvm.updateCache(workplaces: workplaces) }
        .onChange(of: workplaces) { _, newValue in cvm.updateCache(workplaces: newValue) }
        .onChange(of: workSchedules.count) { _, _ in
            cvm.updateCache(workplaces: workplaces)
        }
        .onChange(of: cvm.currentMonth) { _, _ in cvm.updateCache(workplaces: workplaces) }
        .sheet(isPresented: $showMonthPicker) {
            NavigationStack {
                VStack(spacing: 18) {
                    HStack(spacing: 12) {
                        Picker("년도", selection: $pickedYear) {
                            ForEach((2020...2035), id: \.self) { year in
                                Text(verbatim: "\(year)년").tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        
                        Picker("월", selection: $pickedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(verbatim: "\(month)월").tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 160)
                    
                    Button("적용") {
                        applyPickedYearMonth()
                        showMonthPicker = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("연도/월 선택")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("취소") { showMonthPicker = false }
                    }
                }
            }
            .presentationDetents([.height(280)])
        }
    }
    
    private func applyPickedYearMonth() {
        let calendar = Calendar.current
        var comp = calendar.dateComponents([.hour, .minute, .second], from: cvm.currentMonth)
        comp.year = pickedYear
        comp.month = pickedMonth
        comp.day = 1
        
        if let date = calendar.date(from: comp) {
            cvm.currentMonth = date
        }
    }
}
#Preview() {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    
    let starbucks = Workplace(
        name: "스타벅스",
        hourlyWage: 10300,
        defaultDays: "월/화/수/목/금/토/일",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        defaultRestTime: 60
    )
    container.mainContext.insert(starbucks)
    
    return CalendarView()
        .modelContainer(container)
}
