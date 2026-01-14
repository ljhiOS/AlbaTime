//
//  AddJobView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData

struct AddJobView: View {
    
    @StateObject var ajvm = AddJobViewModel() 
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var stateName: String
    @State var isFirst: Bool = false //true
    @State var showAlert: Bool = false
    @State var errorMessage: String = ""

    var body: some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 30) {
                
                HStack {
                    Text(stateName)
                        .font(.title)
                        .bold()
                        
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
//                            .bold()
                            .font(.title)
                    }

                }.padding()
                
                Divider()
                    .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("매장명")
                        .font(.callout)
                        .padding(.horizontal)
                    
                    TextField("예) 스타벅스 강남점", text: $ajvm.placeName)
                        .padding(10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal)
                } //:VStack
                
                VStack(alignment: .leading) {
                    Text("시급")
                        .font(.callout)
                        .padding(.horizontal)
                    
                    TextField("예) 10030", text: $ajvm.wage)
                        .padding(10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal)
                } //:VStack
                
                VStack(alignment: .leading) {
                    Text("세금 적용")
                        .font(.callout)
                        .padding(.horizontal)
                    
                    Picker("세금 종류", selection: $ajvm.taxType) {
                        ForEach(TaxType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu) 
                    .tint(.black)
                    .padding(5)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)
                    .padding(.horizontal)
                } //:VStack
                
                VStack(alignment: .leading) {
                    Text("주 근무 요일")
                        .font(.callout)
                        .padding(.horizontal)
                    
                    HStack {
                        ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                            CustomButton_day(
                                day: day,
                                isSelected: ajvm.selectedDate.contains(day),
                                action: { ajvm.toggleDay(day) }
                            )
                        }
                    }.padding(.horizontal, 8)
                    //:HStack
                    
                } //:VStack
                
                HStack(spacing: 10){
                    VStack(spacing: 0) {
                        TimePickerButton(title: "출근 시간", time: $ajvm.startTime)
                            .padding(.bottom)
                        
                        Divider() // 구분선
                            .padding(.horizontal)
                        
                        TimePickerButton(title: "퇴근 시간", time: $ajvm.endTime)
                            .padding(.top)
                    }
                } //:HStack
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("휴게 시간 (선택)")
                        .font(.callout)
                    
                    HStack(spacing: 10) {
                        TextField("예) 60", text: $ajvm.restTime)
                            .padding(10)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(8)
                            .padding(.trailing)
                        
                        
                        Text("분")
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("메모 (선택)")
                        .font(.callout)
                    
                    TextField("특이사항이나 메모를 입력하세요.", text: $ajvm.memo)
                        .padding(10)
                        .padding(.bottom, 50)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            //:VStack
        } //:ScrollViewEnd
        .safeAreaInset(edge: .bottom) {
            if isFirst {
                VStack {
                    Button {
                        if ajvm.placeName.trimmingCharacters(in: .whitespaces).isEmpty {
                            errorMessage = "매장명을 입력해주세요."
                            showAlert = true
                        } else if (Int(ajvm.wage) ?? 0) <= 0 {
                            errorMessage = "올바른 시급을 입력해주세요."
                            showAlert = true
                        } else if ajvm.selectedDate.isEmpty {
                            errorMessage = "근무 요일을 하나 이상 선택해주세요."
                            showAlert = true
                        } else {
                            ajvm.saveJob(context: modelContext)
                            dismiss()
                        }
                    } label: {
                        Text("저장하기")
                            .foregroundStyle(.white)
                            .padding()
                            .bold()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.bottom)
                            .shadow(radius: 2)
                    }
                    .alert("알림", isPresented: $showAlert) {
                        Button("확인", role: .cancel) {}
                    } message: {
                        Text(errorMessage)
                    }
                }
                
                
                
            } else {
                HStack(spacing: 20) {
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("취소")
                            .foregroundStyle(.black)
                            .padding()
                            .bold()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.leading)
                            .padding(.bottom)
                            .shadow(radius: 2)
                    }
                    Button {
                        if ajvm.placeName.trimmingCharacters(in: .whitespaces).isEmpty {
                            errorMessage = "매장명을 입력해주세요."
                            showAlert = true
                        } else if (Int(ajvm.wage) ?? 0) <= 0 {
                            errorMessage = "올바른 시급을 입력해주세요."
                            showAlert = true
                        } else if ajvm.selectedDate.isEmpty {
                            errorMessage = "근무 요일을 하나 이상 선택해주세요."
                            showAlert = true
                        } else {
                            ajvm.saveJob(context: modelContext)
                            dismiss()
                        }
                    } label: {
                        Text("추가하기")
                            .foregroundStyle(.white)
                            .padding()
                            .bold()
                            .frame(maxWidth: .infinity)
                            .background(Color.theme.primary)
                            .cornerRadius(8)
                            .padding(.trailing)
                            .padding(.bottom)
                            .shadow(radius: 2)
                    }
                    .alert("알림", isPresented: $showAlert) {
                        Button("확인", role: .cancel) {}
                    } message: {
                        Text(errorMessage)
                    }
                }
            }
        } //close safe
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    
    // 2. 뷰에 저장소(container) 주입
    return AddJobView(stateName: "알바 등록")
        .modelContainer(container)
}
