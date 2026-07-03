//
//  DaySelectUI.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//
import SwiftUI

struct DaySelectUIChip<ID: Hashable>: Identifiable {
    let id: ID
    let title: String
    let hasSchedule: Bool
}

struct DaySelectUIState<ID: Hashable> {
    let chips: [DaySelectUIChip<ID>]
    let selectedID: ID?
    let startTime: Date?
    let endTime: Date?
    let emptyMessage: String
    let addButtonTitle: String?
}

enum DaySelectUIAction<ID: Hashable> {
    case tapDay(ID)
    case longPressDay(ID)
    case tapAdd
    case changeStartTime(Date)
    case changeEndTime(Date)
}

struct DaySelectUI<ID: Hashable>: View {
    let state: DaySelectUIState<ID>
    let send: (DaySelectUIAction<ID>) -> Void

    private let twentyFourHourLocale = Locale(identifier: "ko_KR@hc=h23")

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("요일 선택")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(state.chips) { chip in
                    let isSelected = state.selectedID == chip.id

                    Text(chip.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : (chip.hasSchedule ? Color.theme.primary : .primary))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            isSelected
                            ? Color.theme.primary
                            : (chip.hasSchedule ? Color.theme.primary.opacity(0.15) : Color.theme.surface)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            send(.tapDay(chip.id))
                        }
                        .onLongPressGesture(minimumDuration: 0.25) {
                            send(.longPressDay(chip.id))
                        }
                }
            }

            if let startTime = state.startTime, let endTime = state.endTime {
                HStack {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { startTime },
                            set: { send(.changeStartTime($0)) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .environment(\.locale, twentyFourHourLocale)

                    Text("~")
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { endTime },
                            set: { send(.changeEndTime($0)) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .environment(\.locale, twentyFourHourLocale)

                    Spacer()
                }

                Text("삭제를 원하면 요일 버튼을 길게 눌러주세요.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(state.emptyMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let addButtonTitle = state.addButtonTitle {
                        Button {
                            send(.tapAdd)
                        } label: {
                            Text(addButtonTitle)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.theme.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.theme.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color.theme.field)
        .cornerRadius(8)
    }
}


