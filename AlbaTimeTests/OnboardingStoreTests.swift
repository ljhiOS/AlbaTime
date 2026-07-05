//
//  OnboardingStoreTests.swift
//  AlbaTimeTests
//
//  Created by 이준희 on 7/5/26.
//

import XCTest
@testable import AlbaTime

final class OnboardingStoreTests: XCTestCase {
    func testMarkSeenPersistsOnboardingKey() {
        let defaults = UserDefaults(suiteName: "OnboardingStoreTests.markSeen")!
        defaults.removePersistentDomain(forName: "OnboardingStoreTests.markSeen")
        let store = UserDefaultsOnboardingStore(defaults: defaults)

        XCTAssertFalse(store.hasSeen(.addWorkPlaceAICondition))

        store.markSeen(.addWorkPlaceAICondition)

        XCTAssertTrue(store.hasSeen(.addWorkPlaceAICondition))
    }

    func testResetRemovesAllOnboardingKeys() {
        let defaults = UserDefaults(suiteName: "OnboardingStoreTests.reset")!
        defaults.removePersistentDomain(forName: "OnboardingStoreTests.reset")
        let store = UserDefaultsOnboardingStore(defaults: defaults)

        OnboardingKey.allCases.forEach { store.markSeen($0) }
        store.reset()

        XCTAssertTrue(OnboardingKey.allCases.allSatisfy { !store.hasSeen($0) })
    }
}
