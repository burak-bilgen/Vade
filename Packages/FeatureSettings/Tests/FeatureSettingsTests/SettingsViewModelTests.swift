import Foundation
import Testing
@testable import FeatureSettings
import SwiftUI
import Core
import Domain

@MainActor
struct MockPersonRepo: FetchPersonsUseCase {
    func execute(includeArchived: Bool) async throws -> [Person] { [] }
}

@MainActor
struct MockDebtRepo: FetchDebtsForPersonUseCase {
    func execute(for personID: UUID) async throws -> [DebtRecord] { [] }
}

final class MockAnalytics: AnalyticsTracking, @unchecked Sendable {
    var trackedEvents: [AnalyticsEvent] = []
    var optOutVal: Bool?

    func track(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }

    func setOptOut(_ optOut: Bool) {
        optOutVal = optOut
    }
}

@MainActor
@Suite("FeatureSettings")
struct FeatureSettingsTests {
    public init() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.preferredCurrency)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.biometricEnabled)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.analyticsOptOut)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.crashlyticsOptOut)
    }

    @Test("SettingsView initializes with default app storage values")
    @MainActor
    func testDefaultValues() {
        // Verify the SettingsView can be constructed without crashing
        let view = SettingsView(
            personRepo: MockPersonRepo(),
            debtRepo: MockDebtRepo()
        )
        #expect(view is SettingsView)
    }

    @Test("DataExportService CSV export produces valid UTF-8 data")
    func testExportRoundTrip() async throws {
        let service = DataExportService()
        let rows: [ExportRow] = [
            ExportRow(
                personName: "Test",
                amount: 100,
                currency: "TRY",
                direction: "receivable",
                dueDate: nil,
                status: "pending",
                createdAt: Date()
            )
        ]
        let data = try service.exportAsCSV(rows: rows)
        #expect(data.count > 0)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("Test"))
    }

    @Test("SettingsViewModel defaults to TRY as preferred currency")
    @MainActor
    func testDefaultPreferredCurrency() {
        let vm = SettingsViewModel()
        #expect(vm.preferredCurrency == .tryCoin)
    }

    @Test("SettingsViewModel updates preferred currency")
    @MainActor
    func testSetPreferredCurrency() {
        let vm = SettingsViewModel()
        vm.setCurrency(.usd)
        #expect(vm.preferredCurrency == .usd)
    }

    @Test("SettingsViewModel biometric toggle updates user defaults and tracks analytics")
    @MainActor
    func testBiometricToggle() {
        let mockAnalytics = MockAnalytics()
        let vm = SettingsViewModel(analytics: mockAnalytics)
        
        vm.setBiometric(true)
        #expect(vm.isBiometricEnabled == true)
        #expect(UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricEnabled) == true)
        #expect(mockAnalytics.trackedEvents.count == 1)
        
        vm.setBiometric(false)
        #expect(vm.isBiometricEnabled == false)
        #expect(UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricEnabled) == false)
    }

    @Test("SettingsViewModel analytics toggle updates opt out preference and tracks event")
    @MainActor
    func testAnalyticsToggle() {
        let mockAnalytics = MockAnalytics()
        let vm = SettingsViewModel(analytics: mockAnalytics)
        
        vm.setAnalytics(false)
        #expect(vm.isAnalyticsEnabled == false)
        #expect(mockAnalytics.optOutVal == true)
        #expect(UserDefaults.standard.bool(forKey: UserDefaultsKeys.analyticsOptOut) == true)
        
        vm.setAnalytics(true)
        #expect(vm.isAnalyticsEnabled == true)
        #expect(mockAnalytics.optOutVal == false)
        #expect(UserDefaults.standard.bool(forKey: UserDefaultsKeys.analyticsOptOut) == false)
    }

    @Test("SettingsViewModel crashlytics toggle updates crashlytics opt out settings")
    @MainActor
    func testCrashlyticsToggle() {
        let vm = SettingsViewModel()
        
        vm.setCrashlytics(false)
        #expect(vm.isCrashlyticsEnabled == false)
        #expect(UserDefaults.standard.bool(forKey: UserDefaultsKeys.crashlyticsOptOut) == true)
        
        vm.setCrashlytics(true)
        #expect(vm.isCrashlyticsEnabled == true)
        #expect(UserDefaults.standard.bool(forKey: UserDefaultsKeys.crashlyticsOptOut) == false)
    }
}
