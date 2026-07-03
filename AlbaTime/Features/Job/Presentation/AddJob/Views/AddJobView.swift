//
//  AddJobView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct AddJobView: View {
    @StateObject private var ajvm: AddJobViewModel
    @Environment(\.dismiss) private var dismiss

    var stateName: String

    @FocusState private var focusedField: AddJobField?
    private let keyboardNav = KeyboardUX.Navigator<AddJobField>(
        orderedFields: [.name, .wage, .restTime, .memo]
    )

    init(
        stateName: String = "근무지 등록",
        editingSeed: JobEditingSeed? = nil,
        selectedType: WorkType? = nil,
        jobSaving: any JobSaving
    ) {
        if let editingSeed {
            self.stateName = "근무지 수정"
            _ajvm = StateObject(wrappedValue: AddJobViewModel(editingSeed: editingSeed, jobSaving: jobSaving))
        } else {
            self.stateName = stateName
            let type = selectedType ?? .fixed
            _ajvm = StateObject(wrappedValue: AddJobViewModel(type: type, jobSaving: jobSaving))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                BasicInfoGroup(session: ajvm.session, focusedField: $focusedField)
                    .padding(.horizontal)

                Divider().padding(.horizontal)

                if ajvm.session.jobDraft.workType == .fixed {
                    ScheduleGroup(ajvm: ajvm)
                        .padding(.horizontal)
                } else {
                    FlexibleInfoGroup(session: ajvm.session)
                        .padding(.horizontal)
                }

                Divider().padding(.horizontal)

                EtcGroup(ajvm: ajvm, focusedField: $focusedField)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color.theme.surface)
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    ajvm.validateAndOpenAI()
                } label: {
                    HStack(spacing: 4) { Image(systemName: "sparkles"); Text("AI 스케줄") }
                        .font(.caption).bold()
                        .foregroundStyle(Color.theme.primary)
                        .padding(6)
                        .background(Color.theme.primary.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    focusedField = keyboardNav.previous(from: focusedField)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                }
                .disabled(!keyboardNav.canMovePrevious(from: focusedField))

                Button {
                    focusedField = keyboardNav.next(from: focusedField)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                }
                .disabled(!keyboardNav.canMoveNext(from: focusedField))

                Spacer(minLength: 8)

                Button {
                    focusedField = nil
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .navigationTitle(stateName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $ajvm.isAIImportPresented) {
            ScheduleImportRoute(session: ajvm.session)
        }
        .onDisappear {
            ajvm.restoreEditsIfNeeded()
        }
        .safeAreaInset(edge: .bottom) {
            if focusedField == nil {
                BottomButton(title: "저장하기", action: {
                    if ajvm.save() { dismiss() }
                })
            }
        }
        .alert("알림", isPresented: $ajvm.showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(ajvm.errorMessage)
        }
    }
}

#Preview("순수 AddJobView") {
    NavigationStack {
        AddJobView(
            stateName: "알바 등록",
            selectedType: .fixed,
            jobSaving: PreviewAddJobSaving()
        )
    }
}

@MainActor
private struct PreviewAddJobSaving: JobSaving {
    func execute(_ command: JobSaveCommand) throws { }
}
