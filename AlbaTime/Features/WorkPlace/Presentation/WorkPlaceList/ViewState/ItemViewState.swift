//
//  WorkPlaceListViewState.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

struct WorkPlaceListItemViewState: Identifiable, Hashable {
    let id: UUID
    let card: WorkPlaceCardViewState
    let detail: WorkPlaceDetailViewState
    let editingSeed: WorkPlaceEditingSeed

    init(
        card: WorkPlaceCardViewState,
        detail: WorkPlaceDetailViewState,
        editingSeed: WorkPlaceEditingSeed
    ) {
        self.id = card.id
        self.card = card
        self.detail = detail
        self.editingSeed = editingSeed
    }
}
