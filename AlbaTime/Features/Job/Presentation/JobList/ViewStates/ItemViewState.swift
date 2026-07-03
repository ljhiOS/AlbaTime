//
//  JobListViewState.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

struct JobListItemViewState: Identifiable, Hashable {
    let id: UUID
    let card: JobCardViewState
    let detail: JobDetailViewState
    let editingSeed: JobEditingSeed

    init(
        card: JobCardViewState,
        detail: JobDetailViewState,
        editingSeed: JobEditingSeed
    ) {
        self.id = card.id
        self.card = card
        self.detail = detail
        self.editingSeed = editingSeed
    }
}
