import SwiftUI
import CloudKit

/// Checks iCloud account status during onboarding.
/// Does NOT block the user — only informs if not signed in.
@MainActor
@Observable
final class CloudKitStatusChecker {
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var hasChecked = false

    func checkStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            accountStatus = status
        } catch {
            accountStatus = .couldNotDetermine
        }
        hasChecked = true
    }
}

// MARK: - iCloud Info Banner

struct iCloudInfoBanner: View {
    let status: CKAccountStatus

    var body: some View {
        if status != .available {
            HStack(spacing: 12) {
                Image(systemName: "icloud.slash")
                    .foregroundStyle(.white)
                Text(String(localized: "iCloud hesabına giriş yaparsan verilerin diğer cihazlarınla otomatik senkronize olur. Şimdilik yalnızca bu cihazda saklanıyor."))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
        }
    }
}
