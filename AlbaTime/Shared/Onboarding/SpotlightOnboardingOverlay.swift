//
//  SpotlightOnboardingOverlay.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import SwiftUI

struct SpotlightOnboardingStep: Identifiable {
    let key: OnboardingKey
    let message: String

    var id: OnboardingKey { key }
}

struct SpotlightOnboardingOverlay: View {
    let targetGlobalFrame: CGRect
    let step: SpotlightOnboardingStep
    let stepIndex: Int
    let stepCount: Int
    let onAdvance: () -> Void
    let onSkip: () -> Void

    @State private var bubbleSize: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let overlayGlobalFrame = proxy.frame(in: .global)
            let targetFrame = targetGlobalFrame.offsetBy(
                dx: -overlayGlobalFrame.minX,
                dy: -overlayGlobalFrame.minY
            )

            ZStack {
                dimmedBackground(
                    targetFrame: targetFrame,
                    key: step.key
                )
                    .onTapGesture(perform: onAdvance)

                messageBubble(in: proxy.size, targetFrame: targetFrame, key: step.key)
                    .onTapGesture(perform: onAdvance)
            }
            .onPreferenceChange(SpotlightBubbleSizePreferenceKey.self) { size in
                bubbleSize = size
            }
            .animation(.easeInOut(duration: 0.2), value: targetGlobalFrame)
        }
    }

    private func dimmedBackground(
        targetFrame: CGRect,
        key: OnboardingKey
    ) -> some View {
        ZStack {
            Color.gray.opacity(0.62)
                .ignoresSafeArea(edges: .bottom)

            RoundedRectangle(cornerRadius: key.spotlightCornerRadius)
                .frame(
                    width: targetFrame.width + key.spotlightPadding * 2,
                    height: targetFrame.height + key.spotlightPadding * 2
                )
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    private func messageBubble(
        in size: CGSize,
        targetFrame: CGRect,
        key: OnboardingKey
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                Text("\(stepIndex + 1)/\(stepCount)")
                    .font(.caption.bold())
                Spacer()
                Button("건너뛰기", action: onSkip)
                    .font(.caption.bold())
            }
            .foregroundStyle(Color.theme.primary)

            Text(step.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("화면 아무 곳이나 누르면 다음으로 넘어가요.")
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .padding(14)
        .frame(width: min(size.width - 32, 320), alignment: .leading)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 8)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: SpotlightBubbleSizePreferenceKey.self,
                    value: proxy.size
                )
            }
        )
        .position(bubblePosition(in: size, targetFrame: targetFrame, key: key))
    }

    private func bubblePosition(
        in size: CGSize,
        targetFrame: CGRect,
        key: OnboardingKey
    ) -> CGPoint {
        let bubbleWidth = min(size.width - 32, 320)
        let bubbleHeight = max(bubbleSize.height, 128)
        let spacing: CGFloat = 24
        let x = min(max(targetFrame.midX, bubbleWidth / 2 + 16), size.width - bubbleWidth / 2 - 16)

        if key.keepsBubbleBelowTarget {
            let preferredY = targetFrame.maxY + spacing + bubbleHeight / 2
            let maxY = size.height - bubbleHeight / 2 - 16
            return CGPoint(x: x, y: min(preferredY, maxY))
        }

        if targetFrame.maxY + bubbleHeight + spacing < size.height {
            return CGPoint(x: x, y: targetFrame.maxY + spacing + bubbleHeight / 2)
        }

        return CGPoint(x: x, y: max(bubbleHeight / 2 + 16, targetFrame.minY - spacing - bubbleHeight / 2))
    }
}

private struct SpotlightBubbleSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
