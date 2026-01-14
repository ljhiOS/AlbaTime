//
//  CustomButton.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct CustomButton: View {
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct CustomButton_day: View {
    var day: String
    var isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            if isSelected {
                Text(day)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(10)
                    .padding(.horizontal, 3)
                    .background(Color.blue)
                    .cornerRadius(8)
            } else {
                Text(day)
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .padding(10)
                    .padding(.horizontal, 3)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)
            }
        } //:Button
        .frame(maxWidth: .infinity)
        .buttonStyle(ingButtonStyle2())

    }
}

struct ingButtonStyle2: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.25 : 1.0)
            .animation(.easeInOut(duration: 0.05), value: configuration.isPressed)
    }
}

// 점선 색깔 바꾸기 위한 버튼 스타일 커스텀 및 사용자 UX 고려 버튼 터치시 작아지는 애니메이션 기능 첨가
struct ingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(35)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(configuration.isPressed ? .blue : .gray)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .padding()
    }
}

struct PlusButton: View {
    
    @State var isShowingSheet = false
    @State var isColor = false
    @State var isPresented: Bool = false
    
    var body: some View {
        Button {
            isShowingSheet = true
            isColor = true
            
        } label: {
            VStack(spacing: 20) {
                ZStack {
                    
                    Circle()
                        .foregroundStyle(.gray.opacity(0.08))
                        .overlay (
                            Image(systemName: "plus")
                                .foregroundStyle(.blue)
                        )
                        .frame(width: 50, height: 50)
                }
                
                Text("새 알바 추가하기")
                    .foregroundStyle(.gray)
            }
        } //:Button
        .buttonStyle(ingButtonStyle())
        .sheet(isPresented: $isShowingSheet) {
            AddJobView(stateName: "알바 등록")
        } //:List
    }
}

struct TimePickerButton: View {
    let title: String
    @Binding var time: Date
    @State private var showPicker = false
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.black)
            Spacer()
            // 시간 표시 버튼
            Button {
                showPicker = true
            } label: {
                Text(time.format("a h:mm")) // "오전 9:00" 형식
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showPicker) {
            VStack {
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Text(title + " 설정")
                    .font(.headline)
                    .padding(.top, 10)
                
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                Button("완료") {
                    showPicker = false
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding()
            }
            .presentationDetents([.height(350)])  
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview("customButton") {
    CustomButton()
}

#Preview("customButton_day") {
    HStack {
            
            CustomButton_day(day: "월", isSelected: true, action: {
                print("월요일 클릭됨")
            })
            
            
            CustomButton_day(day: "화", isSelected: false, action: {})
        }
}

#Preview("PlusButton") {
    PlusButton()
}

#Preview("시간 입력 UI 테스트") {
    // 프리뷰에서 동작을 확인하기 위해 임시로 만든 래퍼 뷰
    struct TimePickerPreviewWrapper: View {
        @State private var startTime = Date()
        @State private var endTime = Date()
        
        var body: some View {
            ZStack {
                // 배경색 (아이폰 설정 화면 느낌)
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("근무 시간 설정")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    VStack(spacing: 0) {
                        TimePickerButton(title: "출근 시간", time: $startTime)
                            .padding(.bottom)
                        
                        Divider() // 구분선
                            .padding(.horizontal)
                        
                        TimePickerButton(title: "퇴근 시간", time: $endTime)
                            .padding(.top)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // 결과 확인용 텍스트
                    Text("선택된 시간:\n\(startTime.format("HH:mm")) ~ \(endTime.format("HH:mm"))")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
    }
    
    return TimePickerPreviewWrapper()
}
