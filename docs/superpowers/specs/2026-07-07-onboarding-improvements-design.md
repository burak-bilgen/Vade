# Onboarding Visual and Language-Selection Improvements

## Goal
Enhance the visual appeal of Vade's onboarding screen and integrate a real-time language selection popup matching the application's premium design system.

## Architecture
- **Language Integration**: Access the shared `LanguageManager` via SwiftUI `@Environment` within `OnboardingView`. Add `.id(languageManager.languageCode)` to ensure the onboarding screen recreates and animates nicely on language changes.
- **Visual Improvements**: Apply customized gradients and delays to the title, subtitle, tagline, and subtagline to create a cohesive entrance animation sequence.
- **Background Animation**: Design a custom `FinanceBackgroundAnimation` SwiftUI View utilizing `TimelineView` and `Canvas` for fluid, high-performance rendering of grid lines, rising charts, and floating currency symbols.
- **Language Popup**: Create a custom bottom sheet modal (`.sheet` or customized overlay) triggered by a top-left navigation button.

## Proposed Components

### 1. Visual Text Gradients
Apply gradients to onboarding headers:
- **Title**: `ColorTokens.textPrimary` to `ColorTokens.accent`
- **Subtitle**: `ColorTokens.accent` to `ColorTokens.chartTeal`
- **Tagline**: `ColorTokens.textPrimary` to `ColorTokens.accent`
- **Subtagline**: `ColorTokens.textSecondary` to `ColorTokens.textTertiary`

### 2. Finance-themed Background Animation (`FinanceBackgroundAnimation`)
A high-performance `Canvas` view rendering:
- A soft radial gradient and coordinate grid lines.
- An animated rising stock/crypto chart wave.
- Floating, rotating currency particles (`$`, `€`, `₺`, `¥`, `£`) that drift across the screen.

### 3. Language Selector Popover
- Trigger button: Globe icon (`systemName: "globe"`) at the top-left of the onboarding screen.
- Modal content: A premium layout displaying Turkish, English, Spanish, Chinese, Hindi, and Arabic. Selecting a language updates `LanguageManager.shared.setLanguage()`.
