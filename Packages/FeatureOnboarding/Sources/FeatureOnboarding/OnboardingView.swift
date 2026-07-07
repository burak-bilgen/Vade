import SwiftUI
import DesignSystem
import CloudKit

public struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var appear = false
    @State private var featureAppeared = false
    @State private var accepted = false
    @State private var cloudStatus = CKAccountStatus.couldNotDetermine

    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "arrow.left.arrow.right.circle.fill",
            title: String(localized: "onboarding.feature.track"),
            description: String(localized: "onboarding.feature.track.desc")
        ),
        OnboardingFeature(
            icon: "dollarsign.arrow.circlepath",
            title: String(localized: "onboarding.feature.currency"),
            description: String(localized: "onboarding.feature.currency.desc")
        ),
        OnboardingFeature(
            icon: "bell.badge.fill",
            title: String(localized: "onboarding.feature.reminders"),
            description: String(localized: "onboarding.feature.reminders.desc")
        ),
        OnboardingFeature(
            icon: "icloud.fill",
            title: String(localized: "onboarding.feature.sync"),
            description: String(localized: "onboarding.feature.sync.desc")
        ),
    ]

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            ChartWaveBackground()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.92).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(String(localized: "onboarding.skip")) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                onComplete()
                            }
                        }
                        .font(Typography.font(for: .buttonSmall))
                        .foregroundStyle(ColorTokens.accent)
                        .padding(.trailing, Spacing.xl)
                        .padding(.top, Spacing.s)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: appear)
                    }

                    Spacer().frame(height: 24)

                    logoSection
                        .padding(.bottom, Spacing.xxl)

                    Text(String(localized: "onboarding.tagline"))
                        .font(Typography.font(for: .title2))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: appear)

                    Text(String(localized: "onboarding.subtagline"))
                        .font(Typography.font(for: .body))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.top, Spacing.xs)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 15)
                        .animation(.easeOut(duration: 0.6).delay(0.35), value: appear)

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
                            .transition(.move(edge: .trailing).combined(with: .opacity))
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) { featureAppeared = true }
            }
            checkCloudStatus()
        }
    }

    private var logoSection: some View {
        VStack(spacing: Spacing.xxs) {
            Text(String(localized: "app.name"))
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

            Text(String(localized: "app.subtitle"))
                .font(Typography.font(for: .bodyEmphasisItalic))
                .foregroundStyle(ColorTokens.accent.opacity(0.7))
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
        }
    }

    private var iCloudBanner: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 16))
                .foregroundStyle(ColorTokens.warning)
            Text(String(localized: "onboarding.icloud.notSignedIn"))
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    accepted.toggle()
                    if accepted { HapticFeedback.impact(.light) }
                }
            } label: {
                HStack(spacing: Spacing.m) {
                    Image(systemName: accepted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(accepted ? ColorTokens.accent : ColorTokens.border)
                    Text(String(localized: "onboarding.disclaimer.short"))
                        .font(Typography.font(for: .body))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .opacity(featureAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.7), value: featureAppeared)

            Button {
                HapticFeedback.notification(.success)
                onComplete()
            } label: {
                HStack(spacing: Spacing.s) {
                    Text(String(localized: "onboarding.start"))
                        .font(Typography.font(for: .button))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(accepted ? ColorTokens.accent : ColorTokens.border)
                )
                .opacity(accepted ? 1 : 0.6)
            }
            .disabled(!accepted)
            .opacity(featureAppeared ? 1 : 0)
            .offset(y: featureAppeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8), value: featureAppeared)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: accepted)
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
    let title: String
    let description: String
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
                Text(feature.title)
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(feature.description)
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

// MARK: - Animated Chart Wave Background

private struct ChartWaveBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation(paused: false)) { timeline in
            let x = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let phases: [CGFloat] = [0, 1.2, 2.5]
                let opacities: [Double] = [0.08, 0.05, 0.04]
                let colors: [Color] = [ColorTokens.chartBlue, ColorTokens.chartTeal, ColorTokens.chartPurple]

                for (i, offset) in phases.enumerated() {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: h * 0.6))
                    for seg in 0...Int(w / 2) {
                        let px = CGFloat(seg) * 2
                        let angle = (px / w) * .pi * 4 + CGFloat(x * 0.4) + offset
                        let py = h * 0.35 + sin(angle) * h * 0.06 + sin(angle * 1.6) * h * 0.03
                        path.addLine(to: CGPoint(x: px, y: py))
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                    context.fill(path, with: .color(colors[i].opacity(opacities[i])))
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
