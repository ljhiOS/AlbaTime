//
//  CalendarView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var cvm: CalendarViewModel
    
    @State private var showMonthPicker: Bool = false
    @State private var pickedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var pickedMonth: Int = Calendar.current.component(.month, from: Date())
    
    let weekDays = ["일", "월", "화", "수", "목", "금", "토"]

    init(viewModel: CalendarViewModel) {
        _cvm = StateObject(wrappedValue: viewModel)
    }
    
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
                        DayCell(
                            date: day,
                            isSelected: cvm.selectedDate.isSameDay(as: day),
                            hasWork: cvm.hasWork(on: day)
                        )
                        .onTapGesture {
                            cvm.selectDate(day)
                        }
                    } else {
                        Text("")
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        
            // 하단 상세 카드
            ScheduleDetailCard(
                selectedDate: cvm.selectedDate,
                schedules: cvm.selectedDateSchedules,
                totalPay: cvm.selectedDateTotalPay
            )
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
        .onAppear { cvm.load() }
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
                        cvm.applyPickedYearMonth(year: pickedYear, month: pickedMonth)
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
}
#Preview() {
    return CalendarView(
        viewModel: CalendarViewModel(
            loadCalendarWorkPlaces: PreviewCalendarWorkPlacesLoading()
        )
    )
}

@MainActor
private struct PreviewCalendarWorkPlacesLoading: CalendarWorkPlacesLoading {
    func execute() throws -> [WorkPlace] {
        []
    }
}
