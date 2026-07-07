import SwiftUI
import DesignSystem

// MARK: - Onboarding

public struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0
    @State private var accepted = false
    @State private var appear = false

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            ColorTokens.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Premium progress indicator
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(page >= i ? ColorTokens.accent : ColorTokens.border)
                            .frame(width: page == i ? 24 : 6, height: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.top, Spacing.xxl)

                // Pages
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    featuresPage.tag(1)
                    privacyPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)

                // Bottom bar
                bottomBar
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.xxxl)
            }
        }
        .opacity(appear ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appear = true } }
    }

    // MARK: Page 1 — Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Premium animated icon
            ZStack {
                Circle()
                    .fill(ColorTokens.accent.opacity(0.08))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(ColorTokens.accent.opacity(0.15), lineWidth: 1)
                    .frame(width: 150, height: 150)
                    .scaleEffect(appear ? 1 : 0.8)
                    .opacity(appear ? 0.6 : 0)
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ColorTokens.accent)
                    .symbolEffect(.bounce.up.byLayer, options: .repeating.speed(0.3), value: page == 0)
            }
            .padding(.bottom, Spacing.xxl)

            Text("Vade")
                .font(Typography.font(for: .display))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.bottom, Spacing.s)

            Text(String(localized: "onboarding.welcome.subtitle"))
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xxxl)
                .padding(.bottom, Spacing.huge)

            // Glassmorphism card
            HStack(spacing: Spacing.l) {
                Label(String(localized: "onboarding.welcome.tagline"), systemImage: "sparkles")
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.accent)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .glass(GlassStyle.subtle)

            Spacer()
        }
    }

    // MARK: Page 2 — Features

    private var featuresPage: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ColorTokens.accent.opacity(0.06))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 36))
                    .foregroundStyle(ColorTokens.accent)
            }
            .padding(.bottom, Spacing.xxl)

            Text(String(localized: "onboarding.features.title"))
                .font(Typography.font(for: .title))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.bottom, Spacing.xxl)

            VStack(spacing: Spacing.m) {
                FeatureCard(
                    icon: "arrow.left.arrow.right",
                    iconColor: ColorTokens.chartBlue,
                    title: String(localized: "onboarding.feature.track"),
                    subtitle: String(localized: "onboarding.feature.track.detail")
                )
                FeatureCard(
                    icon: "chart.bar.fill",
                    iconColor: ColorTokens.chartPurple,
                    title: String(localized: "onboarding.feature.insights"),
                    subtitle: String(localized: "onboarding.feature.insights.detail")
                )
                FeatureCard(
                    icon: "bell.badge.fill",
                    iconColor: ColorTokens.chartOrange,
                    title: String(localized: "onboarding.feature.reminders"),
                    subtitle: String(localized: "onboarding.feature.reminders.detail")
                )
                FeatureCard(
                    icon: "lock.shield.fill",
                    iconColor: ColorTokens.positive,
                    title: String(localized: "onboarding.privacy.title"),
                    subtitle: String(localized: "onboarding.feature.privacy.detail")
                )
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }

    // MARK: Page 3 — Privacy + Start

    private var privacyPage: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ColorTokens.positive.opacity(0.06))
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(ColorTokens.positive.opacity(0.1), lineWidth: 1)
                    .frame(width: 130, height: 130)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(ColorTokens.positive)
            }
            .padding(.bottom, Spacing.xxl)

            Text(String(localized: "onboarding.privacy.title"))
                .font(Typography.font(for: .title))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.bottom, Spacing.s)

            Text(String(localized: "onboarding.privacy.subtitle"))
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xxxl)

            Spacer()
        }
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: Spacing.m) {
            if page < 2 {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        page += 1
                    }
                } label: {
                    Text(String(localized: "onboarding.continue"))
                        .font(Typography.font(for: .button))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(ColorTokens.accent))
                }

                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        page = 2
                    }
                } label: {
                    Text(String(localized: "onboarding.skip"))
                        .font(Typography.font(for: .buttonSmall))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            } else {
                // Disclaimer checkbox
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        accepted.toggle()
                    }
                } label: {
                    HStack(spacing: Spacing.m) {
                        Image(systemName: accepted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(accepted ? ColorTokens.accent : ColorTokens.border)
                        Text(String(localized: "onboarding.disclaimer.short"))
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, Spacing.m)

                // CTA
                Button(action: onComplete) {
                    Text(String(localized: "onboarding.start"))
                        .font(Typography.font(for: .button))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Capsule().fill(accepted ? ColorTokens.accent : ColorTokens.border)
                        )
                }
                .disabled(!accepted)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: accepted)
            }
        }
    }
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Spacing.l) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(subtitle)
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
