//
//  AddWorkPlaceView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct AddWorkPlaceView: View {
    @StateObject private var ajvm: AddWorkPlaceViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onboarding.addWorkPlaceAICondition") private var hasSeenAIConditionOnboarding = false

    var stateName: String

    @FocusState private var focusedField: AddWorkPlaceField?
    private let keyboardNav = KeyboardUX.Navigator<AddWorkPlaceField>(
        orderedFields: [.name, .wage, .restTime, .memo]
    )

    init(
        stateName: String = "근무지 등록",
        editingSeed: WorkPlaceEditingSeed? = nil,
        selectedType: WorkType? = nil,
        workPlaceSaving: any WorkPlaceSaving
    ) {
        if let editingSeed {
            self.stateName = "근무지 수정"
            _ajvm = StateObject(wrappedValue: AddWorkPlaceViewModel(editingSeed: editingSeed, workPlaceSaving: workPlaceSaving))
        } else {
            self.stateName = stateName
            let type = selectedType ?? .fixed
            _ajvm = StateObject(wrappedValue: AddWorkPlaceViewModel(type: type, workPlaceSaving: workPlaceSaving))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                BasicInfoGroup(session: ajvm.session, focusedField: $focusedField)
                    .padding(.horizontal)

                Divider().padding(.horizontal)

                if ajvm.session.workPlaceDraft.workType == .fixed {
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
                HStack(spacing: 12) {
                    Button {
                        focusedField = keyboardNav.previous(from: focusedField)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                    }
                    .disabled(!keyboardNav.canMovePrevious(from: focusedField))

                    Button {
                        focusedField = keyboardNav.next(from: focusedField)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                    }
                    .disabled(!keyboardNav.canMoveNext(from: focusedField))

                    Spacer(minLength: 8)

                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .padding(.bottom, 10)
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
        .overlay {
            if !hasSeenAIConditionOnboarding {
                ZStack(alignment: .topTrailing) {
                    Color.gray.opacity(0.62)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hasSeenAIConditionOnboarding = true
                        }

                    AddWorkPlaceAIConditionHint {
                        hasSeenAIConditionOnboarding = true
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 16)
                }
            }
        }
    }

}

private struct AddWorkPlaceAIConditionHint: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                Text("1/1")
                    .font(.caption.bold())
                Spacer()
                Button("건너뛰기", action: onDismiss)
                    .font(.caption.bold())
            }
            .foregroundStyle(Color.theme.primary)

            Text("매장명과 시급을 입력하면 AI 스케줄을 사용할 수 있어요.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("화면 아무 곳이나 누르면 닫혀요.")
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 8)
        .onTapGesture(perform: onDismiss)
    }
}

#Preview("순수 AddWorkPlaceView") {
    NavigationStack {
        AddWorkPlaceView(
            stateName: "알바 등록",
            selectedType: .fixed,
            workPlaceSaving: PreviewAddWorkPlaceSaving()
        )
    }
}

@MainActor
private struct PreviewAddWorkPlaceSaving: WorkPlaceSaving {
    func execute(_ command: SaveWorkPlaceCommand) throws { }
}
