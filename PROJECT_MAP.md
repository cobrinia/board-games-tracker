# GameShelf (board_games) — карта проєкту

Flutter-застосунок для обліку настільних ігор, гравців і зіграних партій.
Залежності: `firebase_core`, `firebase_auth`, `firebase_analytics`, `firebase_crashlytics`, `font_awesome_flutter`.
Акаунти — Firebase Authentication (email/пароль + Google). Ігри, гравці й партії поки що mock-дані (Cloud Firestore — у наступних лабораторних).

> Оновлюй цей файл, коли додаєш або перейменовуєш екрани чи віджети.

## Структура `lib/`

```
lib/
├── main.dart                  Firebase.initializeApp → CrashReporting.init → MyApp(AppScope → MaterialApp(home: AuthGate))
├── firebase_options.dart      згенеровано `flutterfire configure` (не редагувати вручну)
├── core/                      спільне для всіх фіч
│   ├── app_scope.dart         AppScope (InheritedWidget): auth + analytics для всіх екранів
│   ├── auth/
│   │   ├── app_user.dart      AppUser — користувач без типів Firebase
│   │   ├── auth_exception.dart AuthException — помилка з повідомленням для користувача
│   │   ├── auth_repository.dart  abstract AuthRepository (інтерфейс)
│   │   └── firebase_auth_repository.dart  реалізація через FirebaseAuth
│   ├── services/
│   │   ├── analytics_service.dart  обгортка FirebaseAnalytics (no-op на Windows і в тестах)
│   │   └── crash_reporting.dart    Crashlytics: обробники помилок, non-fatal, тестовий краш
│   ├── data/
│   │   ├── models.dart        BoardGame, Player, GameSession
│   │   └── mock_data.dart     MockData: static ValueNotifier<List<…>> games / players / sessions
│   ├── theme/
│   │   ├── app_theme.dart     AppTheme.light (ThemeData)
│   │   ├── app_colors.dart    палітра кольорів
│   │   └── box_input_border.dart  кастомна рамка для полів вводу
│   ├── utils/
│   │   ├── formatters.dart    formatDate, formatShortDate, formatTime, formatMonthYear
│   │   └── validators.dart    Validators.required / name / email / password / newPassword / confirmPassword / httpsUrl
│   └── widgets/               UI-кіт (див. нижче)
└── features/                  одна папка на розділ застосунку
    ├── auth/      login, register, forgot password (+ widgets/)
    ├── home/      MainShell (таби) + HomeScreen
    ├── catalog/   каталог ігор, фільтри, деталі, шторка додавання гри
    ├── players/   список гравців, профіль
    ├── sessions/  логування партії, історія (+ widgets/)
    └── settings/  налаштування профілю
```

## Керування станом
- Користувач: `AuthRepository.user` (`ValueListenable<AppUser?>`), джерело — `FirebaseAuth.userChanges()`. Доступ: `AppScope.of(context).auth`.
- Глобальні дані: `MockData.games`, `MockData.players` і `MockData.sessions` (`ValueNotifier`). Екрани слухають їх через `ValueListenableBuilder`, тому додавання чи видалення елемента одразу оновлює UI.
- Локальний стан: `StatefulWidget` + `setState` (форми, фільтри, `TextEditingController`).
- Сторонніх state-management пакетів немає.

## Навігація
- `AuthGate` (home у MaterialApp): сплеш, поки відновлюється сесія → `LoginScreen` (немає користувача) або `MainShell` (є). Екрани самі не переходять у застосунок: вони викликають репозиторій, а `AuthGate` реагує на зміну користувача й закриває Register/Forgot (`popUntil(isFirst)`).
- `LoginScreen` → `ForgotPasswordScreen` / `RegisterScreen` (`push`).
- `MainShell` (`lib/features/home/main_shell.dart`):
  - `IndexedStack` із 4 табами, у **кожного табу свій `Navigator`**: Home, Catalog, Players, Settings.
  - `AppBottomNav` + центральна кнопка «+» відкриває `showModalBottomSheet`, де є «Log Session» (`LogSessionScreen`) і «Add New Game» (`showAddGameSheet`).
  - Кнопка Back на Android спершу робить pop усередині табу, потім повертає на Home, і лише тоді виходить із застосунку.
- Catalog → `FiltersScreen`, `GameDetailsScreen(game:)` → редагування через `showAddGameSheet(initial:)`.
- Players → `PlayerProfileScreen(player:)` → `SessionHistoryScreen`.
- Home → `SessionHistoryScreen`.
- Settings → `EditProfileScreen`; logout: `auth.signOut()` → `AuthGate` показує логін.
- Аналітика: `FirebaseAnalyticsObserver` на кореневому навігаторі й на навігаторі кожного табу (маршрути мають `RouteSettings(name:)`), перемикання табів — `logScreen()`.

