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
            ColorTokens.background.opacity(0.08).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 64)

                    logoSection
                        .padding(.bottom, Spacing.xxl)

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
        .sheet(isPresented: $showLanguagePicker) {
            LanguageSelectionSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) { featureAppeared = true }
            }
            checkCloudStatus()
        }
    }

    private var logoSection: some View {
        ZStack {
            VStack(spacing: Spacing.xxs) {
                Text(LocalizedStringKey("app.name"))
                    .font(.custom(AppFont.jakartaBold, size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTokens.textPrimary, ColorTokens.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(-0.5)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 15)
                    .animation(.easeOut(duration: 0.6).delay(0.12), value: appear)

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
                    .animation(.easeOut(duration: 0.6).delay(0.24), value: appear)
            }
            
            HStack {
                Button(action: {
                    HapticFeedback.impact(.light)
                    showLanguagePicker = true
                }) {
                    Image(systemName: "globe")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ColorTokens.accent)
                        .padding(Spacing.s)
                        .background(Circle().fill(ColorTokens.accent.opacity(0.1)))
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.24), value: appear)
                
                Spacer()
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        onComplete()
                    }
                }) {
                    Text(LocalizedStringKey("onboarding.skip"))
                        .font(Typography.font(for: .buttonSmall))
                        .foregroundStyle(ColorTokens.accent)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.xs)
                        .background(Capsule().fill(ColorTokens.accent.opacity(0.08)))
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: appear)
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    private var iCloudBanner: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 16))
                .foregroundStyle(ColorTokens.warning)
            Text(LocalizedStringKey("onboarding.icloud.notSignedIn"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.warningLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(ColorTokens.warning.opacity(0.3), lineWidth: 1)
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
            .opacity(featureAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.7), value: featureAppeared)

            if accepted {
                Button {
                    HapticFeedback.notification(.success)
                    onComplete()
                } label: {
                    HStack(spacing: Spacing.s) {
                        Text(LocalizedStringKey("onboarding.start"))
                            .font(Typography.font(for: .button))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(ColorTokens.accent))
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                ))
            }
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
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(ColorTokens.accent.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ColorTokens.accent)
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
                .stroke(ColorTokens.accent.opacity(0.15), lineWidth: 1)
        )
        .elevation(Elevation.level1)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.75)
                .delay(0.3 + Double(index) * 0.1),
            value: isVisible
        )
    }
}

// ChartWaveBackground removed, replaced by FinanceBackgroundAnimation.

#Preview {
    OnboardingView(onComplete: {})
}
