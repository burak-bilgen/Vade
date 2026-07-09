import ProjectDescription

let workspace = Workspace(
    name: "Vade",
    projects: [
        "."
    ],
    schemes: [
        .scheme(
            name: "Vade-Workspace",
            shared: true,
            buildAction: .buildAction(targets: [.project(path: ".", target: "Vade")]),
            testAction: .targets(
                [
                    .testableTarget(target: .project(path: "Packages/Core", target: "CoreTests")),
                    .testableTarget(target: .project(path: "Packages/Data", target: "DataTests")),
                    .testableTarget(target: .project(path: "Packages/Domain", target: "DomainTests")),
                    .testableTarget(target: .project(path: "Packages/Networking", target: "NetworkingTests")),
                    .testableTarget(target: .project(path: "Packages/FeatureDashboard", target: "FeatureDashboardTests")),
                    .testableTarget(target: .project(path: "Packages/FeatureOnboarding", target: "FeatureOnboardingTests")),
                    .testableTarget(target: .project(path: "Packages/FeatureSettings", target: "FeatureSettingsTests")),
                    .testableTarget(target: .project(path: "Packages/FeatureDebtDetail", target: "FeatureDebtDetailTests"))
                ],
                options: .options(coverage: true)
            )
        )
    ]
)
