# Onboarding Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement visual improvements (gradients/transitions), a custom finance-themed background animation, and a language-selection popup in Vade's Onboarding flow, ensuring real-time language updates.

**Architecture:** 
- Visual components in `OnboardingView` get animated text gradients.
- `ChartWaveBackground` is replaced by a custom canvas-based `FinanceBackgroundAnimation` rendering lines and floating symbols.
- A globe icon is added to `OnboardingView` which triggers a new `.sheet`-based `LanguageSelectionSheet` containing native flag representations of languages.
- Real-time reactivity is achieved by binding to `LanguageManager` and assigning `.id(languageManager.languageCode)` to the `OnboardingView` in `AppCoordinator.swift`.

**Tech Stack:** SwiftUI, TimelineView, Canvas, Observation.

## Global Constraints
- Target platform: iOS 18+
- Use Vade's existing design system token palette (`ColorTokens`, `Spacing`, `Radius`, etc.)
- Retain all localization keys for translation strings

---

### Task 1: Update CoordinatorRootView for Language Reactivity

**Files:**
- Modify: `App/Sources/Vade/Coordinators/AppCoordinator.swift`

**Interfaces:**
- Consumes: `LanguageManager.languageCode` from the Environment.

- [ ] **Step 1: Add `.id(languageManager.languageCode)` to `OnboardingView`**

```swift
            } else {
                OnboardingView {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        onboardingDone = true
                    }
                    AnalyticsService.shared.track(.onboardingCompleted)
                }
                .id(languageManager.languageCode)
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
```

- [ ] **Step 2: Commit**

```bash
git add App/Sources/Vade/Coordinators/AppCoordinator.swift
git commit -m "feat: add language id tracking to OnboardingView"
```

---

### Task 2: Create Finance Background Animation

**Files:**
- Create: `Packages/FeatureOnboarding/Sources/FeatureOnboarding/FinanceBackgroundAnimation.swift`

- [ ] **Step 1: Create the background animation drawing canvas and particles**

Create `Packages/FeatureOnboarding/Sources/FeatureOnboarding/FinanceBackgroundAnimation.swift` containing:
```swift
import SwiftUI
import DesignSystem

struct CurrencyParticle: Identifiable {
    let id = UUID()
    var symbol: String
    var position: CGPoint
    var scale: CGFloat
    var rotation: Double
    var opacity: Double
    var speedY: CGFloat
    var speedX: CGFloat
}

public struct FinanceBackgroundAnimation: View {
    @State private var particles: [CurrencyParticle] = []
    
    private let symbols = ["$", "€", "₺", "¥", "£", "%"]
    
    public init() {}
    
    public var body: some View {
        TimelineView(.animation(paused: false)) { timeline in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                
                // Draw a sleek finance grid
                let gridSpacing: CGFloat = 40
                var gridPath = Path()
                
                // Vertical grid lines
                for x in stride(from: 0, to: w, by: gridSpacing) {
                    gridPath.move(to: CGPoint(x: x, y: 0))
                    gridPath.addLine(to: CGPoint(x: x, y: h))
                }
                // Horizontal grid lines
                for y in stride(from: 0, to: h, by: gridSpacing) {
                    gridPath.move(to: CGPoint(x: 0, y: y))
                    gridPath.addLine(to: CGPoint(x: w, y: y))
                }
                context.stroke(gridPath, with: .color(ColorTokens.border.opacity(0.15)), lineWidth: 0.5)
                
                // Draw a rising, glowing financial chart line
                let time = timeline.date.timeIntervalSinceReferenceDate
                var chartPath = Path()
                chartPath.move(to: CGPoint(x: 0, y: h * 0.7))
                
                for x in stride(from: 0, to: w + 5, by: 5) {
                    let relativeX = x / w
                    let wave1 = sin(relativeX * .pi * 2 + CGFloat(time * 0.4)) * h * 0.05
                    let wave2 = cos(relativeX * .pi * 4 - CGFloat(time * 0.2)) * h * 0.02
                    let upwardTrend = -relativeX * h * 0.15 // Generates a rising trend
                    let y = h * 0.65 + wave1 + wave2 + upwardTrend
                    chartPath.addLine(to: CGPoint(x: x, y: y))
                }
                
                // Glow effect for the chart line
                context.stroke(chartPath, with: .color(ColorTokens.accent.opacity(0.3)), lineWidth: 4)
                context.stroke(chartPath, with: .color(ColorTokens.chartTeal.opacity(0.6)), lineWidth: 1.5)
                
                // Draw floating particles
                for particle in particles {
                    context.draw(
                        Text(particle.symbol)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ColorTokens.accent.opacity(particle.opacity)),
                        at: particle.position
                    )
                }
            }
        }
        .background(
            LinearGradient(
                colors: [ColorTokens.background, ColorTokens.surface],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            generateInitialParticles()
        }
        .task {
            // Animate particles using an ongoing loop
            while true {
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
                updateParticles()
            }
        }
    }
    
    private func generateInitialParticles() {
        var newParticles: [CurrencyParticle] = []
        for _ in 0..<15 {
            newParticles.append(createRandomParticle(in: UIScreen.main.bounds.size, initialY: true))
        }
        particles = newParticles
    }
    
    private func createRandomParticle(in size: CGSize, initialY: Bool = false) -> CurrencyParticle {
        let x = CGFloat.random(in: 0...size.width)
        let y = initialY ? CGFloat.random(in: 0...size.height) : size.height + 20
        return CurrencyParticle(
            symbol: symbols.randomElement() ?? "$",
            position: CGPoint(x: x, y: y),
            scale: CGFloat.random(in: 0.6...1.2),
            rotation: Double.random(in: 0...360),
            opacity: Double.random(in: 0.05...0.25),
            speedY: CGFloat.random(in: -1.2...-0.4),
            speedX: CGFloat.random(in: -0.3...0.3)
        )
    }
    
    private func updateParticles() {
        let size = UIScreen.main.bounds.size
        for i in 0..<particles.count {
            particles[i].position.y += particles[i].speedY
            particles[i].position.x += particles[i].speedX
            particles[i].rotation += 0.5
            
            // Re-spawn if particle moves off screen
            if particles[i].position.y < -20 || particles[i].position.x < -20 || particles[i].position.x > size.width + 20 {
                particles[i] = createRandomParticle(in: size, initialY: false)
            }
        }
    }
}
```

