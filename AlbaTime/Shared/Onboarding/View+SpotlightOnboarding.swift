//
//  View+SpotlightOnboarding.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import SwiftUI

extension View {
    func spotlightOnboarding(
        steps: [SpotlightOnboardingStep],
        store: OnboardingStoring = UserDefaultsOnboardingStore()
    ) -> some View {
        modifier(SpotlightOnboardingModifier(steps: steps, store: store))
    }
}

private struct SpotlightOnboardingModifier: ViewModifier {
    let steps: [SpotlightOnboardingStep]
    let store: OnboardingStoring

    @State private var targetFrames: [OnboardingKey: CGRect] = [:]
    @State private var currentStep: SpotlightOnboardingStep?

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(SpotlightTargetPreferenceKey.self) { frames in
                targetFrames = frames
                startIfNeeded()
            }
            .onAppear {
                startIfNeeded()
            }
            .overlay {
                if let currentStep,
                   let targetFrame = targetFrames[currentStep.key],
                   let index = steps.firstIndex(where: { $0.key == currentStep.key }) {
                    SpotlightOnboardingOverlay(
                        targetGlobalFrame: targetFrame,
                        step: currentStep,
                        stepIndex: index,
                        stepCount: steps.count,
                        onAdvance: advance,
                        onSkip: skip
                    )
                    .ignoresSafeArea()
                }
            }
    }

    private func startIfNeeded() {
        guard currentStep == nil else { return }
        currentStep = steps.first {
            !store.hasSeen($0.key) && targetFrames[$0.key] != nil
        }
    }

    private func advance() {
        guard let currentStep else { return }
        store.markSeen(currentStep.key)
        self.currentStep = steps.first {
            !store.hasSeen($0.key) && targetFrames[$0.key] != nil
        }
    }

    private func skip() {
        steps.forEach { store.markSeen($0.key) }
        currentStep = nil
    }
}