## Спільні віджети — `lib/core/widgets/`

| Файл | Віджет / функція | Тип |
|---|---|---|
| `app_bottom_nav.dart` | `AppBottomNav` | Stateless |
| `app_buttons.dart` | `PrimaryButton`, `SecondaryButton` | Stateless |
| `app_choice_chip.dart` | `AppChoiceChip` | Stateless |
| `app_search_field.dart` | `AppSearchField` | Stateless |
| `badges.dart` | `AppBadge` | Stateless |
| `circle_icon_button.dart` | `CircleIconButton` | Stateless |
| `custom_text_field.dart` | `CustomTextField` | Stateful |
| `game_card.dart` | `GameCard` | Stateless |
| `player_avatar.dart` | `PlayerAvatar`, `AvatarStack` | Stateless |
| `stat_card.dart` | `StatCard` | Stateless |
| `avatar_picker_dialog.dart` | `showAvatarPickerDialog()` → URL; готові аватари (`presetAvatarUrls`) або власне https-посилання з попереднім переглядом | функція + приватні |
| `app_feedback.dart` | `showSuccessSnackBar()`, `showErrorSnackBar()`, `showConfirmDialog()` → `Future<bool>` | функції |

## Екрани та віджети фіч — `lib/features/`

| Модуль | Екрани | Допоміжні віджети |
|---|---|---|
| `auth/` | `AuthGate`, `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen` (усі Stateful) | `widgets/auth_layout.dart`: `AuthLayout`, `AuthHeader`; `widgets/social_sign_in_button.dart`: `SocialSignInButton`, `OrDivider` |
| `home/` | `MainShell` (Stateful), `HomeScreen` (Stateless) | — |
| `catalog/` | `CatalogScreen`, `FiltersScreen` (+ `CatalogFilters`), `GameDetailsScreen`, `AddGameSheet` / `showAddGameSheet()` | `_Header`, `_HeaderTag`, `_SessionLogRow`, `_CoverPhotoPlaceholder` |
| `players/` | `PlayersScreen` (Stateful; додавання гравця через `showDialog`), `PlayerProfileScreen` (Stateless) | `_PlayerTile`, `_Achievement` |
| `sessions/` | `LogSessionScreen` (вибір гравця через `showModalBottomSheet`), `SessionHistoryScreen` | `_ScoreRow`, `AppWinnerBadge`; `widgets/session_card.dart`: `SessionCard` |
| `settings/` | `SettingsScreen` (Stateful: зміна пароля, прив'язка Google, підтвердження email, тест Crashlytics, вихід), `EditProfileScreen` (ім'я + фото) | `_ProfileCard`, `_SmallAction`, `_SectionLabel`, `_SettingsRow`, `_LabeledField` |

Правило: віджети з префіксом `_` приватні й живуть у файлі свого екрана. Віджети, які перевикористовуються, лежать у `core/widgets/` або `features/<фіча>/widgets/`.

## Вбудовані віджети Flutter, які використовуються
- **Розмітка:** `SizedBox`, `Row`, `Column`, `Expanded`, `Padding`, `Container`, `Center`, `Align`, `Wrap`, `Spacer`, `Stack` + `Positioned`, `SafeArea`.
- **Списки та прокрутка:** `ListView`, `ListView.separated`, `GridView.builder`, `SingleChildScrollView`, `Dismissible`.
- **Каркас екрана:** `Scaffold`, `AppBar`, `IndexedStack`, `Card`, `ListTile`, `SwitchListTile`, `ExpansionTile`, `Divider`.
- **Введення даних:** `Form`, `TextField`, `DropdownButtonFormField`, `Checkbox`, `Slider`, `showDatePicker`.
- **Кнопки:** `FilledButton`, `TextButton`, `IconButton`, `InkWell`, `Tooltip`.
- **Відображення:** `Text`, `Icon`, `CircleAvatar`, `ClipRRect`, `LinearProgressIndicator`.
- **Діалоги:** `AlertDialog`, `SnackBar`, `showModalBottomSheet`, `showDialog`.
- **Реактивність:** `ValueListenableBuilder` / `ValueNotifier`.

## Історія лабораторних
1. Lab 1: базовий проєкт.
2. Lab 2: базовий функціонал, нижня навігація, логін.
3. Lab 3: початкова реалізація UI та основних екранів.
4. Lab 4: Firebase Auth (email/пароль, Google, відновлення пароля, профіль, зміна пароля), Analytics, Crashlytics, валідація форм, `AuthRepository`.

## Тести
- `test/fake_auth_repository.dart` — `FakeAuthRepository` (акаунт test@example.com / secret123), тести працюють без Firebase.
- `test/widget_test.dart` — логін, реєстрація, відновлення пароля, Google, вихід, зміна пароля, таби.
- `test/validators_test.dart` — юніт-тести валідаторів.
