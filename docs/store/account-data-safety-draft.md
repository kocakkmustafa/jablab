# Motion hesabı bağlanınca mağaza gizlilik beyanı taslağı — JabLab

Durum (2026-09-25): Motion üretim şeması ve SMTP kuruldu; gerçek
e-posta teslimi gözlendi. Kurucu ilk sürümde ücretli kamera oturumlarını ve
abonelik satışını erteledi. Mağaza veri formları ve iPhone kabulü ayrıca
doğrulanacak; bu dosya konsolda onaylanmış nihai beyan değildir.

| Veri | Mevcut hesap tasarımı | Beyan adayı |
|---|---|---|
| E-posta | Kayıt, giriş, doğrulama ve parola kurtarma için Supabase Auth'a gönderilir | Apple: `NSPrivacyCollectedDataTypeEmailAddress`; Play: Personal info / Email address; hesaba bağlı, uygulama işlevi |
| Görünen ad | Kullanıcı isteğe bağlı kaydeder; Motion profilinde sunucuya gönderilir | Apple: `NSPrivacyCollectedDataTypeName`; Play: Personal info / Name; isteğe bağlı, hesaba bağlı, uygulama işlevi |
| Ortak hesap ID'si | Oturum ve uygulamaya özel yerel veri ayrımı için kullanılır | Apple: `NSPrivacyCollectedDataTypeUserID`; Play: Personal info / User IDs; hesaba bağlı, uygulama işlevi |
| Satın alma geçmişi | İlk sürümde satış ve satın alma doğrulaması kapalı; uygulama işlem geçmişi göndermez | İlk sürüm Apple/Play veri beyanına girmez; satış açılırsa yeniden değerlendirilir |
| Kamera görüntüsü ve eklem noktaları | Cihazda işlenir; hesap servisine gönderilmez | Görüntü yükleme beyanı yok; canlı SDK ve ağ trafiği release öncesi tekrar denetlenmeli |
| Ders ve seans geçmişi | Yalnız uygulama destek dizinindeki kullanıcıya ayrılmış JSONL dosyasında kalır; guest geçmişi girişte devralınmaz | Sunucuya aktarılmadığı sürece Apple/Play “collected” tanımına girmez; manifestte yerel geçmiş için ayrı collected data türü yoktur |

Kaynakta iOS `PrivacyInfo.xcprivacy` üç Apple hesap veri tipini `Linked=true`, `Tracking=false`, `PurposeAppFunctionality` ile beyan eder; Android INTERNET ve exact `com.yulalab.jablab://auth/callback` kaydı var. Tracking false kalır. Mikrofon API'si kullanılmadığı sürece mikrofon izni eklenmez. Supabase ve native eklentilerin birleşik Xcode privacy raporu, Android manifest merge ve gerçek mağaza formları ayrı release kapısıdır. Hesap silme uzakta başarılı olduktan sonra yalnız ilgili kullanıcıya ait yerel seans dosyası silinir; sunucu hatasında yerel dosya korunur.

Kaynak: [Apple privacy manifest](https://developer.apple.com/documentation/BundleResources/describing-data-use-in-privacy-manifests), [Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/), [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469).
