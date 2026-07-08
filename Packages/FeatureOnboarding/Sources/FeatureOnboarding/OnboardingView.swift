import SwiftUI
import DesignSystem
import CloudKit
import Core

public struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var appear = false
    @State private var featureAppeared = false
    @State private var accepted = false
    @State private var cloudStatus = CKAccountStatus.couldNotDetermine
    @Environment(LanguageManager.self) private var languageManager
    @State private var showLanguagePicker = false
    @State private var disclaimerShakeOffset: CGFloat = 0
    @State private var logoPulse = false

    private let features = [
        OnboardingFeature(
            icon: "arrow.left.arrow.right.circle.fill",
            titleKey: "onboarding.feature.track",
            descriptionKey: "onboarding.feature.track.desc"
        ),
        OnboardingFeature(
            icon: "dollarsign.arrow.circlepath",
            titleKey: "onboarding.feature.currency",
            descriptionKey: "onboarding.feature.currency.desc"
        ),
        OnboardingFeature(
            icon: "bell.badge.fill",
            titleKey: "onboarding.feature.reminders",
            descriptionKey: "onboarding.feature.reminders.desc"
        ),
        OnboardingFeature(
            icon: "icloud.fill",
            titleKey: "onboarding.feature.sync",
            descriptionKey: "onboarding.feature.sync.desc"
        ),
    ]

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            FinanceBackgroundAnimation()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.12).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 72)

                    logoSection
                        .padding(.bottom, Spacing.xl)

                    Text(LocalizedStringKey("onboarding.tagline"))
                        .font(Typography.font(for: .title2))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorTokens.textPrimary, ColorTokens.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.36), value: appear)

                    Text(LocalizedStringKey("onboarding.subtagline"))
                        .font(Typography.font(for: .body))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorTokens.textSecondary, ColorTokens.textTertiary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.top, Spacing.xs)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 15)
                        .animation(.easeOut(duration: 0.6).delay(0.48), value: appear)

                    VStack(spacing: Spacing.s) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            FeatureCard(
                                feature: feature,
                                index: index,
                                isVisible: featureAppeared
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xl)

                    if cloudStatus != .available && cloudStatus != .couldNotDetermine {
                        iCloudBanner
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.m)
                            .opacity(featureAppeared ? 1 : 0)
                            .offset(y: featureAppeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.65), value: featureAppeared)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    bottomSection
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)

                    Spacer().frame(height: 12)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .environment(\.locale, languageManager.locale)
        .id(languageManager.languageCode)
        .overlay(alignment: .top) {
            topBarOverlay
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguageSelectionSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                logoPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) { featureAppeared = true }
            }
            checkCloudStatus()
        }
    }

    private var topBarOverlay: some View {
        HStack {
            Button(action: {
                HapticFeedback.impact(.light)
                showLanguagePicker = true
            }) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "globe")
                        .font(.system(size: 13, weight: .bold))
                    Text(languageDisplayName(for: languageManager.languageCode))
                        .font(Typography.font(for: .labelEmphasis))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(ColorTokens.accent)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(ColorTokens.accent.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .stroke(ColorTokens.accent.opacity(0.15), lineWidth: 1)
                )
            }
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: appear)

            Spacer()

            Button(action: {
                HapticFeedback.impact(.light)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    onComplete()
                }
            }) {
                Text(LocalizedStringKey("onboarding.skip"))
                    .font(Typography.font(for: .labelEmphasis))
                    .foregroundStyle(ColorTokens.textSecondary)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(ColorTokens.textSecondary.opacity(0.06))
                    )
            }
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.24), value: appear)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 16)
    }

    private var logoSection: some View {
        VStack(spacing: Spacing.xs) {
            // Premium Glowing Icon Emblem
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ColorTokens.accent.opacity(logoPulse ? 0.25 : 0.15), ColorTokens.accent.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 130, height: 130)
                    .scaleEffect(logoPulse ? 1.1 : 0.9)
                
                Circle()
                    .fill(ColorTokens.surface)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [ColorTokens.accent.opacity(0.3), ColorTokens.chartTeal.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .elevation(Elevation.level2)
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTokens.accent, ColorTokens.chartTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: ColorTokens.accent.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .scaleEffect(appear ? 1 : 0.7)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.12), value: appear)
            .padding(.bottom, Spacing.xs)

            Text(LocalizedStringKey("app.name"))
                .font(.custom(AppFont.jakartaBold, size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorTokens.textPrimary, ColorTokens.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(-0.8)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 15)
                .animation(.easeOut(duration: 0.6).delay(0.18), value: appear)

            Text(LocalizedStringKey("app.subtitle"))
                .font(Typography.font(for: .bodyEmphasisItalic))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorTokens.accent, ColorTokens.chartTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
                .animation(.easeOut(duration: 0.6).delay(0.28), value: appear)
        }
    }

    private var iCloudBanner: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ColorTokens.warning)
            Text(LocalizedStringKey("onboarding.icloud.notSignedIn"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.warningLight.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(ColorTokens.warning.opacity(0.2), lineWidth: 1)
        )
    }

    private var bottomSection: some View {
        VStack(spacing: Spacing.l) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    accepted.toggle()
                    if accepted { HapticFeedback.impact(.light) }
                }
            } label: {
                HStack(spacing: Spacing.m) {
                    Image(systemName: accepted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(accepted ? ColorTokens.accent : ColorTokens.textSecondary)
                    Text(LocalizedStringKey("onboarding.disclaimer.short"))
                        .font(Typography.font(for: .body))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .offset(x: disclaimerShakeOffset)
            .opacity(featureAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.7), value: featureAppeared)

            Button {
                if accepted {
                    HapticFeedback.notification(.success)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        onComplete()
                    }
                } else {
                    HapticFeedback.notification(.warning)
                    shakeDisclaimer()
                }
            } label: {
                HStack(spacing: Spacing.s) {
                    Text(LocalizedStringKey("onboarding.start"))
                        .font(Typography.font(for: .button))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(
                            accepted
                            ? LinearGradient(
                                colors: [ColorTokens.accent, ColorTokens.accent.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [ColorTokens.textSecondary.opacity(0.4), ColorTokens.textSecondary.opacity(0.35)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                        )
                )
                .shadow(
                    color: accepted ? ColorTokens.accent.opacity(0.3) : Color.clear,
                    radius: 10,
                    x: 0,
                    y: 5
                )
            }
            .opacity(featureAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.75), value: featureAppeared)
        }
    }

    private func shakeDisclaimer() {
        let offsets: [CGFloat] = [10, -10, 8, -8, 5, -5, 0]
        for (index, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    disclaimerShakeOffset = offset
                }
            }
        }
    }

    private func languageDisplayName(for code: String) -> String {
        switch code {
        case "tr": return "Türkçe"
        case "en": return "English"
        case "es": return "Español"
        case "zh": return "简体中文"
        case "hi": return "हिन्दी"
        case "ar": return "العربية"
        default: return "English"
        }
    }

    private func checkCloudStatus() {
        Task {
            do {
                let status = try await CKContainer.default().accountStatus()
                await MainActor.run { cloudStatus = status }
            } catch {
                await MainActor.run { cloudStatus = .couldNotDetermine }
            }
        }
    }
}

private struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let descriptionKey: String
}

private struct FeatureCard: View {
    let feature: OnboardingFeature
    let index: Int
    let isVisible: Bool

    var body: some View {
        HStack(spacing: Spacing.l) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTokens.accent.opacity(0.15), ColorTokens.accent.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(ColorTokens.accent.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTokens.accent, ColorTokens.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(feature.titleKey))
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(LocalizedStringKey(feature.descriptionKey))
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.m)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(ColorTokens.accent.opacity(0.12), lineWidth: 1)
        )
        .elevation(Elevation.level1)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
        .animation(
            .spring(response: 0.52, dampingFraction: 0.76)
                .delay(0.3 + Double(index) * 0.1),
            value: isVisible
        )
    }
}
