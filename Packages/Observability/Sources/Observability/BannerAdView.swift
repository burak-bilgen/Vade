import SwiftUI
import DesignSystem

// MARK: - Banner Ad View (Google AdMob Integration Point)

/// Displays a banner ad at the bottom of the screen.
/// Replace the placeholder with real GADBannerView when GoogleMobileAds SDK is added.
///
/// Setup steps:
/// 1. Add `GoogleMobileAds` SPM package to App target
/// 2. Set `GADApplicationIdentifier` in Info.plist
/// 3. Replace `placeholderBody` with actual `GADBannerView` wrapped in `UIViewRepresentable`
public struct BannerAdView: View {
    let adUnitID: String

    public init(adUnitID: String = "ca-app-pub-3940256099942544/2934735716") {
        self.adUnitID = adUnitID
    }

    public var body: some View {
        // Placeholder: GoogleMobileAds SDK henüz eklenmediğinde boş alan.
        // Gerçek implementasyon:
        // GADBannerViewRepresentable(adUnitID: adUnitID)
        //     .frame(height: 50)
        Rectangle()
            .fill(Color.vdHairline)
            .frame(height: 50)
            .overlay {
                Text(String(localized: "ads.placeholder"))
                    .font(.caption)
                    .foregroundColor(Color.vdInk400)
            }
    }
}

// MARK: - Real GADBannerView Wrapper (uncomment when SDK added)

/*
#if canImport(GoogleMobileAds)
import GoogleMobileAds

private struct GADBannerViewRepresentable: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
#endif
*/