- [ ] **Step 2: Commit new background view**

```bash
git add Packages/FeatureOnboarding/Sources/FeatureOnboarding/FinanceBackgroundAnimation.swift
git commit -m "feat: add custom canvas-based FinanceBackgroundAnimation"
```

---

### Task 3: Create Language Selection Sheet

**Files:**
- Create: `Packages/FeatureOnboarding/Sources/FeatureOnboarding/LanguageSelectionSheet.swift`

- [ ] **Step 1: Create the language selector modal layout**

Create `Packages/FeatureOnboarding/Sources/FeatureOnboarding/LanguageSelectionSheet.swift` containing:
```swift
import SwiftUI
import DesignSystem
import Core

public struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager
    
    private let languages = [
        ("tr", "Türkçe", "🇹🇷"),
        ("en", "English", "🇬🇧"),
        ("es", "Español", "🇪🇸"),
        ("zh", "中文", "🇨🇳"),
        ("hi", "हिन्दी", "🇮🇳"),
        ("ar", "العربية", "🇦🇪")
    ]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: Spacing.l) {
            // Sheet Header
            HStack {
                Text(String(localized: "settings.language.label"))
                    .font(Typography.font(for: .title3))
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.l)
            
            // Language choices grid/list
            ScrollView {
                VStack(spacing: Spacing.s) {
                    ForEach(languages, id: \.0) { code, name, flag in
                        let isSelected = languageManager.languageCode == code
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                languageManager.setLanguage(code)
                            }
                            HapticFeedback.selection()
                            dismiss()
                        } label: {
                            HStack(spacing: Spacing.m) {
                                Text(flag)
                                    .font(.system(size: 24))
                                Text(name)
                                    .font(Typography.font(for: .bodyEmphasis))
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(ColorTokens.accent)
                                } else {
                                    Circle()
                                        .stroke(ColorTokens.border, lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .padding(.horizontal, Spacing.l)
                            .padding(.vertical, Spacing.m)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .fill(isSelected ? ColorTokens.accent.opacity(0.06) : ColorTokens.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .stroke(isSelected ? ColorTokens.accent.opacity(0.3) : ColorTokens.border, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.l)
            }
        }
        .padding(.bottom, Spacing.xl)
        .background(ColorTokens.background)
    }
}
```

- [ ] **Step 2: Commit new language sheet**

```bash
git add Packages/FeatureOnboarding/Sources/FeatureOnboarding/LanguageSelectionSheet.swift
git commit -m "feat: add LanguageSelectionSheet for onboarding language selection"
```

---

### Task 4: Integrate visual and functional improvements in OnboardingView

**Files:**
- Modify: `Packages/FeatureOnboarding/Sources/FeatureOnboarding/OnboardingView.swift`

- [ ] **Step 1: Import Core, retrieve languageManager environment object, add showLanguagePicker state**

Update imports and variables to include:
```swift
import Core

@Environment(LanguageManager.self) private var languageManager
@State private var showLanguagePicker = false
```

- [ ] **Step 2: Replace ChartWaveBackground and update background visual**

```swift
            FinanceBackgroundAnimation()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.85).ignoresSafeArea()
```

- [ ] **Step 3: Add Globe button to the top left**

Insert a globe button in the top bar:
```swift
                    HStack {
                        Button(action: {
                            HapticFeedback.impact(.light)
                            showLanguagePicker = true
                        }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "globe")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(languageManager.languageCode.uppercased())
                                    .font(Typography.font(for: .buttonSmall))
                            }
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.xs)
                            .background(Capsule().fill(ColorTokens.accent.opacity(0.1)))
                            .foregroundStyle(ColorTokens.accent)
                        }
                        .padding(.leading, Spacing.xl)
                        .padding(.top, Spacing.s)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: appear)
                        
                        Spacer()
                        
                        Button(String(localized: "onboarding.skip")) {
```

- [ ] **Step 4: Update text styles for subtitle, tagline, subtagline with gradients and transitions**

Update `logoSection` and the title labels:
```swift
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
    }
```
And inside `body`:
```swift
                    Text(String(localized: "onboarding.tagline"))
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

                    Text(String(localized: "onboarding.subtagline"))
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
```

- [ ] **Step 5: Add sheet modifier for LanguageSelectionSheet**

Add sheet modifier to the outer ZStack:
```swift
        .sheet(isPresented: $showLanguagePicker) {
            LanguageSelectionSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
```

- [ ] **Step 6: Run local swift build/test to verify syntax**

Run: `swift build` (or similar depending on package dependency resolutions)

- [ ] **Step 7: Commit onboarding modifications**

```bash
git add Packages/FeatureOnboarding/Sources/FeatureOnboarding/OnboardingView.swift
git commit -m "feat: complete visual gradients and language selector in OnboardingView"
```
