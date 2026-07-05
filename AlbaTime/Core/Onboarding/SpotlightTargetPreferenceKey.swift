//
//  SpotlightTargetPreferenceKey.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import SwiftUI

struct SpotlightTargetPreferenceKey: PreferenceKey {
    static let defaultValue: [OnboardingKey: CGRect] = [:]

    static func reduce(
        value: inout [OnboardingKey: CGRect],
        nextValue: () -> [OnboardingKey: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

extension View {
    func spotlightTarget(_ key: OnboardingKey) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: SpotlightTargetPreferenceKey.self,
                    value: [key: proxy.frame(in: .global)]
                )
            }
        )
    }
}
