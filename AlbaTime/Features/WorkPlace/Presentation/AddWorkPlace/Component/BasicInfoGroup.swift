//
//  BasicInfoGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct BasicInfoGroup: View {
    @ObservedObject var session: WorkPlaceEditingSession
    
    let focusedField: FocusState<AddWorkPlaceField?>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading) {
                Text("매장명").font(.callout)
                TextField("예) 스타벅스 강남점", text: $session.workPlaceDraft.name)
                    .padding(10)
                    .background(Color.theme.field)
                    .cornerRadius(8)
                    .focused(focusedField, equals: .name)
                    .submitLabel(.next)

            }
            VStack(alignment: .leading) {
                Text("시급")
                    .font(.callout)
                
                let wageProxy = Binding<String>(
                    get: { session.workPlaceDraft.hourlyWage == 0 ? "" : String(session.workPlaceDraft.hourlyWage) },
                    set: { session.workPlaceDraft.hourlyWage = Int($0) ?? 0 }
                )
                
                
                TextField("예) 10320", text: wageProxy) // value가 아니라 text 사용
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color.theme.field)
                    .cornerRadius(8)
                    .focused(focusedField, equals: .wage)
                
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("세금 적용")
                        .font(.callout)
                    Picker("세금 종류", selection: $session.workPlaceDraft.taxType) {
                        ForEach(TaxType.allCases, id: \.self) { type in Text(type.rawValue).tag(type) }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.theme.textPrimary)
                    .padding(5)
                    .background(Color.theme.field).cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("수당 적용")
                        .font(.callout)
                    Picker("수당 종류", selection: $session.workPlaceDraft.allowanceType) {
                        ForEach(AllowanceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.theme.textPrimary)
                    .padding(5)
                    .background(Color.theme.field)
                    .cornerRadius(8)
                }
            }
        }
    }
}
