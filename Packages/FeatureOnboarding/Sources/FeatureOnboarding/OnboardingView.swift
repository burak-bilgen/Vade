import SwiftUI
import DesignSystem

// MARK: - Onboarding View

public struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var hasAcceptedDisclaimer = false
    @State private var iconBounce = false

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(
                colors: [
                    Color(white: 0.08),
                    Color(white: 0.14),
                    Color(white: 0.10),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button(String(localized: "onboarding.skip")) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage = 2
                            }
                        }
                        .font(Typography.font(for: .body))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.trailing, Spacing.l)
                        .padding(.top, Spacing.xl)
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    featuresPage.tag(1)
                    startPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.55, dampingFraction: 0.8), value: currentPage)

                // Bottom controls
                bottomControls
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxxl)
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()

            // Animated icon
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorTokens.accent, ColorTokens.accentLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce.up.byLayer, options: .repeating, value: iconBounce)
                .padding(.bottom, Spacing.xxxl)

            Text(String(localized: "onboarding.welcome.title"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.m)

            Text(String(localized: "onboarding.welcome.subtitle"))
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xxxl)

            Spacer()
            Spacer()
        }
        .onAppear { iconBounce = true }
        .onDisappear { iconBounce = false }
    }

    // MARK: - Page 2: Features

    private var featuresPage: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(String(localized: "onboarding.features.title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)

            VStack(spacing: Spacing.xl) {
                featureRow(
                    icon: "arrow.left.arrow.right",
                    title: String(localized: "onboarding.feature.track"),
                    subtitle: String(localized: "onboarding.feature.track.desc")
                )
                featureRow(
                    icon: "chart.bar.fill",
                    title: String(localized: "onboarding.feature.insights"),
                    subtitle: String(localized: "onboarding.feature.insights.desc")
                )
                featureRow(
                    icon: "bell.badge.fill",
                    title: String(localized: "onboarding.feature.reminders"),
                    subtitle: String(localized: "onboarding.feature.reminders.desc")
                )
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.l) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(ColorTokens.accent)
                .frame(width: 40, height: 40)
                .background(ColorTokens.accent.opacity(0.12))
                .clipShape(.rect(cornerRadius: Radius.md))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Page 3: Start

    private var startPage: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(ColorTokens.accent)
                .padding(.bottom, Spacing.xl)

            Text(String(localized: "onboarding.privacy.title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.m)

            Text(String(localized: "onboarding.privacy.subtitle"))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xxxl)
                .padding(.bottom, Spacing.xxxl)

            // Privacy highlights
            VStack(spacing: Spacing.m) {
                privacyBadge(String(localized: "onboarding.privacy.icloud"))
                privacyBadge(String(localized: "onboarding.privacy.faceid"))
                privacyBadge(String(localized: "onboarding.privacy.noTracking"))
            }
            .padding(.bottom, Spacing.xxxl)

            Spacer()
        }
    }

    private func privacyBadge(_ text: String) -> some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(ColorTokens.positive)
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: Spacing.l) {
            // Progress pills
            HStack(spacing: Spacing.s) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? ColorTokens.accent : .white.opacity(0.2))
                        .frame(
                            width: index == currentPage ? 24 : 8,
                            height: 8
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                }
            }

            // Action button
            if currentPage < 2 {
                Button {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } label: {
                    HStack(spacing: Spacing.s) {
                        Text(String(localized: "onboarding.continue"))
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(ColorTokens.accent)
                    .clipShape(.rect(cornerRadius: Radius.lg))
                }
            } else {
                VStack(spacing: Spacing.l) {
                    // Disclaimer toggle
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            hasAcceptedDisclaimer.toggle()
                        }
                    } label: {
                        HStack(spacing: Spacing.m) {
                            Image(systemName: hasAcceptedDisclaimer
                                ? "checkmark.circle.fill"
                                : "circle"
                            )
                            .font(.system(size: 18))
                            .foregroundStyle(hasAcceptedDisclaimer
                                ? ColorTokens.positive
                                : .white.opacity(0.4)
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasAcceptedDisclaimer)

                            Text(String(localized: "onboarding.disclaimer.accept"))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.leading)
                        }
                    }

                    // CTA
                    Button(action: onComplete) {
                        HStack(spacing: Spacing.s) {
                            Text(String(localized: "onboarding.start"))
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            hasAcceptedDisclaimer
                                ? ColorTokens.accent
                                : ColorTokens.accent.opacity(0.35)
                        )
                        .clipShape(.rect(cornerRadius: Radius.lg))
                    }
                    .disabled(!hasAcceptedDisclaimer)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasAcceptedDisclaimer)
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
