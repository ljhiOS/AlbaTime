//
//  RealAchiveRecord.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import SwiftUI
import SwiftData

struct RealAchiveRecord: View {
    // 1. 뷰모델 연결 (@StateObject)
    @StateObject var ravm = RealAchiveRecordViewModel()
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 데이터 리스트 (화면 갱신을 위해 @Query는 뷰에 남겨둡니다)
    @Query(sort: [SortDescriptor(\MonthlyRecord.year, order: .reverse), SortDescriptor(\MonthlyRecord.month, order: .reverse)])
    var records: [MonthlyRecord]
    
    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView(
                    "기록된 내역이 없습니다",
                    systemImage: "list.bullet.clipboard",
                    description: Text("우측 상단 + 버튼을 눌러\n월별 수령액을 기록해보세요.")
                )
            } else {
                ForEach(records) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(String(format: "%d", record.year))년 \(record.month)월")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Text("₩\((Int(record.actualAmount) ?? 0).formatted())")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.primary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    ravm.deleteRecord(at: indexSet, context: modelContext, sortedRecords: records)
                }
            }
        }
        .navigationTitle("월별 수령액 기록")
        .toolbar {
            Button {
                ravm.resetForm()
                ravm.isAdding = true
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.theme.primary)
            }
        }
        .sheet(isPresented: $ravm.isAdding) {
            NavigationStack {
                Form {
                    Section("날짜 선택") {
                        DatePicker("수령 날짜", selection: $ravm.selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .environment(\.locale, Locale(identifier: "ko_KR")) // 달력을 한국어로 변경
                    }
                    
                    Section("금액 입력") {
                        HStack {
                            Text("₩")
                            TextField("금액", text: $ravm.amountString)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                .navigationTitle("새 기록 추가")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { ravm.isAdding = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            ravm.addRecord(context: modelContext, existingRecords: records)
                        }
                        .disabled(ravm.amountString.isEmpty)
                    }
                }
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    RealAchiveRecord()
        .modelContainer(for: MonthlyRecord.self, inMemory: true)
}
