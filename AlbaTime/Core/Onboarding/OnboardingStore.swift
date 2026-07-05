//
//  OnboardingStore.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import Foundation

protocol OnboardingStoring {
    func hasSeen(_ key: OnboardingKey) -> Bool
    func markSeen(_ key: OnboardingKey)
    func reset()
}

struct UserDefaultsOnboardingStore: OnboardingStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasSeen(_ key: OnboardingKey) -> Bool {
        defaults.bool(forKey: storageKey(for: key))
    }

    func markSeen(_ key: OnboardingKey) {
        defaults.set(true, forKey: storageKey(for: key))
    }

    func reset() {
        OnboardingKey.allCases.forEach {
            defaults.removeObject(forKey: storageKey(for: $0))
        }
    }

    private func storageKey(for key: OnboardingKey) -> String {
        "onboarding.\(key.rawValue)"
    }
}
