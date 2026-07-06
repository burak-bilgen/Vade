import SwiftUI
import DesignSystem

public struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var hasAcceptedDisclaimer = false

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                page(icon: "hand.wave",
                     title: String(localized: "Kiminle ne durumdasın, hep bil."),
                     subtitle: String(localized: "Arkadaşına verdiğin, komşundan aldığın, unutulan ya da unutulması istenmeyen her borç burada güvenle kayıt altında.")).tag(0)
                page(icon: "book.pages",
                     title: String(localized: "Elinle tuttuğun kadar net"),
                     subtitle: String(localized: "Kimden ne kadar alacaklısın, kime ne kadar borçlusun — tek bakışta gör. Kısmi ödemeleri işle, hiçbir şey gözünden kaçmasın.")).tag(1)
                page(icon: "lock.shield",
                     title: String(localized: "Verin sende kalır"),
                     subtitle: String(localized: "Borç ve alacak kayıtların hiçbir sunucuya gönderilmiyor — yalnızca senin iCloud hesabında, Face ID ile korunan bu cihazda saklanıyor. Uygulama içindeki reklam, hata bildirimi ve kullanım istatistiği servisleri, kişisel kayıtlarına dokunmadan yalnızca anonim teknik ve davranışsal veri kullanır; bunu dilediğin an Ayarlar'dan kapatabilirsin.")).tag(2)
                page(icon: "doc.text",
                     title: String(localized: "Bilmen gereken önemli bir şey var"),
                     subtitle: String(localized: "Bu uygulama, borç ve alacaklarını kişisel olarak takip etmen için tasarlandı. Burada tuttuğun kayıtlar hukuki bir belge ya da resmi bir delil niteliği taşımaz.\n\nÖnemli bir borç ilişkisinde, haklarını korumak için yazılı bir belge almanı ya da gerekirse noter onayına başvurmanı öneririz.\n\nVeri kaybı, senkronizasyon aksaklıkları ya da hesaplama hatalarından doğabilecek herhangi bir zarardan sorumluluk kabul etmiyoruz. Bu uygulama sana yardımcı olmak için burada, ama son sorumluluk her zaman sende.")).tag(3)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(.easeInOut, value: currentPage)

            HStack(spacing: Spacing.s) {
                ForEach(0..<4, id: \.self) { i in
                    Circle().fill(i == currentPage ? ColorTokens.accent : Color.white.opacity(0.3))
                        .frame(width: i == currentPage ? 10 : 8, height: i == currentPage ? 10 : 8)
                }
            }
            .padding(.bottom, Spacing.m)

            Group {
                if currentPage < 3 {
                    Button { currentPage += 1 } label: {
                        HStack {
                            Text(String(localized: "Devam")); Image(systemName: "arrow.forward")
                        }.frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.brassPill)
                } else {
                    VStack(spacing: Spacing.m) {
                        Toggle(isOn: $hasAcceptedDisclaimer) {
                            Text(String(localized: "Okudum, anladım ve kabul ediyorum"))
                                .font(Typography.font(for: .caption)).foregroundStyle(.white.opacity(0.85))
                        }
                        .tint(ColorTokens.accent)
                        Button(action: onComplete) {
                            Text(String(localized: "Anladım, devam edeyim")).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.brassPill).disabled(!hasAcceptedDisclaimer).opacity(hasAcceptedDisclaimer ? 1 : 0.5)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [Color(white: 0.12), Color(white: 0.18)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .ignoresSafeArea()
    }

    private func page(icon: String, title: String, subtitle: String) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer(minLength: Spacing.xxxl)
                Image(systemName: icon).font(Typography.font(for: .onboardingIcon)).foregroundStyle(ColorTokens.accent)
                    .padding(.bottom, Spacing.m)
                Text(title).font(Typography.font(for: .title1)).foregroundStyle(.white).multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl).minimumScaleFactor(0.75)
                Text(subtitle).font(Typography.font(for: .body)).foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center).padding(.horizontal, Spacing.xxl).lineSpacing(Spacing.xs)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: Spacing.xxxl)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
