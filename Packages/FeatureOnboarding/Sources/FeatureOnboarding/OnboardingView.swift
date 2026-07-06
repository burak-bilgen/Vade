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
                // Progress dots
                HStack(spacing: 6) {
                    Capsule().fill(ColorTokens.accent).frame(width: 20, height: 4)
                    Capsule().fill(page >= 1 ? ColorTokens.accent : ColorTokens.border).frame(width: page >= 1 ? 20 : 4, height: 4)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                .padding(.top, 20)

                // Pages
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    startPage.tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)

                // Bottom
                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .opacity(appear ? 1 : 0)
        .onAppear { withAnimation(.easeIn(duration: 0.4)) { appear = true } }
    }

    // MARK: Page 1 — Welcome + Features

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(ColorTokens.accent.opacity(0.08))
                    .frame(width: 120, height: 120)
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(ColorTokens.accent)
                    .symbolEffect(.bounce.up.byLayer, options: .repeating.speed(0.3), value: page == 0)
            }
            .padding(.bottom, 32)

            Text("Vade")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.bottom, 8)

            Text(String(localized: "onboarding.welcome.subtitle"))
                .font(.system(size: 16))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .padding(.bottom, 48)

            // Feature list
            VStack(spacing: 16) {
                featureRow(icon: "arrow.left.arrow.right", text: String(localized: "onboarding.feature.track"))
                featureRow(icon: "chart.bar.fill", text: String(localized: "onboarding.feature.insights"))
                featureRow(icon: "bell.badge.fill", text: String(localized: "onboarding.feature.reminders"))
                featureRow(icon: "lock.shield.fill", text: String(localized: "onboarding.privacy.title"))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ColorTokens.accent)
                .frame(width: 32)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(ColorTokens.textPrimary)
            Spacer()
        }
    }

    // MARK: Page 2 — Privacy + Start

    private var startPage: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ColorTokens.positive.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(ColorTokens.accent)
            }
            .padding(.bottom, 24)

            Text(String(localized: "onboarding.privacy.title"))
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.bottom, 8)

            Text(String(localized: "onboarding.privacy.subtitle"))
                .font(.system(size: 15))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if page == 0 {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { page = 1 }
                } label: {
                    Text(String(localized: "onboarding.continue"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(ColorTokens.accent, in: .rect(cornerRadius: 12))
                }
            } else {
                // Disclaimer
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { accepted.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: accepted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(accepted ? ColorTokens.positive : ColorTokens.border)
                        Text(String(localized: "onboarding.disclaimer.short"))
                            .font(.system(size: 13))
                            .foregroundStyle(ColorTokens.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                // CTA
                Button(action: onComplete) {
                    Text(String(localized: "onboarding.start"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(accepted ? ColorTokens.accent : ColorTokens.border, in: .rect(cornerRadius: 12))
                }
                .disabled(!accepted)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: accepted)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
