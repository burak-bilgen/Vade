import ProjectDescription

// MARK: - Build Settings

let swiftSettings: [String: SettingValue] = [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY": "YES",
]

let targetSettings = Settings.settings(
    base: swiftSettings,
    configurations: [
        .debug(name: "Debug"),
        .release(name: "Release"),
    ]
)

// MARK: - Info Plist

let infoPlist: InfoPlist = .extendingDefault(with: [
    "UIBackgroundModes": ["remote-notification"],
    "UIApplicationSupportsIndirectInputEvents": true,
    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
    "ITSAppUsesNonExemptEncryption": false,
    "CFBundleDevelopmentRegion": "tr",
    "UILaunchScreen": [:],
    "NSContactsUsageDescription": "Vade needs access to your contacts so you can quickly add people you owe money to or who owe you.",
    "NSFaceIDUsageDescription": "Vade uses Face ID to protect your financial data from unauthorized access.",
    "NSUserTrackingUsageDescription": "Your data helps us improve Vade and show relevant ads. You can disable this in Settings.",
])

// MARK: - App Target

let appTarget = Target.target(
    name: "Vade",
    destinations: [.iPhone],
    product: .app,
    bundleId: "com.vade.app",
    deploymentTargets: .iOS("18.0"),
    infoPlist: infoPlist,
    sources: ["App/Sources/Vade/**"],
    resources: [
        "App/Sources/Vade/Resources/**",
        "Vade/Assets.xcassets",
        "Packages/DesignSystem/Sources/DesignSystem/Resources/Fonts/**",
        "Packages/DesignSystem/Sources/DesignSystem/Resources/Colors.xcassets",
    ],
    entitlements: .file(path: "Vade/Vade.entitlements"),
    dependencies: [
        .external(name: "Core"),
        .external(name: "DesignSystem"),
        .external(name: "Observability"),
        .external(name: "Domain"),
        .external(name: "Data"),
        .external(name: "Networking"),
        .external(name: "FeatureOnboarding"),
        .external(name: "FeatureDashboard"),
        .external(name: "FeatureDebtDetail"),
        .external(name: "FeatureSettings"),
        .external(name: "FeatureWidget"),
    ],
    settings: targetSettings
)

// MARK: - Project

let project = Project(
    name: "Vade",
    targets: [appTarget]
)
