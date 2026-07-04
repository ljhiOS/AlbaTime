//
//  RealAchiveRecord.swift
//  AlbaTime
//
//  Created by 이준희 on 1/11/26.
//

import SwiftUI

struct RealAchiveRecord: View {
    let records: [MonthlyRecord]
    @StateObject private var ravm: RealAchiveRecordViewModel

    init(
        records: [MonthlyRecord],
        viewModel: RealAchiveRecordViewModel
    ) {
        self.records = records
        _ravm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView(
                    "기록된 내역이 없습니다",
                    systemImage: "list.bullet.clipboard",
                    description: Text("우측 상단 + 버튼을 눌러\n월별 수령액을 기록해보세요.")
                )
                .listRowBackground(Color.theme.field)
            } else {
                Section {
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
                                .foregroundStyle(Color.orange)
                        }
                        .padding(.vertical, 4)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.theme.field)
                    }
                    .onDelete { indexSet in
                        ravm.deleteRecord(at: indexSet, sortedRecords: records)
                    }
                } header: {
                    Text("삭제를 원한다면 좌로 넘기세요.")
                        .font(.footnote)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.theme.surface)
        .navigationTitle("월별 수령액 기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                ravm.resetForm()
                ravm.isAdding = true
            } label: {
                Image(systemName: "plus")
                    .tint(.black)
            }
        }
        .sheet(isPresented: $ravm.isAdding) {
            NavigationStack {
                Form {
                    Section("날짜 선택") {
                        DatePicker("수령 날짜", selection: $ravm.selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .environment(\.locale, Locale(identifier: "ko_KR")) // 달력을 한국어로 변경
                            .tint(Color.theme.primary)
                    }
                    .listRowBackground(Color.theme.field)
                    
                    Section("금액 입력") {
                        HStack {
                            Text("₩")
                            TextField("금액", text: $ravm.amountString)
                                .keyboardType(.numberPad)
                        }
                    }
                    .listRowBackground(Color.theme.field)
                }
                .scrollContentBackground(.hidden)
                .background(Color.theme.surface)
                .listRowBackground(Color.theme.field)
                .navigationTitle("새 기록 추가")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { ravm.isAdding = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            ravm.addRecord(existingRecords: records)
                        }
                        .disabled(ravm.amountString.isEmpty)
                    }
                }
            }
            .presentationDetents([.large])
        }
    }
}
