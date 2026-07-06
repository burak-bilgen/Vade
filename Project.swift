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
    "UIAppFonts": [
        "PlusJakartaSans-Regular",
        "PlusJakartaSans-Medium",
        "PlusJakartaSans-SemiBold",
        "PlusJakartaSans-Bold",
        "JetBrainsMono-Regular",
        "JetBrainsMono-Medium",
    ],
    "UIApplicationSupportsIndirectInputEvents": true,
    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
    "ITSAppUsesNonExemptEncryption": false,
    "CFBundleDevelopmentRegion": "tr",
])

// MARK: - App Target

let appTarget = Target.target(
    name: "Vade",
    destinations: .iOS,
    product: .app,
    bundleId: "com.vade.app",
    deploymentTargets: .iOS("18.0"),
    infoPlist: infoPlist,
    sources: ["App/Sources/Vade/**"],
    resources: [
        "App/Sources/Vade/Resources/**",
    ],
    entitlements: .file(path: "Vade/Vade.entitlements"),
    dependencies: [
        .external(name: "Core"),
        .external(name: "DesignSystem"),
        .external(name: "DIContainer"),
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
