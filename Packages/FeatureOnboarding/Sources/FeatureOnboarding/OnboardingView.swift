import SwiftUI
import DesignSystem
import CloudKit
import Core

public struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var activeTab = 0
    @State private var accepted = false
    @State private var cloudStatus = CKAccountStatus.couldNotDetermine
    @Environment(LanguageManager.self) private var languageManager
    @State private var disclaimerShakeOffset: CGFloat = 0
    @State private var logoPulse = false
    @State private var isAnimating = false
    
    // Independent animations states for each page to prevent double animation jumpiness
    @State private var welcomeAnimate = false
    @State private var trackAnimate = false
    @State private var currencyAnimate = false
    @State private var syncAnimate = false

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Shared premium animated background
            FinanceBackgroundAnimation()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top navigation bar
                topBarOverlay
                    .padding(.top, 12)
                
                // Horizontal swiper TabView
                TabView(selection: $activeTab) {
                    welcomeTab
                        .tag(0)
                    
                    trackTab
                        .tag(1)
                    
                    currencyTab
                        .tag(2)
                    
                    syncTab
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom controls & custom indicators
                bottomNavigation
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
            }
        }
        .environment(\.locale, languageManager.locale)
        .id(languageManager.languageCode)
        .onAppear {
            checkCloudStatus()
            triggerAnimateState(for: 0)
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                logoPulse = true
            }
        }
        .onChange(of: activeTab) { _, newTab in
            HapticFeedback.selection()
            triggerAnimateState(for: newTab)
        }
    }

    // MARK: - Navigation Top Bar

    private var topBarOverlay: some View {
        HStack {
            Spacer()

            if activeTab < 3 {
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
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Tab 0: Welcome Screen

    private var welcomeTab: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Premium Glowing Logo Emblem
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ColorTokens.accent.opacity(logoPulse ? 0.22 : 0.12), ColorTokens.accent.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 75
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(logoPulse ? 1.08 : 0.94)
                
                Circle()
                    .fill(ColorTokens.surface)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [ColorTokens.accent.opacity(0.4), ColorTokens.chartTeal.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .elevation(Elevation.level2)
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTokens.accent, ColorTokens.chartTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: ColorTokens.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(welcomeAnimate ? 1 : 0.8)
            .opacity(welcomeAnimate ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1), value: welcomeAnimate)
            .padding(.bottom, Spacing.l)

            Text(LocalizedStringKey("app.name"))
                .font(.custom(AppFont.jakartaBold, size: 58))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorTokens.textPrimary, ColorTokens.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(-1.2)
                .scaleEffect(welcomeAnimate ? 1.0 : 0.95)
                .opacity(welcomeAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: welcomeAnimate)

            Text(LocalizedStringKey("onboarding.tagline"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.s)
                .offset(y: welcomeAnimate ? 0 : 15)
                .opacity(welcomeAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.32), value: welcomeAnimate)

            Text(LocalizedStringKey("onboarding.subtagline"))
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.xs)
                .offset(y: welcomeAnimate ? 0 : 15)
                .opacity(welcomeAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.44), value: welcomeAnimate)
            
            Spacer()
        }
    }

    // MARK: - Tab 1: Debt Tracker Visualisation

    private var trackTab: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Transaction card simulation
            VStack(spacing: Spacing.m) {
                // Card 1: Ahmet Borç Alacak
                HStack(spacing: Spacing.m) {
                    Image(systemName: "arrow.down.left.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(ColorTokens.positive)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("onboarding.mock.person1.name"))
                            .font(Typography.font(for: .bodyEmphasis))
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(LocalizedStringKey("onboarding.mock.person1.status"))
                            .font(Typography.font(for: .label))
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    Spacer()
                    Text(LocalizedStringKey("onboarding.mock.person1.amount"))
                        .font(Typography.font(for: .amountSmall))
                        .foregroundStyle(ColorTokens.positive)
                }
                .padding(Spacing.m)
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(ColorTokens.positive.opacity(0.2), lineWidth: 1)
                )
                .elevation(Elevation.level1)
                .offset(x: trackAnimate ? 0 : -100)
                .opacity(trackAnimate ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.76).delay(0.25), value: trackAnimate)
                
                // Card 2: Elif Borç Veren
                HStack(spacing: Spacing.m) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(ColorTokens.negative)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("onboarding.mock.person2.name"))
                            .font(Typography.font(for: .bodyEmphasis))
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(LocalizedStringKey("onboarding.mock.person2.status"))
                            .font(Typography.font(for: .label))
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    Spacer()
                    Text(LocalizedStringKey("onboarding.mock.person2.amount"))
                        .font(Typography.font(for: .amountSmall))
                        .foregroundStyle(ColorTokens.negative)
                }
                .padding(Spacing.m)
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(ColorTokens.negative.opacity(0.2), lineWidth: 1)
                )
                .elevation(Elevation.level1)
                .offset(x: trackAnimate ? 0 : 100)
                .opacity(trackAnimate ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.76).delay(0.4), value: trackAnimate)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
            
            Text(LocalizedStringKey("onboarding.feature.track"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .offset(y: trackAnimate ? 0 : 15)
                .opacity(trackAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: trackAnimate)

            Text(LocalizedStringKey("onboarding.feature.track.desc"))
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.s)
                .offset(y: trackAnimate ? 0 : 15)
                .opacity(trackAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: trackAnimate)
            
            Spacer()
        }
    }

    // MARK: - Tab 2: Live Currency rates

    private var currencyTab: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Currency rates simulation
            VStack(spacing: Spacing.s) {
                HStack(spacing: Spacing.m) {
                    CurrencyIconView(code: "USD", size: 36)
                    Text(LocalizedStringKey("onboarding.mock.usd.name"))
                        .font(Typography.font(for: .bodyEmphasis))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Spacer()
                    Text(LocalizedStringKey("onboarding.mock.usd.rate"))
                        .font(Typography.font(for: .amountSmall).monospacedDigit())
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(ColorTokens.border, lineWidth: 0.5)
                )
                .scaleEffect(currencyAnimate ? 1 : 0.8)
                .opacity(currencyAnimate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.2), value: currencyAnimate)

                HStack(spacing: Spacing.m) {
                    CurrencyIconView(code: "XAU", size: 36)
                    Text(LocalizedStringKey("onboarding.mock.gold.name"))
                        .font(Typography.font(for: .bodyEmphasis))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Spacer()
                    Text(LocalizedStringKey("onboarding.mock.gold.rate"))
                        .font(Typography.font(for: .amountSmall).monospacedDigit())
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(ColorTokens.border, lineWidth: 0.5)
                )
                .scaleEffect(currencyAnimate ? 1 : 0.8)
                .opacity(currencyAnimate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.35), value: currencyAnimate)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
            
            Text(LocalizedStringKey("onboarding.feature.currency"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .offset(y: currencyAnimate ? 0 : 15)
                .opacity(currencyAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: currencyAnimate)

            Text(LocalizedStringKey("onboarding.feature.currency.desc"))
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.s)
                .offset(y: currencyAnimate ? 0 : 15)
                .opacity(currencyAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: currencyAnimate)
            
            Spacer()
        }
    }

    // MARK: - Tab 3: iCloud Sync & Disclaimer

    private var syncTab: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // iCloud & notification simulation
            VStack(spacing: Spacing.s) {
                // iCloud indicator
                HStack(spacing: Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(ColorTokens.accent.opacity(0.1))
                            .frame(width: 38, height: 38)
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(ColorTokens.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("onboarding.icloud.title"))
                            .font(Typography.font(for: .bodyEmphasis))
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(cloudStatus == .available ? String(localized: "onboarding.icloud.connected") : String(localized: "onboarding.icloud.automaticSync"))
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                    Spacer()
                    if cloudStatus == .available {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ColorTokens.positive)
                    }
                }
                .padding(Spacing.m)
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(ColorTokens.border, lineWidth: 0.5)
                )
                .scaleEffect(syncAnimate ? 1 : 0.8)
                .opacity(syncAnimate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.15), value: syncAnimate)

                // Notification Simulation Card
                HStack(spacing: Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(ColorTokens.accent.opacity(0.1))
                            .frame(width: 38, height: 38)
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(ColorTokens.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("onboarding.notification.title"))
                            .font(Typography.font(for: .bodyEmphasis))
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(LocalizedStringKey("onboarding.notification.body"))
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    Spacer()
                }
                .padding(Spacing.m)
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(ColorTokens.border, lineWidth: 0.5)
                )
                .scaleEffect(syncAnimate ? 1 : 0.8)
                .opacity(syncAnimate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.28), value: syncAnimate)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.ml)
            
            Text(LocalizedStringKey("onboarding.feature.sync"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .offset(y: syncAnimate ? 0 : 15)
                .opacity(syncAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: syncAnimate)

            Text(LocalizedStringKey("onboarding.feature.sync.desc"))
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.s)
                .offset(y: syncAnimate ? 0 : 15)
                .opacity(syncAnimate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: syncAnimate)
            
            if cloudStatus != .available && cloudStatus != .couldNotDetermine {
                iCloudBanner
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.m)
                    .opacity(syncAnimate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: syncAnimate)
            }
            
            Spacer()
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

    // MARK: - Bottom Navigation Controls

    private var bottomNavigation: some View {
        VStack(spacing: Spacing.l) {
            // Custom page indicators
            HStack(spacing: Spacing.s) {
                ForEach(0..<4) { index in
                    Capsule()
                        .fill(activeTab == index ? ColorTokens.accent : ColorTokens.textSecondary.opacity(0.3))
                        .frame(width: activeTab == index ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: activeTab)
                }
            }
            .padding(.top, Spacing.s)

            if activeTab == 3 {
                // Disclaimer Checkbox
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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                
                // Get Started Button
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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Next Button
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                        activeTab += 1
                    }
                } label: {
                    HStack(spacing: Spacing.s) {
                        Text(LocalizedStringKey("onboarding.next"))
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
                                LinearGradient(
                                    colors: [ColorTokens.accent, ColorTokens.accent.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            }
        }
    }

    // MARK: - Helper Actions & Methods

    private func triggerAnimateState(for tab: Int) {
        // Reset all states
        welcomeAnimate = false
        trackAnimate = false
        currencyAnimate = false
        syncAnimate = false
        
        // Trigger active tab state
        switch tab {
        case 0:
            welcomeAnimate = true
        case 1:
            trackAnimate = true
        case 2:
            currencyAnimate = true
        case 3:
            syncAnimate = true
        default:
            break
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
