# Vade — Teknik Mimari ve Faz Planı (v5 — Güncel)


## Proje Hedefi
**Uygulama adı: Vade.** Kişisel, tek-kullanıcılı borç/alacak (elden verilen/alınan
para) takip uygulaması. İki amaç: (1) gerçekten günlük/haftalık kullanılacak bir
ürün, (2) banka/fintech iOS pozisyonlarına başvururken gösterilecek, senior/tech-lead
seviyesinde bir mühendislik vitrini.

**Kesinlikle olmayacaklar:** Backend sunucusu yok, para transferi/tutma yok,
hukuki/finansal tavsiye yok, iki taraflı onay mekanizması yok, genel harcama/bütçe
takibi yok (bilinçli olarak kapsam dışı bırakıldı — odağı dağıtmaması için).

---

## Teknik Mimari Kararları (Sabit)

| Katman | Karar | Gerekçe |
|---|---|---|
| UI Framework | SwiftUI, minimum **iOS 18** | Nisan 2026'dan itibaren Apple, App Store'a yüklenen her uygulamanın **iOS 26 SDK / Xcode 26** ile build edilmesini zorunlu kıldı (bu, deployment target'ı değil, build araçlarını ilgilendirir). Deployment target'ı iOS 18'de tutmak 2026 ortası için makul bir alt sınır — çok eski cihazı dışlamadan güncel API yüzeyinin büyük kısmına erişim sağlıyor. iOS 17'de bırakmak artık "eski" görünüyor. |
| Dil Modu | **Swift 6, strict concurrency baştan açık** | Sıfırdan başlayan bir projede sonradan Swift 6'ya geçiş acısı çekmeye hiç gerek yok — ilk günden strict concurrency ile başlamak veri yarışı (data race) hatalarını derleme zamanında yakalar. Ayrıca güncel Swift bilgisinin en somut kanıtı. |
| Mimari | MVVM-C (Coordinator pattern) | VIPER'a göre daha az boilerplate, hâlâ test edilebilir ve ayrık |
| Kalıcılık | SwiftData + CloudKit sync | Backend'siz çoklu cihaz senkronizasyonu. **Önemli:** CloudKit'in şema üzerinde sert kısıtları var, aşağıda ayrı başlıkta detaylandırıldı — bunlar Faz 0'da modelleme yapılırken baştan bilinmezse sonradan çok pahalıya mal olur. |
| Modülerlik | Yerel Swift Package Manager paketleri | Gerçek modülerlik, build time kontrolü |
| DI | Kendi yazılmış, protokol tabanlı hafif DI container | 3. parti bağımlılık yok, tasarım kararı anlatılabilir |
| Networking | URLSession + async/await, protokol soyutlaması | Native, test edilebilir |
| Test | **Unit/integration: Swift Testing** (`@Test`, `#expect`, `#require`) · **UI akışları: XCUITest** · **Snapshot: swift-snapshot-testing** | Swift Testing WWDC24'te tanıtıldı ve 2026 itibarıyla yeni projelerde varsayılan tercih haline geldi (daha az boilerplate, native parametreli test, async/await ile doğal uyum). Ama UI otomasyonu (`XCUIApplication`) ve performans testleri (`XCTMetric`) hâlâ sadece XCTest'te var — bu yüzden ikisi bir arada, ama net bir işbölümüyle kullanılıyor. |
| CI/CD | GitHub Actions | Her PR'da: build + test + lint + **coverage eşiği** + **commit mesajı format kontrolü** |
| Lint/Format | SwiftLint + SwiftFormat | CI'da zorunlu |
| Yerelleştirme | String Catalogs (.xcstrings) | Apple'ın güncel yöntemi |
| Diller | Türkçe + İngilizce, İspanyolca, Mandarin, Hintçe, Arapça | Sistem diline göre otomatik + Arapça için RTL desteği. **Not:** TR/EN dışındaki 4 dil için ayrı bir "native review" adımı var (Faz 5'te) — aksi halde "doğal insan çevirisi" iddiası gerçekçi olmaz. |
| Güvenlik | Face ID/Touch ID, Keychain, jailbreak tespiti (pasif) | Finansal veri, banka standardı. **Certificate pinning kasıtlı olarak YOK** — gerekçe aşağıda ayrı başlıkta. |
| Grafik | Swift Charts | Native, güncel — hangi grafikler/hangi filtreler aşağıda "Grafik ve İstatistik Ekranı" başlığında detaylandırıldı |
| Görsel Kimlik / Design System | Özel renk paleti + gömülü (sistem dışı) font çifti | Varsayılan SwiftUI/Apple app'i görünümünden bilinçli olarak ayrışmak için — tam token seti aşağıda "Design System" başlığında |
| Widget | WidgetKit (+ opsiyonel Live Activity) | Gerçek kullanım sinyali + opsiyonel "vitrin" katmanı |
| Reklam | Google AdMob | Ücretsiz model — **App Tracking Transparency (ATT) izni + Privacy Manifest** ile birlikte, aşağıda detaylı |
| Crash/Analytics | Firebase Crashlytics **+ Firebase Analytics** (tip-güvenli event whitelist) | Gözlemlenebilirlik + kullanım verisi — sadece anonim teknik/davranışsal veri, kişisel veri (isim/tutar/not) asla gönderilmez, kullanıcı Ayarlar'dan kapatabilir; detay aşağıda ayrı başlıkta |
| Erişilebilirlik | VoiceOver + Dynamic Type | Az kişinin yaptığı, fark yaratan katman |
| Dokümantasyon | README + ADR (Architecture Decision Record) dosyaları | Mimari kararların yazılı gerekçesi |
| Proje Yönetimi | Tuist | Xcode proje dosyasını kod olarak yönetme, modüler yapıyı otomatik bağlama, ücretsiz, ekip/ölçek farkındalığı sinyali |

### Neden Certificate Pinning KALDIRILDI (önemli mimari karar — ADR olarak yazılacak)

İlk taslakta "banka standardı" gerekçesiyle sertifika pinleme vardı. Ama gerçek veri
akışına bakınca bu kararın zayıf olduğu görülüyor — ve bu, projenin **backend'i
olmadığı** için sorduğun soruyla doğrudan ilgili:

- Uygulamanın kendi backend'i yok. Kendi kontrolündeki tek network çağrıları TCMB
  döviz kuru ve 3. parti altın fiyatı API'lerine gidiyor — ikisi de public, auth
  gerektirmeyen, salt-okunur veri sunuyor.
- CloudKit trafiği zaten Apple'ın kendi SDK'sı tarafından yönetiliyor; uygulama
  kodu bu trafiğe elle pin koyamaz, koymaya çalışmak da anlamsız.
- Firebase Crashlytics ve AdMob'un networking'i kendi SDK'ları içinde soyutlanmış
  durumda — uygulama seviyesinde pinlemeye zaten açık değiller.
- Geriye kalan tek aday TCMB/altın API'si. Buraya pin koymak, o servis sertifikasını
  rotasyona soktuğu an (senin kontrolünde olmayan bir zamanlama) uygulamanın TÜM
  kullanıcılarında kırılma riski doğuruyor. Karşılığında korunan veri (döviz kuru)
  hassas olmadığı için bu risk/fayda dengesi olumsuz çıkıyor.
- **Karar:** Standart ATS/TLS doğrulaması (sistem güven deposu, Info.plist'te
  hiçbir istisna yok) yeterli. Ekstra bir pinleme mekanizması eklenmeyecek.

Bunu bir ADR olarak yaz (`docs/adr/00X-no-certificate-pinning.md`). Mülakatta
anlatılacak hikaye "pinlemeyi düşündüm, backend'im olmadığını ve verinin hassas
olmadığını görüp bilinçli olarak vazgeçtim, işte gerekçem" — bu, körü körüne
checkbox güvenlik eklemekten çok daha güçlü bir mühendislik sinyali.

### SwiftData + CloudKit Şema Kısıtları (Faz 0'da baştan uygulanacak)

CloudKit senkronizasyonu SwiftData şemasına sert kısıtlar getiriyor. Bunlar
modelleme yapılırken baştan bilinmezse, birkaç faz sonra keşfedilip pahalı bir
geri dönüşe (refactor + veri taşıma) yol açar:

- `@Attribute(.unique)` **kullanılmayacak** — CloudKit unique constraint
  desteklemiyor, kullanmaya çalışırsan `ModelContainer` yüklenirken çöker.
- Her property ya **optional** ya da **default value'lu** olmalı — non-optional,
  default'suz bir alan container'ın yüklenmesini engeller.
- Her **relationship optional olmalı** (boş dizi default'u olsa bile). Kullanım
  kolaylığı için private optional alan + public computed property şablonu
  kullanılabilir: `private var _payments: [Payment]?` / `var payments: [Payment] { _payments ?? [] }`.
- **Ordered relationship desteklenmiyor** — sıralama gerekiyorsa ilişkinin
  kendisine güvenme, ayrı bir `sortIndex`/tarih alanına göre sırala.
- Uygulama production'a çıkıp CloudKit şeması production ortamına push
  edildikten **sonra**, şema değişiklikleri sadece **ekleme** olabilir —
  mevcut bir entity/attribute'u **silme, yeniden adlandırma veya tipini
  değiştirme YASAK** (CloudKit bunu "sil + yeni ekle" olarak yorumlar, veri
  kaybına yol açar). Bu kural Faz 0'ın ilk ADR'ına yazılacak.

### iOS 26 SDK Zorunluluğu ve Liquid Glass Etkisi (Design System için kritik) **(YENİ — v4)**

Final gözden geçirmede doğrulanan, planı doğrudan etkileyen somut bir bulgu:

- **Kesin tarih:** Apple, **28 Nisan 2026**'dan itibaren App Store Connect'e
  yüklenen tüm iOS/iPadOS uygulamalarının **Xcode 26+ / iOS 26 SDK** ile build
  edilmesini zorunlu kıldı. Bu tarih geçti (bugün 6 Temmuz 2026) — yani proje
  başından itibaren zaten bu SDK ile build edilmeli, geçiş derdi yok.
- **Önemli ayrım (plan için güvenli taraf):** Bu kural sadece build aracını
  ilgilendiriyor — deployment target'ı iOS 18'de tutmak hâlâ tamamen geçerli,
  eski cihazlar dışlanmıyor.
- **Design System için asıl risk:** iOS 26 SDK ile build edilen bir uygulama,
  **iOS 26 çalıştıran bir cihazda** varsayılan olarak Apple'ın yeni **"Liquid
  Glass"** görsel dilini standart sistem bileşenlerine (tab bar, navigation
  bar, toolbar, sheet, sistem butonları) otomatik uygular — bu, deployment
  target'tan bağımsız, çalışma zamanındaki OS + SDK kombinasyonuna bağlı bir
  davranış. Bu planın Design System hedefi ("varsayılan SwiftUI/Apple app'i
  gibi görünmeyecek") ile doğrudan etkileşime giriyor ve baştan bir karar
  gerektiriyor — Faz 5'e kadar bekleyip sürpriz yaşamamak için burada
  netleştirildi.
- **Karar:** Hibrit yaklaşım benimsenir. **Sistem "chrome"unda** (TabView,
  NavigationStack toolbar'ı, sheet'ler) Liquid Glass **kabul edilir** —
  reddetmek yerine kabul etmek hem ücretsiz bir "güncel görünüyor" sinyali
  verir hem de Apple'ın kendi HIG yönüyle çatışmaz; ama tint rengi `ink900`/
  `brass500` olarak ayarlanır, sistem mavisi bırakılmaz. **Özel içerik
  bileşenlerinde** (`LedgerRowView`, `SummaryCard`, grafikler, `PillButtonStyle`
  vb. — bunlar zaten custom-drawn) Design System'in kendi kimliği tamamen
  korunur, Liquid Glass bunları etkilemez çünkü bunlar sistem bileşeni değil.
- Bu karar Faz 0'da bir ADR olarak yazılır (`docs/adr/00X-liquid-glass-adoption.md`)
  ve Faz 0'ın sonunda Xcode 26 simülatöründe erken bir görsel doğrulama yapılır.
- **CI implikasyonu:** GitHub Actions runner image'ının Xcode 26+ içerdiğinden
  emin olunmalı (`macos-15` veya sonrası, güncel `xcode-select` adımı) — Faz
  0'daki CI kurulumunda bu netleştirilecek pratik bir detay.

### Concurrency (Swift 6)

- Tüm ViewModel'ler `@MainActor` işaretli.
- Repository/Networking katmanındaki paylaşılan mutable state (örn. döviz kuru
  ve altın fiyatı cache'i) bir `actor` içinde izole edilir (`RatesCache` gibi);
  Sendable olmayan tipler actor/task sınırını geçmez.
- DTO'lar ve Domain modelleri `Sendable` protokolüne uyar.
- Strict concurrency açık olduğundan, agent bir uyarıyı "sonra hallederim" diye
  bastırıp geçmez — Faz 0'dan itibaren temiz derlenir.

### Firebase Analytics — Kapsam, Event Şeması ve Gizlilik Sınırları

**Gerekçe:** Crashlytics için zaten kurulacak Firebase altyapısının üstüne
Analytics eklemek ucuz — ve "kaç kişi kullanıyor, hangi özellik gerçekten
kullanılıyor, nerede terk ediliyor" bilgisi hem gerçek ürün kararları almanı
sağlar hem mülakatta "veriye dayalı iterasyon yaptım" diyebileceğin somut bir
hikaye olur. Ama bu bir borç/alacak uygulaması — event'lere yanlışlıkla isim,
tutar veya not sızması ciddi bir gizlilik hatası olur. Bu yüzden kural yazmak
yetmez, **mimaride imkansız kılmak** gerekiyor.

**Mimari yaklaşım:**
- Yeni bir `Observability` SPM paketi eklenir (aşağıdaki modül ağacında
  görülebilir). Crashlytics ve Analytics SDK'larına dokunan TEK yer burasıdır.
  Feature modülleri Firebase'i asla doğrudan import etmez; sadece DI container
  üzerinden enjekte edilen bir `AnalyticsTracking` protokolü çağırır.
- Serbest, string tabanlı `Analytics.logEvent("x", parameters: [String: Any])`
  çağrısı **hiçbir yerde** serbest bırakılmaz. Bunun yerine kapalı, tip-güvenli
  bir `AnalyticsEvent` enum'u üzerinden gidilir — parametresiz veya sadece
  kapalı bir alt-enum/tip parametreli (asla serbest String/tutar değil):

```swift
enum AnalyticsEvent {
    case appOpened
    case onboardingCompleted
    case personAdded
    case debtAdded(kind: DebtKind)            // .cash, .foreignCurrency, .gold
    case paymentRecorded(type: PaymentType)   // .full, .partial
    case currencyChanged(to: CurrencyCode)    // sadece kod: .try, .usd, .eur, .gold
    case exportUsed(format: ExportFormat)     // .pdf, .csv
    case notificationPermission(granted: Bool)
    case notificationScheduled
    case widgetAdded
    case biometricLockEnabled(Bool)
    case languageChanged(to: String)          // sadece dil kodu ("tr", "en"...)
    case themeChanged(to: ThemeMode)          // .system, .light, .dark
    case chartViewed(ChartType)
    case analyticsOptOut(Bool)
    case dataDeleted
}
```

  `AnalyticsService` bu enum'u Firebase'in `logEvent(name:parameters:)`
  çağrısına eşleyen TEK yerdir. Yeni bir event eklemek bu enum dosyasına
  dokunmayı ve PR review'dan geçmeyi gerektirir — "whitelist'e ekleme" mantığı
  budur.
- **CI'da zorunlu kontrol:** Mevcut "hardcoded UI string" regex/lint kontrolüyle
  aynı mantıkla, `Observability` paketi dışında `import FirebaseAnalytics` veya
  `Analytics.logEvent` geçen bir dosya bulunursa build FAIL eder.
- `Analytics.setUserID(_:)` ve kimliğe bağlı `setUserProperty` **hiçbir zaman**
  çağrılmaz — veri tamamen anonim/toplu kalır.
- **Google Signals / Ad Personalization Analytics'ten bağımsız kapatılır**
  (Firebase konsolunda Google Signals OFF + gerekli config anahtarı ile ad
  personalization sinyalleri kapalı). AdMob zaten kendi ATT akışına sahip;
  Analytics'i bundan ayrı ve "temiz" tutmak daha doğru bir ayrım.
- **Kullanıcı kontrolü:** Ayarlar > Gizlilik altında iki ayrı switch bulunur:
  "Kullanım İstatistiklerini Paylaş" (Analytics, varsayılan açık) ve "Çökme
  Raporlarını Paylaş" (Crashlytics, varsayılan açık) — ikisi de bağımsız olarak
  kapatılabilir (`setAnalyticsCollectionEnabled(false)` /
  `crashlyticsCollectionEnabled = false`). Bu, uygulamanın "verin sende kalır"
  mesajıyla tutarlı, somut bir kullanıcı kontrolü katmanıdır.
- Onboarding'deki gizlilik metni buna göre güncellendi (aşağıda "Kullanıcıya
  Gösterilecek Ana Metinler" bölümünde) ve Privacy Nutrition Label'a "Kullanım
  Verisi" kategorisi eklendi (FAZ 5) — kimliğe bağlı değil, çünkü `setUserID`
  hiç çağrılmıyor.
- Bunun için ayrı bir ADR yazılır: `docs/adr/00X-firebase-analytics-event-whitelist.md`.
- **KVKK/GDPR farkındalık notu (YENİ — v4, hukuki tavsiye DEĞİLDİR):** Firebase
  (ABD merkezli altyapı) ve Google AdMob kullanan bir uygulama olarak, Türkiye'de
  KVKK ve (AB kullanıcıları için) GDPR kapsamında ek yükümlülükler doğabilir
  (ör. aydınlatma metninin içeriği, veri işleyen/aktarım gerekçeleri). Bu plan
  bir hukuki danışmanlık sağlamıyor; App Store'a çıkmadan önce onboarding
  gizlilik metni ve Gizlilik Politikası sayfasının nihai diline kısa bir hukuki
  göz atılması önerilir — özellikle KVKK aydınlatma metni formatı için.

### Modül Yapısı (SPM paketleri)
```
Vade/
├── App/                     (ana uygulama hedefi, sadece composition root)
├── Packages/
│   ├── Core/                (temel utilities, extensions, Decimal helpers)
│   ├── DesignSystem/        (renkler, tipografi, spacing/radius token'ları, tema,
│   │                         reusable UI bileşenleri — tam detay "Design System" bölümünde)
│   ├── DIContainer/         (kendi yazılmış DI mekanizması)
│   ├── Observability/       (AnalyticsService + Crashlytics wrapper, AnalyticsEvent whitelist enum —
│   │                         Firebase SDK'sına dokunan tek paket)
│   ├── Domain/               (entities, use case protokolleri — framework bağımsız)
│   ├── Data/                (SwiftData modelleri, repository implementasyonları, CloudKit sync)
│   ├── Networking/          (döviz/altın API client, protokol soyutlaması, RatesCache actor)
│   ├── FeatureOnboarding/
│   ├── FeatureDashboard/
│   ├── FeatureDebtDetail/
│   ├── FeatureSettings/
│   └── FeatureWidget/
```

---

## Design System — Görsel Kimlik ve UI Rehberi

**Hedef:** Uygulama ilk bakışta "başka bir varsayılan SwiftUI app'i" gibi
görünmeyecek — kendi kimliği, kendi rengi, kendi fontu olacak. Ama bu kimlik
rastgele "güzel renkler" seçmekten değil, uygulamanın **kendi konusundan**
doğuyor: bu bir borç/alacak *defteri*. Türkiye'de esnafın tuttuğu "veresiye
defteri" kültürel referansı — kağıt üzerinde hizalı sütunlar, el yazısı
tutarlar, güven — dijital ama sıcak bir "modern defter" kimliğine dönüştürülüyor.
Buna ek olarak uygulamanın gerçek bir özelliği (gram altın bazlı borç takibi)
imza rengin (pirinç/bronz ton) için doğrudan bir gerekçe veriyor — dekoratif
değil, konudan doğan bir seçim.

### Uygulama Adı — "Vade" ve Dil Bazlı Yerelleştirmesi **(YENİ — v4)**

**Neden "Vade":** Kısa, tek kelime, akılda kalıcı — ve uygulamanın kalbindeki
kavramı doğrudan taşıyor: bir borcun/alacağın **vadesi**, yani ödeme tarihi.
Uygulamanın en güçlü tekrar-kullanım mekanizması olan "vade hatırlatma sistemi"
isimle bire bir örtüşüyor; bu, marka ile ürünün özü arasında doğal, kurgulanmamış
bir bağ kuruyor — mülakatta anlatılacak isim hikayesi de budur.

**Marka/isim çakışması notu (agent'ın kendi başına karar vermemesi gereken bir
nokta):** Araştırmada "Vade" adının Fransa merkezli bir e-posta güvenliği
şirketi (eski adıyla Vade Secure, artık Hornetsecurity markası altında
birleşiyor) tarafından **kurumsal siber güvenlik** alanında kullanıldığı
görüldü — farklı ülke, farklı sektör (B2B e-posta güvenliği vs. bireysel finans
uygulaması), farklı marka sınıfı olduğundan pratik çakışma riski düşük
görünüyor; üstelik o şirket zaten "Hornetsecurity" adına geçiyor. Yine de bu bir
hukuki değerlendirme değildir — App Store'a göndermeden önce (1) App Store
Connect'te isim rezervasyonu yapılması, (2) Türk Patent ve Marka Kurumu ile
ilgili ülkelerde hızlı bir marka taraması yapılması, gerekiyorsa bir marka
vekiline danışılması önerilir.

**Rakip ortam notu:** Aynı araştırmada App Store'da neredeyse aynı konsepte
sahip birkaç uygulama olduğu görüldü — kişi bazlı borç/alacak takibi, çoklu
para birimi, vade hatırlatmaları, PDF/CSV dışa aktarma sunan, biri özellikle
Türkiye merkezli ve TRY/USD/EUR/GBP destekleyen bir rakip dahil. Bu iyi bir
haber: konseptin gerçek bir ihtiyacı karşıladığını doğruluyor. Ama bu planın
asıl farkı şu üç noktada kalıyor ve bunlar bilinçli olarak korunmalı:
**(1) gram altın bazlı takip** (rakiplerde görülmedi, Türkiye pazarına özgü
gerçek bir farklılaşma), **(2) CloudKit ile gerçek çakışma-çözümlü çoklu cihaz
senkronizasyonu** (çoğu rakip basit iCloud yedeklemesi sunuyor, conflict
resolution'lı gerçek sync değil), **(3) Design System + ADR + test derinliği**
(mühendislik vitrini hedefi için asıl değer burada, rakiplerin hiçbirinde yok).

**Dil bazlı uygulama adı çevirileri:**

| Dil | Uygulama Adı | Gerekçe |
|---|---|---|
| Türkçe (tr) | **Vade** | Orijinal isim — "vade tarihi" kavramıyla birebir örtüşüyor, esnafın veresiye defteri kültürüyle de tanıdık bir kelime. |
| İngilizce (en) | **Vade** | Değiştirilmeden bırakıldı. İngilizce'de anlamı olan bir kelime değil, ama "Venmo", "Wise", "Wave" gibi kısa/özgün finans-app isimleri geleneğine uyuyor; telaffuzu kolay, tek bir global App Store arama terimi olması marka tutarlılığı sağlıyor. |
| İspanyolca (es) | **Vade** | İspanyolca'da zaten var olan bir kelime — küçük bir evrak çantası/dosya anlamına gelir ve "vademécum" (başvuru kitapçığı) kelimesinin köküdür; ayrıca Latince "git/ilerle" (vadere) emir kipinden geliyor, bu da "ilerleme/takip" fikriyle örtüşüyor. Bu yüzden değiştirilmeden bırakıldı. |
| Mandarin (zh) | **账期 (Zhàngqī)** | Birebir çeviri yerine anlamca en yakın gerçek finans terimi seçildi — Çince'de "ödeme vadesi/tahsilat süresi" anlamına gelen, ticari bağlamda zaten yerleşik bir terim. Latin harfli "Vade" bir Çince kullanıcı için anlamsız ve telaffuzu zor bir isim olurdu. |
| Hintçe (hi) | **मियाद (Miyaad)** | Hintçe/Urduca'da "süre/vade/son tarih" anlamına gelen, hukuki ve finansal bağlamda ("ऋण की मियाद" — borcun vadesi gibi ifadelerde) yaygın kullanılan yerleşik bir kelime. İlginç bir dilsel bağlantı: bu kelime de Türkçe "vade" gibi Arapça kökten geliyor — aynı kavram iki dile de aynı kaynaktan geçmiş. |
| Arapça (ar) | **أجل (Ajal)** | Arapça'da "belirlenmiş vade/süre" anlamına gelen, borç-alacak bağlamında klasik bir terim — Kur'an'daki borç ayetinde geçen ("...إذا تداينتم بدين إلى أجل مسمى...") kelimenin ta kendisi. Türkçe "vade"nin kökeni de Arapça'ya dayandığından, bu çeviri kavramı adeta "aslına" döndürüyor — hem dilsel hem kültürel olarak güçlü bir seçim. |

**Uygulama notu (teknik):**
- Uygulama ikonu ve ana marka wordmark'ı her pazarda **"Vade"** (Latin harfli)
  olarak kalır — görsel kimlik/logo değişmez.
- App Store Connect'teki her yerelleştirilmiş metadata girişinde (App Name /
  Subtitle alanı) ilgili dildeki isim kullanılır — bu, o ülke App Store'undaki
  arama/vitrin başlığını etkiler.
- **Karar:** Sadece App Store vitrin ismi değil, cihazın ana ekranındaki isim
  (`CFBundleDisplayName`) de yerelleştirilsin — iOS'ta bu, her `.lproj`
  klasöründeki `InfoPlist.strings` dosyasında ayrı ayrı tanımlanabilir. Yani
  Çince/Hintçe/Arapça kullanan bir kullanıcının ana ekranında da sırasıyla
  "账期"/"मियाद"/"أجل" yazar — daha tutarlı, daha profesyonel bir yerelleştirme
  hikayesi.
- **Bu isimlerin hiçbiri agent tarafından tek başına "doğal mı" diye
  onaylanmamalı** — aşağıdaki Faz 5 "native review" adımı (İspanyolca/
  Mandarin/Hintçe/Arapça için) bu isim çevirilerini de kapsamalı; bir native
  speaker'a özellikle "bu isim bir borç/finans uygulaması için doğal ve olumlu
  bir çağrışım yapıyor mu" diye sorulmalı — isim, sıradan bir çeviri satırından
  çok daha kritik ve geri dönüşü daha pahalı bir karardır.
- Bundle identifier önerisi: `com.<gelistirici>.vade` (Latin, sabit); App
  Store URL slug'ı da "vade" olarak sabit kalır, sadece görünen isim/metadata
  dile göre değişir.
- Bunun için ayrı bir ADR yazılır: `docs/adr/00X-app-name-vade.md` (isim
  seçimi, çakışma taraması sonucu ve dil bazlı çeviri gerekçeleri belgelenir).

**Kaçınılanlar (bilinçli):** Sistem mavisi (`Color.accentColor` varsayılanı),
varsayılan SF Pro'nun hiç işlenmemiş hali, sıcak krem arka plan + serif başlık +
turuncu-kiremit vurgu kombinasyonu (AI ile üretilen tasarımlarda klişeleşmiş bir
kalıp), yarı-siyah zemin + tek neon vurgu (bir diğer klişe). Bunun yerine soğuk
tonlu açık bir "kağıt" arka planı + koyu lacivert-indigo "mürekkep" rengi +
sıcak pirinç/bronz vurgu tercih edildi — hem birbirinden hem klişelerden ayrışıyor.

### Renk Paleti

**Marka / Nötr (Işık modu):**

| Token | Hex | Kullanım |
|---|---|---|
| `ink900` | `#1B2340` | Birincil metin, ikon, birincil buton zemini |
| `ink700` | `#4B5170` | İkincil metin |
| `ink400` | `#8A8FAE` | Üçüncül/pasif metin, placeholder |
| `background` | `#F5F6F8` | Ekran arka planı (soğuk, nötr "kağıt") |
| `surface` | `#FFFFFF` | Kart/liste satırı zemini |
| `hairline` | `#E3E5EC` | İnce kenarlık |
| `ledgerLine` | `#D3D6E0` | Liste satırları arası "defter çizgisi" (noktalı) |

**İmza vurgu — Pirinç/Bronz (altın takibiyle doğrudan ilişkili):**

| Token | Hex | Kullanım |
|---|---|---|
| `brass500` | `#B8863A` | Birincil CTA, aktif durum, seçili sekme, imza öğe |
| `brass300` | `#EDD9AF` | Açık tint zemin (seçili chip arkaplanı vb.) |
| `brass700` | `#8F6526` | Basılı/pressed durum |

**Anlamsal — Alacak (pozitif) / Borç (negatif):**

| Token | Hex | Kullanım |
|---|---|---|
| `positive600` | `#1F7A5C` | Alacak tutarları, pozitif net durum |
| `positive100` | `#DCF0E7` | Pozitif kart/tint zemin |
| `negative600` | `#C1483B` | Borç tutarları, negatif net durum |
| `negative100` | `#F8E1DE` | Negatif kart/tint zemin |

**Koyu mod (aynı paletin gece versiyonu, ayrı ayrı tanımlanır, elle hesaplanmaz):**

| Token | Hex | Kullanım |
|---|---|---|
| `background` (dark) | `#10121C` | Ekran arka planı |
| `surface` (dark) | `#1A1D2C` | Kart zemini |
| `hairline` (dark) | `#2B2F45` | Kenarlık |
| `textPrimary` (dark) | `#F2F1ED` | Birincil metin |
| `textSecondary` (dark) | `#ACAFC7` | İkincil metin |
| `brass500` (dark) | `#D1A356` | Vurgu (karanlıkta biraz açılır) |
| `positive600` (dark) | `#3FA980` | Alacak |
| `negative600` (dark) | `#E2695A` | Borç |

**Uygulama notu:** Bu token'lar `DesignSystem` paketinde Asset Catalog color
set'leri olarak tanımlanır (her set light/dark appearance içerir), koda hardcoded
hex **yazılmaz** — `Color("ink900")` gibi isimle çağrılır. SwiftUI kodu hiçbir
yerde `Color(red:green:blue:)` ile ham hex kullanmaz.

### Tipografi

Sistem fontu (San Francisco) yerine gömülü, açık lisanslı bir font çifti
kullanılıyor — hem ayrışma hem de "para tutarlarının hizalı göründüğü" gerçek
bir fintech/defter hissi için:

- **Plus Jakarta Sans** (SIL Open Font License) — tüm UI metinleri, başlıklar,
  gövde metni. Geometrik-hümanist karakteri modern ve sıcak; SF Pro'dan bariz
  farklı ama okunabilirlikte ödün vermiyor.
- **JetBrains Mono** (SIL Open Font License) — **sadece para tutarları ve
  bakiye rakamları için**, tabular (sabit genişlikte) rakamlarla. Bu, gerçek bir
  defterin/hesap cetvelinin sütun hizası hissini verir ve liste içinde tutarlar
  güncellendiğinde genişlik zıplamasını da engeller — hem estetik hem işlevsel
  bir seçim.
- Her iki font da açık lisanslı; repo'ya `LICENSE` dosyaları eklenmeli, indirilen
  sürümün güncel lisans metni build öncesi teyit edilmeli.

**Tip skalası:**

| Rol | Font | Boyut | Ağırlık | Dynamic Type `relativeTo` |
|---|---|---|---|---|
| Display (Dashboard net durum rakamı) | JetBrains Mono | 34 | Medium | `.largeTitle` |
| Title 1 (ekran başlıkları) | Plus Jakarta Sans | 28 | SemiBold | `.title` |
| Title 2 (kart başlıkları) | Plus Jakarta Sans | 20 | SemiBold | `.title2` |
| Headline (liste satırı — isim) | Plus Jakarta Sans | 17 | Medium | `.headline` |
| Body (genel metin) | Plus Jakarta Sans | 16 | Regular | `.body` |
| Amount (liste/satır tutarı) | JetBrains Mono | 16 | Medium | `.body` |
| Caption (etiket, tarih, alt metin) | Plus Jakarta Sans | 13 | Regular | `.caption` |

- **Dynamic Type zorunlu:** Tüm boyutlar `Font.custom(_:size:relativeTo:)` ile
  tanımlanır, sabit `Font.custom(_:size:)` KULLANILMAZ — plandaki Dynamic Type
  gereksinimiyle çelişmemesi için bu şart.
- **Bilinen SPM gotcha'sı:** Bir Swift Package içindeki font dosyaları,
  ana app target'ının `Info.plist` → `UIAppFonts` listesine otomatik girmez.
  Fontlar `DesignSystem` paketinin resource'ı olarak eklenir, ama
  kayıt işlemi `CTFontManagerRegisterFontsForURL` ile `Bundle.module`
  üzerinden programatik yapılmalı (uygulama açılışında bir defaya mahsus). Bu,
  Faz 0'da keşfedilmezse "fontlar simülatörde çalışıyor ama gerçek build'de
  sistem fontuna düşüyor" şeklinde ilerideki fazlarda fark edilen, can sıkıcı
  bir hataya yol açar — baştan bilinsin diye burada not edildi.

### Spacing / Radius / Elevation Token'ları

- **Spacing (8pt grid):** `xs=4, s=8, m=12, l=16, xl=24, xxl=32, xxxl=48`
- **Radius:** `sm=8` (rozet/chip) · `md=14` (buton) · `lg=20` (kart) · `pill=999` (FAB/pill buton)
- **Elevation:** Gölge kullanımı kasıtlı olarak minimal — sadece Dashboard'daki
  ana özet kartında (siyah %6 opaklık, y:4, blur:12); geri kalan her yerde ince
  bir `hairline` kenarlık yeterli. Amaç: her karta gölge basıp "yapay derinlik"
  yaratan şablon görünümünden kaçınmak, cesaretini tek bir yere harcamak.

### Bileşen Rehberi (`DesignSystem` paketi)

- **`LedgerRowView` (imza bileşen):** Kişi/borç listesindeki her satır — solda
  isim baş harfinden deterministik renkli bir daire avatar + isim, sağda
  `JetBrains Mono` ile tutar (pozitifse `positive600` + yukarı ok ikonu,
  negatifse `negative600` + aşağı ok ikonu — renk asla tek başına anlam
  taşımaz). Satır altında ince noktalı bir `ledgerLine` ayracı, gerçek bir
  defter satırını andırır.
- **`SummaryCard`:** Dashboard'daki net durum kartı — büyük `JetBrains Mono`
  rakam, altında ince bir `brass500` alt çizgi/vurgu, kart arka planı net
  duruma göre hafif tonlanır (pozitifse `positive100`, negatifse `negative100`,
  nötrse nötr yüzey). Sayı, ekrana girişte kısa bir "count-up" animasyonuyla belirir.
- **`PillButtonStyle`:** Birincil (dolu `ink900` zemin, beyaz metin — özel bir
  CTA için `brass500` dolu varyant), ikincil (1.5pt `ink900` kontur, dolu değil),
  yıkıcı/destructive (sadece `negative600` renkli metin+ikon, dolgu yok — dolgu
  sadece onay diyaloğunda).
- **`CurrencyChip`:** Para birimi/altın türü seçimi için yatay pill-chip grubu
  (TRY/USD/EUR/Altın) — aynı bileşen hem borç girişinde hem grafik filtresinde kullanılır.
- **`StatChip`:** Küçük özet rozetleri ("Toplam Alacak", "Toplam Borç").
- **`EmptyStateView`:** Harici illüstrasyon paketi kullanılmaz (lisans riski);
  bunun yerine SwiftUI `Path`/`Shape` ile çizilmiş sade, marka renkli çizgi
  illüstrasyonları (ör. açık bir defter ikonu) — hem tamamen özgün hem de
  mülakatta gösterilebilecek küçük bir teknik detay ("illüstrasyonları native
  Shape API'siyle kendim çizdim").
- **`ChartCard`:** Aşağıdaki "Grafik ve İstatistik Ekranı" bölümündeki tüm
  Swift Charts görselleri bu ortak kart sarmalayıcı içinde yaşar (tutarlı
  başlık/lejant/erişilebilirlik davranışı için).
- **`ConfirmSheet`:** Silme/onay akışları için ortak bottom sheet bileşeni.

### Ekran Bazlı UI Fikirleri

- **Onboarding:** 4 ekran arasında `ink900` → koyu mürekkep-mor arası yumuşak
  bir gradyan geçişi, her ekranda konuya özel sade bir çizgi ikon (tokalaşma /
  açık defter / kilit+kalkan / onay işareti), sayfa göstergesi noktaları `brass500`.
- **Dashboard:** Üstte `SummaryCard` (net durum) + altında iki `StatChip`
  (Toplam Alacak / Toplam Borç) + "Yaklaşan Ödemeler" için yatay kaydırmalı
  kart şeridi + sağ altta sabit, `brass500` dolgulu dairesel "+" (Borç/Alacak
  Ekle) butonu.
- **Kişi Listesi ("Bana Borçlu Olanlar" / "Benim Borçlu Olduklarım"):** İki
  sekme (segmented control, `brass500` seçili gösterge), her satır `LedgerRowView`.
- **Kişi Detayı:** Üstte avatar + isim + bu kişiyle net durum; altında ince
  dikey bir "zaman çizgisi" hattı üzerinde sıralanan `LedgerRowView` geçmişi
  (her kayıt küçük bir nokta ile zaman çizgisine bağlanır).
- **İstatistikler ekranı:** Üstte pill-şeklinde zaman aralığı seçici (3A/6A/1Y/Tümü)
  + `CurrencyChip` şeridi, altında `ChartCard` içinde sıralı grafikler (detay
  aşağıda).
- **Ayarlar:** Native gruplu liste stili korunur (SwiftUI/HIG tutarlılığı için)
  ama vurgu rengi `brass500`; tema seçimi üç küçük canlı önizleme kutusuyla
  (Sistem/Açık/Koyu) gösterilir, düz metin listesi yerine.

### Hareket (Motion) ve Haptik Geri Bildirim

- Dashboard açıldığında net durum rakamı için kısa bir "count-up" animasyonu
  (`~0.6sn`, yumuşak spring) — abartısız, tek seferlik.
- "Ödendi olarak işaretle" ve ödeme kaydetme aksiyonlarında hafif haptic
  (`UIImpactFeedbackGenerator(.light)`).
- `accessibilityReduceMotion` açıksa: count-up yerine doğrudan fade, spring
  yerine `.easeInOut` — hareket asla zorunlu bir bilgi taşıyıcısı değildir.

### Erişilebilirlik Notları (Design System'e özel)

- Alacak/borç ayrımı **hiçbir yerde sadece renkle** verilmez — her zaman
  yön oku ikonu ve/veya `+`/`−` işaretiyle desteklenir (renk körü kullanıcılar için).
- Işık/koyu modda tüm metin–zemin ikilileri WCAG AA (4.5:1) kontrast hedefler;
  özellikle `brass500` üzerindeki beyaz metin ve tint zeminler üzerindeki
  metinler bu açıdan test edilir.
- Grafiklerde VoiceOver için `AXChartDescriptor`/`accessibilityChartDescriptor`
  ile sesli özet sağlanır — plandaki genel VoiceOver gereksinimiyle doğrudan bağlantılı.

### Grafik ve İstatistik Ekranı — Kapsam ve Tasarım

Swift Charts zaten mimari kararlarda vardı; burada **hangi grafik, hangi
filtre, nerede** sorusu somutlaştırılıyor.

**Gösterilecek grafikler:**
1. **Net Durum Zaman Çizelgesi** — `LineMark`, seçilen zaman aralığında net
   durumun (alacak − borç) değişimi, alan altı `brass500` gradyan dolgu.
2. **Alacak vs Borç Karşılaştırma** — aylık gruplanmış `BarMark`, `positive600`/`negative600` renkleriyle.
3. **Kişi Bazlı Dağılım** — yatay `BarMark`, en çok borçlu/alacaklı olunan ilk
   5–10 kişi; bir çubuğa dokunmak ilgili kişinin detay ekranına götürür.
4. **Para Birimi/Tür Dağılımı** — `SectorMark` (donut), TRY/USD/EUR/Altın için
   **ayrı ayrı** (plandaki "naif toplama yasak" kararıyla tutarlı — tek bir
   toplam rakama zorla çevrilmez, kullanıcı sekme değiştirerek bakar).
5. **Ödenmiş / Bekleyen Oranı** — basit donut veya ilerleme göstergesi.
6. **Vade Takvimi Yoğunluğu** *(opsiyonel, düşük öncelik — Faz 4'te zaman
   kalmazsa Faz 5'e kayabilir)* — takvim-heatmap tarzı, yaklaşan vadelerin
   yoğunluğunu gösterir.

**Etkileşim/filtreler:**
- Üstte pill-şeklinde zaman aralığı seçici: 3 Ay / 6 Ay / 1 Yıl / Tümü.
- `CurrencyChip` şeridiyle para birimi/tür filtresi.
- Dashboard'da küçük bir "önizleme" sparkline (Faz 1'deki basit dashboard'a bile
  eklenebilir) + "Tüm İstatistikler" linkiyle tam ekran İstatistikler sayfasına geçiş.
- Az veri varken (ör. 3 kayıttan az) grafik yerine nazik bir boş-durum mesajı:
  *"Trend görebilmek için birkaç kayıt daha ekle."*

**Konum:** Basit bir önizleme Faz 1'deki dashboard'da bile yer alabilir; tam
İstatistikler ekranı ve yukarıdaki 6 grafiğin tamamı **Faz 4**'te (Dashboard
Derinleştirme fazı) hayata geçer — bkz. aşağıdaki Faz 4 detayı.

---

## FAZ 0 — Temel Altyapı + Yasal Zırh
**Hedef:** Mimari iskelet ayakta, hiçbir feature yok ama proje "senior" görünüyor.

- Tuist ile Xcode projesi + SPM paket yapısının kurulması (`Project.swift`
  manifestolarıyla, elle `.pbxproj` düzenlenmeyecek)
- **Swift 6 dil modu + strict concurrency** ayarının Project.swift'te açılması
- MVVM-C iskeleti: `AppCoordinator`, `Coordinator` protokolü, ilk boş ekran geçişi
- DI Container: protokol tabanlı `Container`/`Resolver` yapısı, örnek bir servisin enjekte edilmesi
- SwiftData şema tasarımı: `Person`, `DebtRecord` (tutar, para birimi/tür, tarih,
  not, durum), `Payment` (kısmi ödeme) — **yukarıdaki CloudKit şema kısıtlarına
  uygun şekilde**: unique constraint yok, tüm alanlar optional/default, ilişkiler optional
- CloudKit container kurulumu + `ModelContainer` CloudKit senk konfigürasyonu
- GitHub Actions CI: build + test + SwiftLint pipeline + **code coverage eşiği**
  (örn. %70 altına düşerse build fail) + **commit mesajı format kontrolü**
  (Conventional Commits regex/commitlint adımı)
- SwiftLint + SwiftFormat konfigürasyon dosyaları (kurallar tanımlı, CI'da fail eden)
- String Catalog (.xcstrings) kurulumu, 6 dil iskeleti (boş key'lerle)
- **`Observability` paketi + Firebase kurulumu:** `GoogleService-Info.plist`
  eklenmesi, Firebase Crashlytics + Analytics SDK entegrasyonu, `AnalyticsEvent`
  whitelist enum'unun ve `AnalyticsService`/`AnalyticsTracking` protokolünün
  yazılması (bkz. yukarıdaki "Firebase Analytics" bölümü). Google Signals ve
  ad personalization sinyalleri baştan kapatılır. CI'a "Observability dışında
  Firebase SDK'sına doğrudan erişim var mı" kontrolü eklenir.
- **`DesignSystem` paketinin kurulması:** Renk token'ları Asset Catalog color
  set'leri olarak (light/dark), Plus Jakarta Sans + JetBrains Mono font
  dosyalarının pakete eklenmesi ve `Bundle.module` üzerinden programatik kayıt
  (bkz. yukarıdaki SPM font gotcha'sı), spacing/radius sabitleri, temel
  `PillButtonStyle`/`LedgerRowView` iskeletleri (bkz. yukarıdaki "Design System"
  bölümü).
- **Zorunlu onboarding akışı:** 3-4 ekran tanıtım + son ekranda atlanamaz sorumluluk
  reddi metni — kullanıcı onaylamadan içeri giremiyor (tam metin aşağıda "Kullanıcıya
  Gösterilecek Ana Metinler" bölümünde)
- **iCloud hesap durumu kontrolü (Sign in with Apple DEĞİL):** Onboarding
  sırasında `CKContainer.default().accountStatus` ile cihazın iCloud durumu
  kontrol edilir. Giriş yoksa engelleyici bir ekran gösterilmez, sadece
  bilgilendirme yapılır ve uygulama yerel modda çalışmaya devam eder. Sign in
  with Apple butonu EKLENMEYECEK — uygulamada hiçbir 3. parti/özel login sistemi
  olmadığı için Apple'ın bunu zorunlu kılan kuralı (Guideline 4.8) tetiklenmiyor.
- **Gizlilik Politikası sayfasının barındırılması (YENİ — v4, eksikti):**
  Apple, veri toplayan (Crashlytics/Analytics/AdMob'un üçü de bu kapsamda) her
  uygulama için App Store Connect'te canlı bir Gizlilik Politikası URL'si
  zorunlu kılıyor — bu plan bu üçünü de kullandığı için bu adım atlanamaz.
  Basit, statik bir sayfa (ör. GitHub Pages üzerinde ücretsiz barındırılan tek
  sayfalık bir `.md`/`.html`) burada hazırlanır, hem App Store Connect'e hem
  Ayarlar ekranındaki ilgili linke bağlanır. İçeriği onboarding gizlilik
  metniyle birebir tutarlı olmalı.
- **Liquid Glass benimseme kararının ADR'ı (YENİ — v4):** Yukarıdaki "iOS 26
  SDK Zorunluluğu ve Liquid Glass Etkisi" başlığındaki hibrit karar burada
  yazılı hale getirilir, Xcode 26 simülatöründe erken bir görsel doğrulama
  yapılır.
- README iskeleti + ilk ADR dosyaları: neden MVVM-C, neden SwiftData+CloudKit,
  neden bu modülerlik, **neden certificate pinning yok**, **CloudKit şema
  kısıtları ve production-sonrası "sadece ekleme" kuralı**, **neden Analytics
  tip-güvenli whitelist üzerinden çalışıyor**, **Liquid Glass benimseme
  kararı**, **"Vade" isim seçimi ve dil bazlı çeviri gerekçeleri**

**Test:** DI container'ın doğru resolve ettiğini kanıtlayan Swift Testing testleri
(`@Test`), Coordinator navigasyon testleri, `AnalyticsEvent` → Firebase event
adı eşlemesinin doğru çalıştığını kanıtlayan testler (kişisel veri içermediğini
doğrulayan bir testle birlikte).

---

## FAZ 1 — MVP Çekirdek Özellikler
**Hedef:** Uygulama gerçekten kullanılabilir hale geliyor.

- Kişi ekleme: rehberden (Contacts framework) veya manuel
- İki ana sekme: "Bana Borçlu Olanlar" / "Benim Borçlu Olduklarım" — listeler
  yukarıdaki Design System'deki `LedgerRowView` bileşeniyle render edilir
- Kişi detay ekranı: borç geçmişi zaman çizelgesi (tarih, tutar, not)
- Kısmi ödeme ekleme ve bakiye güncelleme mantığı
- Dashboard: toplam alacak, toplam borç, net durum özeti (`SummaryCard` +
  `StatChip` bileşenleriyle) + "Yaklaşan Ödemeler ve Alacaklar" bölümü (vade
  tarihi girilmiş kayıtları en yakın tarihe göre sıralayan kısa liste — bu
  bölüm Faz 1'de basit haliyle görünür olur, tam hatırlatma/bildirim mantığı
  Faz 4'te derinleştirilir). Dashboard'a Faz 1'de basit bir net durum
  sparkline'ı da eklenebilir (tam İstatistikler ekranı Faz 4'te).
- Para hesaplamalarında **yalnızca `Decimal`**, `Double` kullanımı yasak
- Use case katmanı: `AddDebtUseCase`, `RecordPaymentUseCase`, `CalculateBalanceUseCase` vb.
- Analytics event'leri: `personAdded`, `debtAdded(kind:)`, `paymentRecorded(type:)`
  — `AnalyticsService` üzerinden, sadece yukarıda tanımlı whitelist enum'uyla
- **Bu fazdan itibaren "Kod Mimarisi ve UI Disiplini" bölümündeki kurallar geçerli**
  (aşağıda) — View'lar ince kalır, business logic use case'lerde yaşar.

**Test:** Tüm para hesaplama use case'leri için **Swift Testing'in parametreli
test desteğiyle** (`@Test(arguments:)`) kapsamlı test — tek bir test fonksiyonunda
onlarca kısmi ödeme/sıfırlama/negatif bakiye/yuvarlama edge-case'i, kod
tekrarı olmadan. Dashboard ve kişi detay ekranları için snapshot test.

---

## FAZ 2 — Çoklu Para Birimi ve Altın Desteği
**Hedef:** Türkiye'ye özgü derinlik katmanı.

- Borç kaydında para birimi seçimi: TRY, USD, EUR + altın türleri (gram, çeyrek,
  yarım, tam, cumhuriyet altını — her biri kendi gram/ayar karşılığıyla), seçim
  UI'ı Design System'deki `CurrencyChip` bileşeniyle yapılır
- Para birimi değiştiğinde `currencyChanged(to:)` analytics event'i (sadece kod,
  ör. `.usd`/`.gold` — tutar/isim yok) gönderilir
- **Önemli ayrım:** Bir borcu gram altın olarak kaydetmek (miktar + tür) HİÇBİR
  API'ye bağımlı değildir, her zaman çalışır — bu çekirdek özelliktir ve asla
  API'nin çökmesine bağlı olarak bozulmamalıdır. Sadece "bu altının bugünkü TL
  karşılığı" gösterimi API'ye bağımlıdır ve API çökerse sadece bu gösterim
  "şu an hesaplanamıyor" der, borcun kendisi (gram cinsinden) her zaman görünür
  ve doğru kalır.
- **TCMB döviz kuru API entegrasyonu** (ücretsiz, resmi, key gerektirmez) —
  `https://www.tcmb.gov.tr/kurlar/today.xml` adresinden XML olarak çekilir,
  `Networking` modülü içinde bir `XMLParsingService` ile parse edilip
  Domain katmanındaki modele dönüştürülür. Cache/rate-limit mantığı, yukarıda
  tanımlanan `RatesCache` actor'ü içinde yaşar.
- **Altın fiyatı API kaynağı** — TCMB'nin resmi bir gram altın/piyasa fiyatı
  servisi YOK, bu yüzden bir 3. parti kaynak (ücretsiz topluluk API'si veya
  freemium bir agregatör) kullanılmalı. Bu kaynak döviz kadar garantili
  olmadığından, offline/hata fallback mekanizması burada özellikle kritiktir
- **Kritik mimari kural:** Borç kaydı her zaman orijinal biriminde saklanır;
  TL karşılığı sadece gösterim katmanında hesaplanır, asıl veriyi değiştirmez
- API hata/offline durumunda son önbelleklenmiş veriyi gösterme + kullanıcıyı
  asla boş ekranda bırakmama stratejisi
- **Cache/güncelleme politikası:** Döviz ve altın kurları günde bir kez
  (ör. uygulama açılışında, son güncellemeden 6+ saat geçmişse) çekilir —
  her ekran açılışında API'ye gitmek yerine, gereksiz batarya/veri tüketimini
  önlemek için yerel cache kullanılır, cache üzerinde "son güncelleme: X"
  bilgisi gösterilir
- **Altın hesaplama hassasiyeti:** Ayar/milyem bazlı hesaplama ayrı bir
  `GoldCalculationService` içinde izole edilir (gram × ayar katsayısı ×
  güncel gram fiyatı), böylece bu mantık tek bir yerden test edilir ve
  yanlışlıkla farklı ekranlarda tutarsız hesaplama riski ortadan kalkar
- "Bu sadece bilgi amaçlıdır" net etiketlemesi TL karşılığı gösterilen her yerde
- **Locale-aware sayı/para formatlaması:** Tutar gösterimi asla elle string
  birleştirerek yapılmaz (`"\(amount) TL"` gibi YASAK). `NumberFormatter` +
  `Locale.current` kullanılır — çünkü ondalık ayracı (Türkçe'de virgül,
  İngilizce'de nokta), binlik ayracı ve rakam yönü (Arapça'da farklı) dile
  göre değişir. 6 dilli bir uygulamada bunu elle yönetmeye çalışmak hem hataya
  açık hem de gereksizdir — sistem API'sine bırakılmalı.

**Test:** Altın gramaj/ayar hesaplama mantığı için Swift Testing ile parametreli
test, API client için mock'lanmış networking testleri (`RatesCache` actor'ünün
thread-safety'sini de kapsayan), offline fallback senaryosu testi.

---

## FAZ 3 — Güvenlik ve Veri Bütünlüğü
**Hedef:** "Banka gözünde ciddiye alınma" katmanı.

- Face ID / Touch ID uygulama kilidi (Secure Enclave)
- **Biyometrik fallback kuralı:** Face ID/Touch ID kullanılamıyorsa (donanım
  yok, kullanıcı devre dışı bırakmış, art arda başarısız deneme) sistem
  otomatik olarak cihaz şifresine (passcode) düşer — kullanıcı asla
  uygulamadan tamamen kilitlenip kalmamalı
- **Denetim izi (audit trail) — genişletilmiş kapsam:** İki taraflı onay
  mekanizması olmadığı için, kullanıcının kendi kayıtlarına güvenini artıran
  alternatif bir teknik çözüm: her borç/ödeme kaydı düzenlemesi, **değiştirilemez
  (append-only)** bir denetim kaydı oluşturur (eski değer, yeni değer, zaman
  damgası). **Bu log artık sadece manuel düzenlemeleri değil, CloudKit
  senkronizasyon çakışmalarını da kapsar:** last-write-wins uygulandığında,
  "bu kayıt {tarih}'te başka bir cihazda güncellendi, eski değer X, yeni değer Y"
  satırı otomatik olarak aynı audit trail'e eklenir. Böylece hem kullanıcı
  düzenlemesi hem sync çakışması aynı güven mekanizmasından geçiyor ve
  mülakatta event-sourcing benzeri bir düşünce tarzı gösterme fırsatı sunuyor.
- Keychain üzerinden hassas veri şifreleme
- ~~Certificate pinning~~ — **kasıtlı olarak yok**, standart ATS/TLS
  doğrulaması yeterli (gerekçe yukarıda, ayrı başlıkta)
- Jailbreak tespiti (opsiyonel uyarı, uygulamayı kapatmaz/engellemez)
- Silme işlemlerinde 5-10 saniyelik "Geri Al" (Undo) penceresi
- SwiftData + CloudKit otomatik senkronizasyon — çakışma çözme stratejisi:
  **last-write-wins + kullanıcıya bilgilendirme + yukarıdaki audit trail'e
  otomatik kayıt**
- PDF/CSV dışa aktarma (kullanıcı kendi verisini her an alıp çıkabilmeli, audit
  izi de dahil edilebilir); dışa aktarma tamamlandığında `exportUsed(format:)`
  event'i gönderilir (sadece `.pdf`/`.csv`, dosya içeriği asla)
- Face ID/Touch ID kilidi açıldığında `biometricLockEnabled(Bool)` event'i gönderilir
- Arka plana geçince otomatik blur/kilitleme, hassas ekranlarda ekran görüntüsü
  engelleme
- **Senkronizasyon/yedekleme durumu göstergesi:** Ayarlar ekranında "Son
  senkronizasyon: X dakika önce" veya "iCloud'a bağlı değil" gibi basit bir
  durum göstergesi
- **"Verilerimi Sil" (YENİ — v4):** Ayarlar'da, çift onaylı (uyarı diyaloğu +
  yazarak onaylama gibi ek bir güvenlik adımı) bir "Tüm Verilerimi Sil"
  seçeneği — hem yerel SwiftData store'unu hem CloudKit'teki kayıtları temizler.
  Düşük maliyetli ama "verim tamamen bende, istediğim an tamamen silebilirim"
  hikayesini eksiksiz kılan, gizlilik anlatısını güçlendiren bir özellik.
  Tamamlandığında sadece anonim bir `dataDeleted` event'i gönderilir (hangi
  kayıtların silindiğine dair hiçbir detay yok).

**Test:** Keychain wrapper testleri (Swift Testing), Face ID mock'lanmış
authentication flow testi (fallback senaryosu dahil), audit trail'in hem
manuel düzenlemede hem CloudKit sync çakışmasında doğru kayıt oluşturduğunu
doğrulayan testler, "Verilerimi Sil" akışının hem yerel hem CloudKit
kayıtlarını eksiksiz temizlediğini doğrulayan test.

---

## FAZ 4 — Dashboard Derinleştirme, Bildirimler, Grafikler
**Hedef:** Recurring kullanım mekanizmaları.

- **Vade tarihi ve hatırlatma sistemi (detaylı tasarım):**
  - Borç kaydı oluştururken opsiyonel "vade tarihi" alanı
  - Hatırlatma zamanı seçenekleri (çoklu seçilebilir): vade günü, 1 gün önce,
    3 gün önce, 1 hafta önce
  - Her iki yön için de çalışır: "Ahmet'ten alacağın var, vade bugün" /
    "Ayşe'ye borcun var, ödeme günü"
  - **Local notification** kullanılır (`UNUserNotificationCenter` üzerinden,
    push notification DEĞİL). Vade günü aynı gün olan bildirimler için
    `.timeSensitive` interruption level kullanılabilir (kullanıcının Odaklanma
    modlarını da dikkate alarak).
  - Rich notification action: bildirime "Ödendi olarak işaretle" butonu
    eklenir (`UNNotificationAction` ile)
  - **64 bildirim limiti çözümü:** iOS bir uygulamaya en fazla 64 bekleyen
    local notification hakkı tanır. Sistem şöyle çalışmalı: tüm hatırlatmalar
    veritabanında tutulur, ama sadece **en yakın tarihli 64 tanesi** iOS'a
    planlanır. Uygulama arka plana her geçtiğinde veya açıldığında, planlanmış
    bildirimler kontrol edilir, tetiklenmiş/geçmiş olanlar temizlenir ve
    kuyruktaki bir sonraki hatırlatma yeniden planlanır.
  - **Senkronizasyon kuralı (kritik):** Bir borç "ödendi" olarak işaretlenirse
    veya vade tarihi değiştirilirse/silinirse, o kayda ait TÜM bekleyen
    bildirimler önce iptal edilir (`removePendingNotificationRequests`),
    sonra gerekiyorsa yeni tarihle yeniden planlanır.
  - Bildirim izni reddedilirse: sessizce devre dışı kal, Ayarlar'a
    yönlendiren pasif bir link göster, tekrar tekrar izin isteme.
  - `notificationPermission(granted:)` ve bir hatırlatma planlandığında
    `notificationScheduled` event'i gönderilir.
- **İstatistikler ekranı (tam kapsam — yukarıdaki Design System bölümündeki
  "Grafik ve İstatistik Ekranı" alt başlığına bkz.):** Swift Charts ile 6
  grafik — net durum zaman çizelgesi, alacak/borç aylık karşılaştırma, kişi
  bazlı dağılım (ilk 5-10), para birimi/tür dağılımı (ayrı ayrı, naif toplama
  yok), ödenmiş/bekleyen oranı, opsiyonel vade takvimi yoğunluğu. Üstte zaman
  aralığı seçici (3A/6A/1Y/Tümü) + `CurrencyChip` filtre şeridi, tüm grafikler
  `ChartCard` bileşeni içinde. Az veri durumunda boş-durum mesajı. Bir grafik
  görüntülendiğinde `chartViewed(ChartType)` event'i gönderilir.
- Arama/filtreleme (kişi, tarih, ödenmiş/ödenmemiş durumu)
- Settings ekranı: light/dark tema seçimi (`themeChanged(to:)` event'i), dil
  seçimi (sistem otomatik + manuel override, `languageChanged(to:)` event'i —
  sadece dil kodu)
- **Ayarlar > Gizlilik altında iki switch:** "Kullanım İstatistiklerini Paylaş"
  (Analytics) ve "Çökme Raporlarını Paylaş" (Crashlytics), ikisi de varsayılan
  açık ve birbirinden bağımsız kapatılabilir; kapatma/açma anında
  `analyticsOptOut(Bool)` event'i (kapatılmadan hemen önce) gönderilir ve
  ardından `setAnalyticsCollectionEnabled`/`crashlyticsCollectionEnabled`
  çağrılır.
- **Taksitli/tekrarlayan borç desteği:** Kullanıcı "12 ay taksitle borç
  verdim/aldım" gibi bir kayıt girebilmeli — tek bir borç yerine otomatik
  olarak N adet alt-kayıt (installment) üretilir, her biri kendi vade
  tarihine ve hatırlatmasına sahip olur.

**Test:** Notification scheduling/iptal/yeniden planlama mantığı için kapsamlı
test (özellikle 64 limit senaryosu ve ödeme sonrası iptal senaryosu), taksit
bölme algoritması için Swift Testing ile parametreli test (küsuratlı tutarların
taksitlere doğru dağıtılması — örn. 1000 TL / 3 taksit = 333.33 + 333.33 +
333.34, toplamın her zaman orijinal tutara tam eşit olduğunun garantisi),
filtreleme/arama use case testleri, grafik veri agregasyon fonksiyonları için
parametreli testler (para birimlerinin asla naif toplanmadığının garantisi
dahil), Analytics opt-out switch'inin gerçekten collection'ı durdurduğunu
kanıtlayan test.

---

## FAZ 5 — Widget, Reklam, Erişilebilirlik, Cila, Gizlilik Uyumu
**Hedef:** Son parlatma, App Store'a hazır hale getirme, gerçek gizlilik uyumu.

- WidgetKit: ana ekran widget'ı (toplam net durum özeti, Design System token'larıyla
  temalı); widget eklendiğinde `widgetAdded` event'i gönderilir
- **Opsiyonel "vitrin" katmanı — Live Activity / Dynamic Island:** Vade günü
  bugün olan bir borç/alacak için kilit ekranında/Dynamic Island'da canlı
  durum gösterimi. Ürün için şart değil, ama düşük maliyetli, güncel iOS API
  bilgisi sinyali veren bir ek.
- App Intents/Siri Shortcuts (opsiyonel): "Ahmet'e olan borcumu göster" gibi
  komutlarla doğrudan bir kişinin borç durumuna erişim
- Google AdMob entegrasyonu (banner, hassas ekranlarda gösterilmeyecek şekilde
  dikkatli yerleşim) + **App Tracking Transparency (ATT) izin akışı**:
  kullanıcı reddederse non-personalized reklam gösterilir, tekrar tekrar izin
  istenmez, personalized reklam zorlanmaz.
- **Privacy Manifest dosyaları (`PrivacyInfo.xcprivacy`):** Firebase
  Crashlytics, Firebase **Analytics** ve AdMob gibi 3. parti SDK'lar için
  Apple'ın zorunlu kıldığı privacy manifest'lerin eklenmesi, "required reason
  API" kullanımlarının beyan edilmesi.
- **App Store Privacy Nutrition Label'ın gerçek veri akışıyla birebir uyumlu
  doldurulması** — Crashlytics: anonim teşhis verisi, **Analytics: "Kullanım
  Verisi" (Usage Data) kategorisi, kimliğe bağlı değil çünkü `setUserID` hiç
  çağrılmıyor**, AdMob: reklam verisi/kimlik (kullanıcıya bağlı değil) şeklinde
  doğru işaretlenecek. Bu, onboarding'deki gizlilik metniyle (aşağıda
  güncellendi) tutarlı olmalı.
- Google Signals / ad personalization sinyallerinin gerçekten kapalı olduğunun
  Firebase konsolundan son bir kez doğrulanması.
- VoiceOver desteği tüm ekranlarda, Dynamic Type test edilmiş
- RTL layout testi (Arapça için)
- **Localization "native review" adımı:** TR ve EN dışındaki 4 dil (İspanyolca,
  Mandarin, Hintçe, Arapça) için mümkünse bir native speaker'a tek seferlik
  review yaptır; en azından README'de "AI-assisted translation, community
  review'a açık" şeklinde dürüstçe belgele. "Doğal insan çevirisi kalitesi"
  iddiasını gerçekçi kılan tek yol bu — ne sen ne de agent bu dilleri anadili
  olarak konuşmuyor.
- **Opsiyonel:** MetricKit entegrasyonu ile launch time / hang metriklerinin
  toplanması (performans farkındalığı sinyali, kurulumu ucuz)
- App Store Connect metadata: açıklama içinde net sorumluluk reddi
- Son ADR güncellemeleri, README'nin ekran görüntüleriyle tamamlanması

**Test:** Accessibility audit (Xcode Accessibility Inspector) — Design System
renk token'larının light/dark'ta WCAG AA kontrastı karşıladığının doğrulanması
dahil, tam regresyon snapshot test paketi, **ATT reddedilme senaryosu testi**.

---

## Kod Standartları (Her Fazda Geçerli)
- Para ile ilgili her yerde `Decimal`, asla `Double`/`Float`
- Her yeni use case/ViewModel için unit test **zorunlu**, test yazılmadan PR
  tamamlanmış sayılmaz
- Her önemli mimari karar için kısa bir ADR dosyası (`docs/adr/00X-karar-adi.md`)
- Commit mesajları [Conventional Commits](https://www.conventionalcommits.org/) formatında, **CI'da bu format otomatik doğrulanır**
- Her feature modülü kendi test target'ına sahip
- Public API'lerde dokümantasyon yorumları (`///`)
- Proje yönetimi Tuist ile (`Project.swift` manifestoları), elle düzenlenen
  `.pbxproj` yok

### Yorum ve Dil Kuralları (SIKI, İSTİSNASIZ)
- **Kod içi yorumlar SADECE İngilizce.** Türkçe yorum, değişken adı, fonksiyon
  adı YASAK.
- **Gereksiz yorum yasak.** Yorum sadece "neden böyle yapıldığı" belirsizse
  yazılır. Self-documenting code önceliklidir.
- **Hardcoded UI string kesinlikle yasak — istisnasız.** İlk satırdan itibaren
  HER UI string'i String Catalog key'i üzerinden gitmeli. CI'da bunu denetleyen
  bir custom SwiftLint kuralı veya regex script build'i FAIL ettirir.
- Eksik çeviri key'i varsa uygulama İngilizce'ye fallback yapsın (Türkçe'ye
  değil) — bu davranış açıkça kodlanmalı.

### Genel Kod Kalitesi Kuralları
- `Force unwrap (!)` **ve `as!` (force cast)** kullanımı yasak, `guard let`/
  `if let`/nil-coalescing/`as?` kullan. Sadece test kodunda ve gerçekten
  imkansız durumlarda (yorumla gerekçelendirilmiş) istisna kabul edilir.
- `print()` YASAK, `OSLog` ile yapılandırılmış loglama kullan.
- Crashlytics/analytics'e ASLA kişisel veri (isim, tutar, not) gönderilmeyecek.
  Analytics'e SADECE `Observability` paketindeki tip-güvenli `AnalyticsEvent`
  whitelist enum'u üzerinden erişilir; serbest `logEvent(_:parameters:)`
  çağrısı `Observability` dışında CI'da FAIL eder (bkz. yukarıdaki "Firebase
  Analytics" bölümü).
- Magic number yasak, isimlendirilmiş sabitler kullan (spacing/sizing için
  DesignSystem'deki token'lar).
- Bir dosya/tip tek sorumluluğa sahip olacak (Single Responsibility).
- TODO bırakılacaksa mutlaka kısa açıklama içersin, açıklamasız TODO yasak.

---

## YENİ: Kod Mimarisi ve UI Disiplini (Agent İçin Somut Kurallar)

Bu bölüm, agent'ın zamanla "her şeyi yapan büyük View/ViewModel" üretmesini
önlemek için var — büyük projelerde kalite düşüşünün en görünür belirtisi budur.

- **View boyutu:** Bir SwiftUI View struct'ının `body`'si ~40-50 satırı geçmeye
  başlarsa, agent DURUP alt view'lara/extension'lara böler. Bir dosya (view +
  private subview'lar dahil) 300-400 satırı geçmemeli — geçtiyse refactor sinyali
  kabul edilir.
- **View'da business logic YASAK.** View sadece state'i render eder, kullanıcı
  niyetini (`onTapGesture`, `.onChange` vb.) ViewModel'e iletir. Hesaplama,
  doğrulama gibi "iş mantığı" View'da değil, use case/domain katmanında yaşar.
- **ViewModel ince (thin) kalır:** State tutar, use case çağırır, sonucu view'a
  uygun forma sokar. Asıl karar mantığı (örn. "overpayment nasıl hesaplanır")
  her zaman Domain/UseCase katmanında olur, ViewModel'de değil.
- **`@Observable` makrosu kullanılır** (Observation framework, iOS 17+); eski
  `ObservableObject`/`@Published` kullanılmaz — daha az boilerplate, daha modern.
- **Tekrar eden UI parçaları DesignSystem paketine çıkarılır** — aynı buton/
  kart/boş-durum view'ı iki feature modülünde ayrı ayrı yazılmaz.
- **Tekrar eden stil kombinasyonları** (padding+font+corner radius vb.) custom
  `ViewModifier` olarak çıkarılır, view body'lerinde tekrar tekrar yazılmaz.
- **Her View için en az bir `#Preview` zorunlu**, mümkünse birden fazla state
  ile (boş/dolu/hata/yükleniyor).
- **Coordinator'lar sadece navigasyon taşır**, hiçbir business logic
  Coordinator içine sızmaz.
- **Constructor injection tercih edilir**; property/environment injection
  sadece SwiftUI'ın kendi gerektirdiği yerlerde (`@Environment` vb.) kullanılır.
- SwiftData sorguları elle filtreleme yerine derlenmiş **`#Predicate`** makrosu
  ile yazılır — hem performans hem tip güvenliği için.

---

## YENİ: Agent Çalışma Taktikleri (Kapsam Kaçağını Önleme)

- Bir faz üzerinde çalışırken agent SADECE o fazın kapsamındaki işi yapar —
  örn. Faz 1'deyken Faz 3'ün güvenlik kodunu "madem elimdeyken yazayım" diye
  eklemeye başlamaz. Kapsam kaçağı (scope creep), büyük agent görevlerinde
  kalite düşüşünün en büyük sebebidir.
- Yeni bir dosya oluşturmadan önce agent önce mevcut modül/klasör yapısına
  bakar, doğru pakete koyar — rastgele bir yere "geçici" dosya bırakmaz.
- Bir View/ViewModel yazarken satır sayısı yukarıdaki eşikleri geçmeye
  başladığında agent durur, "bu bölünebilir mi" diye kendine sorar, sonra devam eder.
- **Her fazın sonunda agent kendi kendine kısa bir self-review checklist'i
  geçer:** SwiftLint temiz mi, force unwrap/force cast var mı, hardcoded UI
  string var mı, herhangi bir dosya eşik boyutunu aştı mı, yeni eklenen her
  use case/ViewModel için test yazıldı mı, coverage eşiği düştü mü — bunlar
  özet raporunda kullanıcıya da bildirilir.
- Emin olmadığı bir mimari karar noktasında (örn. conflict resolution
  stratejisi) agent varsayım yapıp geçmez, kullanıcıya sorar.

---

## Edge Case Kararları (Agent'ın Kafasına Göre Karar Vermemesi İçin)

Bunlar önceden karara bağlanmış davranışlar. Agent bu konularda kendi kafasına
göre bir şey uydurmayacak, aşağıdaki kurallara uyacak.

| Durum | Karar |
|---|---|
| Kullanıcı bir kişiyi silmek isterse, o kişiye ait borç kayıtları varsa | Sert silme yasak. Önce uyarı göster: "Bu kişinin X adet kaydı var, önce onları arşivleyin veya kaydı silin." Soft-delete (arşivleme) tercih edilir, kalıcı silme ayrı bir onay adımı gerektirir. |
| Kullanıcı borçtan fazla ödeme girerse (overpayment) | Sistem izin verir ama bakiyeyi negatif (yani "artık sana borçlu" durumuna) çevirir ve bunu net bir şekilde UI'da gösterir, hata fırlatmaz. |
| CloudKit hesabı yoksa / iCloud'a giriş yapılmamışsa | Uygulama yerel modda (sadece cihazda) çalışmaya devam eder. Kullanıcıya nazik bir bilgilendirme gösterilir, engelleyici bir hata ekranı GÖSTERİLMEZ. |
| CloudKit senkronizasyon çakışması (iki cihazda aynı kayıt değiştirilmiş) | Last-write-wins (son yazan kazanır) + kullanıcıya "bu kayıt başka bir cihazda güncellendi" bilgilendirmesi + **audit trail'e otomatik kayıt**. Sessiz üzerine yazma yasak. |
| Uygulama production'a çıktıktan sonra CloudKit şemasında değişiklik gerekirse | Sadece **ekleme** yapılır (yeni alan/entity); mevcut alan/entity silinmez, yeniden adlandırılmaz, tipi değiştirilmez — CloudKit bunu veri kaybı olarak yorumlar. |
| Döviz/altın API'sine erişilemezse (offline, timeout, 5xx) | Son önbelleklenmiş değer gösterilir + "X saat önceki kur" etiketiyle. Asla boş/kırık ekran gösterilmez. API 24 saatten uzun süre yanıt vermezse kullanıcıya pasif bir uyarı gösterilir. |
| Çeviri key'i eksikse | İngilizce'ye fallback. Asla ham key adı ekranda görünmez. |
| Kullanıcı bildirim izni reddederse | Uygulama normal çalışmaya devam eder, hatırlatma özelliği sessizce devre dışı kalır, tekrar tekrar izin isteme YASAK. |
| **Kullanıcı ATT (App Tracking Transparency) iznini reddederse** | Non-personalized reklam gösterilir, tekrar tekrar izin istenmez, personalized reklam zorlanmaz. |
| Aynı kişiyle birden fazla para biriminde borç varsa (örn. hem TL hem USD borç) | Bunlar ayrı ayrı gösterilir, TEK bir toplam rakama zorla çevrilip toplanmaz. Dashboard'da "X TL + Y USD + Z gram altın" gibi ayrıştırılmış gösterim. |
| Dışa aktarma (PDF/CSV) sırasında veri büyükse | İşlem arka planda yapılır, UI donmaz, ilerleme göstergesi gösterilir. |
| Jailbreak tespit edilirse | Uygulama kapatılmaz/engellenmez, sadece pasif bir güvenlik uyarısı gösterilir. |
| Bekleyen local notification sayısı iOS'un 64 limitini aşarsa | Sadece en yakın tarihli 64 hatırlatma iOS'a planlanır, kalanı veritabanında bekler; uygulama her açılışta/arka plana geçişte kuyruğu kontrol edip bir sonrakini planlar. |
| Borç "ödendi" işaretlenir veya vade tarihi değişir/silinirse | O kayda ait TÜM bekleyen bildirimler önce iptal edilir, sonra gerekiyorsa yeniden planlanır. |
| Taksitli borç tutarı taksit sayısına tam bölünmüyorsa (örn. 1000 TL / 3) | Küsurat SON taksite eklenir (333.33 + 333.33 + 333.34), toplamın orijinal tutara kuruşu kuruşuna eşit olduğu testle garanti edilir. |
| Face ID/Touch ID kullanılamıyorsa | Otomatik olarak cihaz şifresine (passcode) fallback yapılır. |
| **Kullanıcı Ayarlar'dan Analytics veya Crashlytics'i kapatırsa** | İlgili collection anında durdurulur (`setAnalyticsCollectionEnabled(false)` / `crashlyticsCollectionEnabled = false`), iki switch birbirinden bağımsızdır, tekrar açmaya zorlanmaz, uygulamanın geri kalanı normal çalışmaya devam eder. |
| **Kullanıcı "Verilerimi Sil" seçeneğini kullanırsa (YENİ — v4)** | Çift onay (uyarı + ek bir yazarak-onaylama adımı) alınır, onaylanırsa hem yerel SwiftData store'u hem CloudKit kayıtları silinir, kullanıcı uygulamayı sıfırdan (onboarding'den) başlatır. Geri alma YOKTUR — bu yüzden çift onay şart. |

---

## Kullanıcıya Gösterilecek Ana Metinler (Copy)

Aşağıdaki metinler doğrudan kullanılabilir referans metinlerdir. Agent bunları
birebir kullanabilir veya küçük UI kısıtlarına göre uyarlayabilir, ama ton ve
anlam korunmalı: sıcak ama ciddi, güven veren, asla robotik/resmi-soğuk değil.

### Onboarding — Ekran 1 (Karşılama)
**Başlık:** Kiminle ne durumdasın, hep bil.
**Alt metin:** Arkadaşına verdiğin, komşundan aldığın, unutulan ya da
unutulması istenmeyen her borç burada güvenle kayıt altında.

### Onboarding — Ekran 2 (Nasıl çalışır)
**Başlık:** Elinle tuttuğun kadar net
**Alt metin:** Kimden ne kadar alacaklısın, kime ne kadar borçlusun — tek
bakışta gör. Kısmi ödemeleri işle, hiçbir şey gözünden kaçmasın.

### Onboarding — Ekran 3 (Gizlilik/Güvenlik) — **GÜNCELLENDİ (v3)**
**Başlık:** Verin sende kalır
**Alt metin:** Borç ve alacak kayıtların hiçbir sunucumuza gönderilmiyor —
yalnızca senin iCloud hesabında, Face ID ile korunan bu cihazda saklanıyor.
Uygulama içindeki reklam, hata bildirimi ve kullanım istatistiği servisleri,
kişisel kayıtlarına dokunmadan yalnızca anonim teknik ve davranışsal veri
kullanır; bunu dilediğin an Ayarlar'dan kapatabilirsin.

> *Neden değişti (v2):* Eski metin "hiçbir sunucuya göndermiyoruz" diyordu, ama
> Firebase Crashlytics (teşhis verisi) ve Google AdMob (reklam verisi/kimlik)
> gerçekte veri gönderiyor. Blanket bir "hiçbir şey gitmiyor" iddiası hem
> kullanıcıya yanlış beyan olur hem de Apple'ın Privacy Nutrition Label'ıyla
> pratikte çelişir. Yeni metin, iddiayı doğru kapsama (kişisel borç/alacak
> verisi) çekiyor.
>
> *Neden değişti (v3):* Firebase Analytics eklenince metne "kullanım
> istatistiği" ifadesi de eklendi (Crashlytics/AdMob'un yanına), çünkü artık
> üçüncü bir anonim veri akışı var. Ayrıca kullanıcıya somut bir kontrol
> hatırlatması ("Ayarlar'dan kapatabilirsin") eklendi — bu, Ayarlar >
> Gizlilik'teki iki switch'e (Analytics/Crashlytics) doğrudan atıf yapıyor.

### Onboarding — Ekran 4 (Sorumluluk Reddi — zorunlu, atlanamaz)
**Başlık:** Bilmen gereken önemli bir şey var
**Gövde metni:**
> Bu uygulama, borç ve alacaklarını kişisel olarak takip etmen için
> tasarlandı. Burada tuttuğun kayıtlar hukuki bir belge ya da resmi bir delil
> niteliği taşımaz.
>
> Önemli bir borç ilişkisinde, haklarını korumak için yazılı bir belge almanı
> ya da gerekirse noter onayına başvurmanı öneririz.
>
> Veri kaybı, senkronizasyon aksaklıkları ya da hesaplama hatalarından
> doğabilecek herhangi bir zarardan sorumluluk kabul etmiyoruz. Bu uygulama
> sana yardımcı olmak için burada, ama son sorumluluk her zaman sende.

**Buton:** Anladım, devam edeyim
**Ayarlar'da kalıcı link metni:** Sorumluluk Reddi Beyanını Tekrar Oku

### Boş Durum (Empty State) Metinleri
- Hiç kişi eklenmemişse: **Henüz kimseyle bir hesabın yok** / *İlk kişini
  ekleyerek başla — borcunu ya da alacağını kaydet, aklında tutmak zorunda kalma.*
- Kişi detayında hiç kayıt yoksa: **Bu kişiyle henüz bir kaydın yok**

### Temel Buton/Etiket Metinleri
- "Kişi Ekle" · "Borç/Alacak Ekle" · "Ödeme Kaydet" · "Ödendi Olarak İşaretle"
- Dashboard: "Toplam Alacağın" · "Toplam Borcun" · "Net Durumun"

### Bildirim Metinleri
- Borçlu olduğun taraf için: **Ödeme günün yaklaşıyor** / *{isim}'e olan
  {tutar} borcunun vadesi {tarih}.*
- Alacaklı olduğun taraf için: **Alacağını hatırlatalım** / *{isim}'den
  {tutar} alacağının vadesi bugün.*

### Durum/Uyarı Metinleri
- Kur verisi güncellenemediğinde: *Güncel kur bilgisine şu an ulaşılamıyor.
  Son bilinen değerler gösteriliyor ({X} saat önce güncellendi).*
- Fazla ödeme durumunda: *{isim} borcundan fazla ödeme yaptı. Artık sen
  {isim}'e {tutar} borçlusun.*
- iCloud girişi yoksa: *iCloud hesabına giriş yaparsan verilerin diğer
  cihazlarınla otomatik senkronize olur. Şimdilik yalnızca bu cihazda saklanıyor.*

### Ayarlar > Gizlilik — Analytics/Crashlytics Switch Metinleri **(YENİ)**
- **Kullanım İstatistiklerini Paylaş** / *Hangi özelliklerin kullanıldığını
  anonim olarak paylaşarak uygulamayı geliştirmemize yardımcı ol. Borç/alacak
  kayıtlarına asla dokunulmaz.*
- **Çökme Raporlarını Paylaş** / *Bir sorun oluştuğunda anonim teknik bilgiyi
  bize göndererek hataları daha hızlı düzeltmemizi sağla.*

---

## Çeviri Kalitesi Kuralı (Tüm Diller İçin — Özellikle Türkçe)

Agent'ın ürettiği HER çeviri **doğal, profesyonel bir insan çevirisi** kalitesinde
olmalı — kelime kelime, Google Translate tarzı robotik çeviri KESİNLİKLE KABUL
EDİLMEZ.

- Her dil için o dilin **kendi doğal cümle yapısı ve deyimsel ifadeleri**
  kullanılmalı, kaynak dildeki (Türkçe veya İngilizce) cümle yapısı birebir
  taşınmamalı.
- **Türkçe metinler özellikle önemli** — bu bizim asıl kitlemiz. TDK yazım
  kurallarına uygun, imla hatasız, gerçek bir insanın yazdığı gibi akıcı ve
  sıcak olmalı.
- Finansal bağlamda güven veren, kullanıcıyı ürkütmeyen ama gereken yerde net
  ve ciddi bir dil kullanılmalı.
- **İspanyolca, Mandarin, Hintçe, Arapça için:** Ne sen ne de agent bu dilleri
  anadili olarak konuştuğu için "doğal mı" testini güvenilir şekilde
  yapamazsınız. Faz 5'teki "native review" adımı (yukarıda) bu dört dil için
  zorunlu bir kontrol noktasıdır — atlanmamalı.


---

## Güncel Durum (Temmuz 2026)

| Faz | Durum | Test |
|-----|-------|------|
| **0** — Temel Altyapı + Yasal Zırh | ✅ Tamamlandı | — |
| **1** — MVP Çekirdek | ✅ Tamamlandı | 11 test (8 ViewModel + 3 Domain) |
| **2** — Çoklu Para Birimi + Altın | ✅ Tamamlandı | 17 test (Networking) |
| **3** — Güvenlik ve Veri Bütünlüğü | ✅ Tamamlandı | 7 test (Keychain + Biometric) |
| **4** — Dashboard Derinleştirme | ✅ Tamamlandı | 5 test (Installment) |
| **5** — Widget, Reklam, Erişilebilirlik | ✅ Tamamlandı | 3 test (Widget) |

### Metrikler

| | |
|---|---|
| **Swift dosya** | 83 |
| **SPM paket** | 12 |
| **Test** | 66 (macOS), 79+ (iOS) |
| **Localization key** | 103 (TR/EN dolu, ES/ZH/HI/AR needs_review) |
| **Hardcoded string** | 0 |
| **SwiftLint source error** | 0 |
| **Font** | Plus Jakarta Sans + JetBrains Mono (6 TTF, OFL) |
| **DI Container** | Protokol tabanlı, app lifecycle'a bağlı |
| **Biometric** | Face ID / Touch ID + passcode fallback |
| **Audit Trail** | Append-only, her mutasyonda kayıt |
| **Export** | PDF (UIGraphicsPDFRenderer) + CSV |
| **Widget** | TimelineProvider, App Groups ready |
| **AdMob** | Banner placeholder, ATT flow hazır |
| **Animation** | Spring 60fps, staggered list, skeleton loading |
| **CI/CD** | GitHub Actions: build + test + lint + coverage + commit format |

### Kalan Opsiyonel İşler

- GoogleMobileAds SDK linkleme (Tuist target + Info.plist)
- Widget extension target (Tuist `.appExtension` target)
- ES/ZH/HI/AR native review (manuel, App Store öncesi)
- App Store Privacy Nutrition Label + metadata
- MetricKit dashboard entegrasyonu
- Live Activity / Dynamic Island (opsiyonel)
- App Intents / Siri Shortcuts (opsiyonel)

### Mimari

```
App (VadeApp + AppCoordinator)
├── FeatureOnboarding  (4 ekran, CloudKit kontrol)
├── FeatureDashboard   (DashboardView, PeopleListView, Charts)
├── FeatureDebtDetail  (PersonDetailView, AddDebt, RecordPayment)
├── FeatureSettings    (SettingsView, DataManagementView)
├── FeatureWidget      (TimelineProvider, WidgetEntry)
├── DesignSystem       (Tokens, Typography, 8 bileşen)
├── Core               (Extensions, Security, Notifications, Export)
├── Domain             (Modeller, UseCase protokolleri)
├── Data               (SwiftData modelleri, Repositories, AuditTrail)
├── Networking         (TCMB XML, Gold API, CurrencyConverter)
├── Observability      (Analytics, Crashlytics, AdService, PrivacyInfo)
└── DIContainer        (Container, Resolver, ServiceScope)
```

### Commit Geçmişi

40 commit, kategorize: `feat` (20), `fix` (8), `test` (5), `refactor` (4), `docs` (1), `chore` (1), `build` (1)

