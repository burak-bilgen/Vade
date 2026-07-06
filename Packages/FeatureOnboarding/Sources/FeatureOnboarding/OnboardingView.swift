import SwiftUI
import DesignSystem

// MARK: - Onboarding View

public struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0
    @State private var accepted = false
    @State private var animateIcon = false
    private let totalPages = 3

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Animated gradient background
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 12)
                LinearGradient(
                    colors: [
                        Color(white: 0.06),
                        Color(white: 0.10 + sin(t) * 0.02),
                        Color(white: 0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip + progress
                header
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xxl)

                // Pages
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    featuresPage.tag(1)
                    startPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)

                // Fixed-height bottom controls — prevents layout jump
                bottomControls
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Progress bar
            HStack(spacing: 4) {
                ForEach(0..<totalPages, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= page ? ColorTokens.accent : .white.opacity(0.15))
                        .frame(width: i == page ? 20 : 8, height: 4)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                }
            }
            Spacer()
            if page < totalPages - 1 {
                Button(String(localized: "onboarding.skip")) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        page = totalPages - 1
                    }
                }
                .font(Typography.font(for: .body))
                .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Bottom Controls (fixed height to prevent jump)

    private var bottomControls: some View {
        ZStack {
            if page < totalPages - 1 {
                // Continue button — same height as start page controls
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        page += 1
                    }
                } label: {
                    HStack(spacing: Spacing.s) {
                        Text(String(localized: "onboarding.continue"))
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(ColorTokens.accent)
                    .clipShape(.rect(cornerRadius: Radius.lg))
                }
                .padding(.top, Spacing.m)
            } else {
                VStack(spacing: Spacing.m) {
                    // Disclaimer toggle
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            accepted.toggle()
                        }
                    } label: {
                        HStack(spacing: Spacing.m) {
                            ZStack {
                                Circle()
                                    .stroke(accepted ? ColorTokens.positive : .white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                if accepted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(ColorTokens.positive)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            Text(String(localized: "onboarding.disclaimer.accept"))
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
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
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(accepted ? ColorTokens.accent : ColorTokens.accent.opacity(0.3))
                        .clipShape(.rect(cornerRadius: Radius.lg))
                    }
                    .disabled(!accepted)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: accepted)
                }
                .padding(.top, Spacing.m)
            }
        }
        .frame(height: 100) // Fixed height prevents layout jump
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated icon stack
            ZStack {
                Circle()
                    .fill(ColorTokens.accent.opacity(0.08))
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(ColorTokens.accent.opacity(0.15), lineWidth: 1)
                    .frame(width: animateIcon ? 200 : 160, height: animateIcon ? 200 : 160)
                    .opacity(animateIcon ? 0 : 0.6)

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(ColorTokens.accent)
                    .symbolEffect(.bounce.up.byLayer, options: .repeating.speed(0.5), value: animateIcon)
            }
            .padding(.bottom, Spacing.xxxl)

            Text("Vade")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, Spacing.m)

            Text(String(localized: "onboarding.welcome.subtitle"))
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, Spacing.xxxl)

            Spacer()
            Spacer()
        }
        .onAppear { animateIcon = true }
        .onDisappear { animateIcon = false }
    }

    // MARK: - Page 2: Features

    private var featuresPage: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(String(localized: "onboarding.features.title"))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, Spacing.xxxl)
                .padding(.horizontal, Spacing.xl)

            VStack(spacing: Spacing.l) {
                feature(icon: "arrow.left.arrow.right", color: ColorTokens.accent,
                        title: String(localized: "onboarding.feature.track"),
                        desc: String(localized: "onboarding.feature.track.desc"))
                feature(icon: "chart.bar.fill", color: ColorTokens.positive,
                        title: String(localized: "onboarding.feature.insights"),
                        desc: String(localized: "onboarding.feature.insights.desc"))
                feature(icon: "bell.badge.fill", color: ColorTokens.accentLight,
                        title: String(localized: "onboarding.feature.reminders"),
                        desc: String(localized: "onboarding.feature.reminders.desc"))
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }

    private func feature(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: Spacing.l) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(.rect(cornerRadius: Radius.md))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Page 3: Start

    private var startPage: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ColorTokens.positive.opacity(0.08))
                    .frame(width: 140, height: 140)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTokens.accent, ColorTokens.positive],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, Spacing.xl)

            Text(String(localized: "onboarding.privacy.title"))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, Spacing.m)

            Text(String(localized: "onboarding.privacy.subtitle"))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, Spacing.xxxl)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
