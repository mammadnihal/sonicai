# sonicAI - Flutter AI Chat App

Bu, Flutter ilə qurulmuş, istifadəçi dostu interfeysə malik güclü bir
süni intellekt söhbət tətbiqidir. Tətbiq söhbət seanslarını yadda
saxlamaq üçün yerli yaddaşdan istifadə edir və Azure OpenAI xidmətləri
ilə inteqrasiya olunmuşdur.

## Xüsusiyyətləri

-   **Müasir UI/UX Dizaynı:** Şık və intuitiv istifadəçi interfeysi.
-   **Yan Menyu:** Yeni söhbət yaratmaq və keçmiş söhbətlərə asanlıqla
    daxil olmaq üçün yan menyu.
-   **Canlı Yazma Animasiyası:** İstifadəçi təcrübəsini artırmaq üçün AI
    cavabları üçün yazma animasiyası.
-   **Söhbət Seanslarının İdarə Edilməsi:** Söhbət tarixçəsini saxlamaq
    üçün seansların avtomatik idarə edilməsi.
-   **Provider Paketindən İstifadə:** Tətbiqin vəziyyətini idarə etmək
    üçün Provider state management paketi ilə effektiv işləmə.
-   **Yerli Yaddaş:** Söhbətləri cihazda saxlamaq üçün
    shared_preferences istifadəsi.

## Tətbiqin Vizual Təqdimatı

## Başlamaq üçün

Bu layihəni yerli olaraq işlətmək üçün aşağıdakı addımları izləyin.

### Önşərtlər

-   Flutter SDK
-   Android Studio və ya VS Code
-   Azure OpenAI xidmətlərinə giriş və bir API açarı.

### Quraşdırma

Layihəni klonlayın:

``` bash
git clone https://github.com/Sizin-Github-Adınız/sizin-repo-adınız.git
cd sizin-repo-adınız
```

Lazımi paketləri quraşdırın:

``` bash
flutter pub get
```

`lib/main.dart` faylını açın və Azure API konfiqurasiyalarınızı
dəyişdirin:

``` dart
// Provider sinifi
class ChatProvider with ChangeNotifier {
    ...
    final String _azureEndpoint = "SİZİN AZURE ENDPOINTUNUZ";
    final String _azureApiKey = "SİZİN AZURE API AÇARINIZ";
    ...
}
```

Tətbiqi işə salın:

``` bash
flutter run
```

## Əlaqə

Bu layihə haqqında hər hansı bir sualınız və ya təklifiniz varsa,
nihalmammad@gmail.com ünvanına e-poçt göndərə bilərsiniz.
