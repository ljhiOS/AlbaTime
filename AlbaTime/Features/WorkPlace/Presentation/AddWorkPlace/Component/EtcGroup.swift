//
//  EtcGroup.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//

import SwiftUI

struct EtcGroup: View {
    @ObservedObject var ajvm: AddWorkPlaceViewModel
    
    let focusedField: FocusState<AddWorkPlaceField?>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading) {
                Text("휴게 시간 (선택)")
                    .font(.callout)
                HStack(spacing: 10) {
                    TextField("예: 60", value: $ajvm.session.workPlaceDraft.defaultRestTime, format: .number)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(Color.theme.field)
                        .cornerRadius(8)
                        .padding(.trailing)
                        .focused(focusedField, equals: .restTime)

                    Text("분")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.theme.textPrimary)
                    
                    Spacer()
                }
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("메모 (선택)")
                    .font(.callout)
                TextField("특이사항 입력", text: $ajvm.session.workPlaceDraft.defaultMemo, axis: .vertical)
                .padding(10)
                .padding(.bottom, 100)
                .background(Color.theme.field)
                .cornerRadius(8)
                .focused(focusedField, equals: .memo)
                .submitLabel(.done)

            }
        }
    }
}
