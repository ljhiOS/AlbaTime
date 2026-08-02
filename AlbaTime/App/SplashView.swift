//
//  SplashView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/29/25.
//
import SwiftUI

struct SplashView: View {
    @AppStorage(AnalyticsConsentStore.decisionKey) private var hasDecided = false
    @State private var isSplashFinished = false
    @State private var size: Double = 0.7
    @State private var opacity: Double = 0.5

    var body: some View {
        ZStack {
            Color.theme.surface
                .ignoresSafeArea()

            if !isSplashFinished {
                splashContent
            } else if hasDecided {
                MainTabView()
            } else {
                AnalyticsConsentView { isGranted in
                    AnalyticsConsentStore.setConsent(isGranted)
                    hasDecided = true
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var splashContent: some View {
        VStack(spacing: 20) {
            Image("AppIconImage")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
        }
        .scaleEffect(size)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                size = 1.0
                opacity = 1.0

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSplashFinished = true
                    }
                }
            }
        }
    }
}

struct AnalyticsConsentView: View {
    let onDecision: (Bool) -> Void

    @State private var isShowingPrivacyPolicy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                informationCard
                privacyPolicyButton
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color.theme.surface.ignoresSafeArea())
        .tint(Color.theme.primary)
        .sheet(isPresented: $isShowingPrivacyPolicy) {
            NavigationStack {
                PersonalInfo()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.theme.primary)
                .frame(width: 64, height: 64)
                .background(Color.theme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("서비스 이용 분석 설정")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text("알바타임을 더 나은 앱으로 만들기 위해 사용 패턴을 분석합니다.")
                    .font(.body)
                    .foregroundStyle(Color.theme.textPrimary)
                    .lineSpacing(3)

                Text("동의하지 않아도 앱의 모든 기본 기능을 사용할 수 있으며, 나중에 설정에서 변경할 수 있습니다.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    private var informationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("수집될 수 있는 정보")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            VStack(spacing: 0) {
                AnalyticsConsentInfoRow(
                    systemName: "chart.bar.fill",
                    title: "앱 사용 이벤트",
                    description: "화면 이동과 기능 사용 등"
                )

                divider

                AnalyticsConsentInfoRow(
                    systemName: "iphone",
                    title: "앱·운영체제·기기 정보",
                    description: "앱의 안정성과 이용 현황 확인"
                )

                divider

                AnalyticsConsentInfoRow(
                    systemName: "clock.fill",
                    title: "앱 인스턴스·세션 정보",
                    description: "방문 및 사용 흐름을 파악하기 위한 정보"
                )
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.theme.primary)

                Text("급여, 근무지, 메모 등 사용자가 입력한 내용은 Analytics 이벤트에 포함하지 않습니다.")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(18)
        .background(Color.theme.field)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var privacyPolicyButton: some View {
        Button {
            isShowingPrivacyPolicy = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 28, height: 28)
                    .background(Color.theme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("개인정보처리방침 확인")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding(16)
            .background(Color.theme.subtle)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onDecision(true)
            } label: {
                Text("동의하고 계속하기")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onDecision(false)
            } label: {
                Text("동의하지 않고 계속하기")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
    }

    private var divider: some View {
        Divider()
            .overlay(Color.theme.borderSoft)
            .padding(.leading, 40)
    }
}

private struct AnalyticsConsentInfoRow: View {
    let systemName: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.theme.primary)
                .frame(width: 28, height: 28)
                .background(Color.theme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    SplashView()
}

#Preview("Analytics Consent") {
    AnalyticsConsentView { _ in }
}
