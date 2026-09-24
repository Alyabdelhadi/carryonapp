# CarryOn (Flutter)

Peer-to-peer parcel delivery: post a package to send or receive, or declare
your travel routes and carry packages that match them. This is the Flutter
rewrite of the Ionic/Angular app, on top of the
[flutter_template](https://github.com/momshaddinury/flutter_template) clean
architecture (Riverpod + go_router + Retrofit/Dio).

Backend: the Laravel API at `https://carryon.app/admin/api` (see
`lib/src/data/services/network/endpoints.dart`). The API has no token auth;
the stored user id is the session and every request carries it.

## Requirements

- Flutter 3.47+ / Dart 3.13+ (the template pins `sdk: ^3.13.0`).
- Xcode 15+ with CocoaPods for iOS; Android Studio / SDK 37 for Android.

## Secrets (first clone)

- Copy `lib/src/core/config/app_secrets.example.dart` to `app_secrets.dart` and fill in the Shufti Pro credentials. The file is git-ignored.
- Put the Firebase config files in place: `ios/Runner/GoogleService-Info.plist` and `android/app/google-services.json` (both git-ignored). Without them the app runs, but push notifications stay off.

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Continuous codegen while developing:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Platform setup

- **iOS**: `ios/Runner/GoogleService-Info.plist` (Firebase, bundle id
  `com.CarryOnApp.App`) is included and registered with the Runner target.
  Google Maps key is set in `AppDelegate.swift`.
- **Android**: application id `com.CarryOnApp.App`. Drop the Firebase
  console's `google-services.json` into `android/app/` to enable push; the
  Gradle build applies the google-services plugin only when that file
  exists, so the app builds without it (push is disabled at runtime, every
  other feature works). Google Maps key is in `AndroidManifest.xml`.
- Third-party keys (Google Maps, Shufti Pro) live in
  `lib/src/core/config/app_config.dart`; they are the same values the Ionic
  build shipped.

## Layout

```
lib/src/
├── core/            bootstrap, DI (Riverpod), config, logging, l10n
├── domain/          entities, repository interfaces, use cases
├── data/            Retrofit client, JSON mappers, repository impls, cache
└── presentation/
    ├── core/        router (Routes enum + gate), theme tokens, shared widgets
    └── features/    home, packages, trips, account, auth, splash
```

`docs/conversion_guide.md` maps every Ionic page to its Flutter feature and
lists the conventions (providers, results, session, server-managed copy,
navigation, theme). `docs/architecture.md`, `docs/network.md` and
`docs/router.md` describe the template layers this app follows.

## Features

- Home: banners, the three actions (send / receive / carry), current city,
  matched-package and upcoming-trip indicators, store update prompt.
- Packages: my posted packages and packages I carry, with status timeline,
  carrier/sender contact, extend date, cancel, drop, pickup → transit →
  delivered flow, and carrier rating.
- Matching packages for carriers (from their trips), accept + mark read.
- Post / edit a package: category, weight, value, reward, dates, sender and
  receiver details, map-based address picker with Places search and saved
  addresses, carbon impact preview.
- Trips: one-time or recurring routes between cities, create / edit /
  delete.
- Account: profile with stats (rating, packages, trips, trees saved),
  profile edit, saved addresses, carbon calculator, terms, push toggle,
  logout, delete account.
- Auth: login, signup with selfie + ID verification (Shufti Pro), password
  reset link.

## Languages

English and Arabic. The user picks the language from Account → Language (or the globe button on the login page); the choice is stored on the device and the whole app re-lays out right-to-left for Arabic.

- Strings live in `lib/src/core/localization/intl_en.arb` (template) and `intl_ar.arb`; `flutter gen-l10n` regenerates `lib/src/core/gen/l10n/`. Read them with `context.l10n.key`.
- Every key must exist in both files. Keys are prefixed by feature (`auth…`, `pkg…`, `acc…`, `trip…`, `home…`, `core…`); shared words (`cancel`, `save`, `statusDelivered`…) have no prefix.
- The admin-edited server copy (`getTexts`) is English only, so it is used only while the app is in English. In Arabic the bundled translation is shown.
- Server data with an Arabic form: service tile names, country and city names (pickers, trips, package routes, saved addresses) and the home banners (`img_ar`). Entities expose `nameFor(languageCode)` / `cityFor` / `countryFor` / `imageFor`; use `context.languageCode`. Anything without an Arabic value falls back to English.
- Dates follow the locale for month and weekday names; digits are always Western (0-9).
- Layout uses directional paddings/alignments so it mirrors correctly; fields that hold phone numbers, emails, passwords and amounts stay left-to-right.

## Admin switches

The backend admin page **App Settings** (`/app-settings`, API `GET /appSettings`) turns the Shufti Pro identity check on or off. When it is off, signup still uploads the selfie and ID for manual review and stores `shufti_status = skipped`; if the request fails the app assumes the check is on.

## Credits

- Tab bar icons: [Solar Icons](https://www.figma.com/community/file/1166831539721848736) by 480 Design (CC BY 4.0) for Home, Packages and Account, and [Phosphor Icons](https://phosphoricons.com) (MIT) for Trips. Fetched as SVG from the Iconify CDN into `assets/icons/`.
