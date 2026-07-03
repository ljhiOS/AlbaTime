//
//  KeyboardUX.swift
//  AlbaTime
//
//  Created by 이준희 on 3/1/26.
//

import SwiftUI

enum KeyboardUX {
    struct Navigator<Field: Hashable> {
        let orderedFields: [Field]

        func canMovePrevious(from current: Field?) -> Bool {
            guard let current,
                  let index = orderedFields.firstIndex(of: current) else { return false }
            return index > 0
        }

        func canMoveNext(from current: Field?) -> Bool {
            guard let current,
                  let index = orderedFields.firstIndex(of: current) else { return false }
            return index < orderedFields.count - 1
        }

        func previous(from current: Field?) -> Field? {
            guard let current,
                  let index = orderedFields.firstIndex(of: current),
                  index > 0 else { return current }
            return orderedFields[index - 1]
        }

        func next(from current: Field?) -> Field? {
            guard let current else { return orderedFields.first }
            guard let index = orderedFields.firstIndex(of: current) else { return orderedFields.first }
            let nextIndex = index + 1
            return nextIndex < orderedFields.count ? orderedFields[nextIndex] : nil
        }
    }
}

enum AddWorkPlaceField: Hashable {
    case name, wage, restTime, memo
}

