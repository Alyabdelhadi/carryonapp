# CarryOn: Ionic → Flutter conversion guide

This document is the contract for anyone converting an Ionic page into a
Flutter feature in this project. The foundation (data, domain, DI, router,
theme, shared widgets) is done; feature work only touches
`lib/src/presentation/features/<feature>/`.

## Source of truth

- Ionic app: `../user-1 2/src/app/<page>/<page>.page.{ts,html,scss}`.
- Backend contract: `lib/src/data/services/network/rest_client.dart` and the
  mappers in `lib/src/data/mappers/json_mappers.dart` (field names, success
  envelopes).
- Every backend response is decoded to an entity in
  `lib/src/domain/entities/`. Never touch raw JSON in presentation.

## Ionic → Flutter page map

| Ionic page | Flutter file (`lib/src/presentation/features/...`) | Route |
|---|---|---|
| `home` | `home/view/home_page.dart` | `Routes.home` (tab) |
| `parcel` | `packages/view/packages_page.dart` | `Routes.packages` (tab) |
| `my` | `trips/view/trips_page.dart` | `Routes.trips` (tab) |
| `account` | `account/view/account_page.dart` | `Routes.account` (tab, signed in) |
| `login` | `auth/view/login_page.dart` | `Routes.login` and the account tab when signed out (`embeddedInTab: true`) |
| `signup` | `auth/view/signup_page.dart` | `Routes.signup` |
| `forgot` | `auth/view/forgot_password_page.dart` | `Routes.forgotPassword` |
| `list` | `packages/view/matching_packages_page.dart` | `Routes.matching` |
| `order-detail` | `packages/view/order_detail_page.dart` | `Routes.orderDetail` (`/order/:id`, extra: `ParcelOrder`) |
| `pview` (receive) + `pviewsend` (send) | `packages/view/order_form_page.dart` | `Routes.orderForm` (extra: `OrderFormArgs`) |
| `paddress` | `packages/view/address_picker_page.dart` | `Routes.addressPicker` (extra: `AddressPickerArgs`, pops `OrderAddress`) |
| `success/:type` | `packages/view/success_page.dart` | `Routes.success` (`SuccessType`) |
| `rate` (modal) | `packages/widgets/rate_carrier_sheet.dart` | bottom sheet from order detail |
| `trip` | `trips/view/trip_form_page.dart` | `Routes.tripForm` (extra: `Trip?`) |
| `setting` | `account/view/profile_page.dart` | `Routes.profile` |
| `select-address` | `account/view/addresses_page.dart` | `Routes.addresses` |
| `address` | `account/view/address_form_page.dart` | `Routes.addressForm` (extra: `Address?`) |
| `offer` (carbon calculator) | `account/view/carbon_calculator_page.dart` | `Routes.carbonCalculator` (extra: `CarbonCalculatorArgs?`) |

Dead Ionic pages (unreachable from the shipped app, or calling endpoints the
backend does not have) are **not** converted: about, cart, cate, cate-page,
checkout, city, contact, detail, done, faq, folder, info, item, lang, menu,
myparcel, note, option, payment (fully commented out), pinfo, search, tip,
welcome.

## How a page is built

1. **Providers** live in `<feature>/riverpod/`. Feature code declares
   providers by hand (`FutureProvider.autoDispose`, `AsyncNotifierProvider.
   autoDispose`) so no build_runner pass is needed; core/DI keeps
   `@riverpod` codegen. Reads go through use cases:
   `ref.read(getMyTripsUseCaseProvider).call(userId)`. Every use case is
   registered in `lib/src/core/di/parts/use_cases.dart`. Do not add
   repositories, DI entries or endpoints from feature code; if one is
   missing, note it in your report.
2. **Results**: use cases return `Result<T, BusinessFailure>`. Match with
   `switch (result) { case Success(:final data): ...; case Error(:final error): ... }`.
   Show errors with `AppFeedback.error(context, error)`; `FailureView` for
   full-body failures. Do not show raw strings from exceptions.
3. **Session**: `ref.watch(currentUserIdProvider)` (int?),
   `ref.watch(currentUserProvider)` (`AppUser?`),
   `ref.watch(sessionStatusProvider)`. Guard whole bodies with
   `LoginRequired(child: ...)`; guard single actions with
   `requireLogin(context, ref, () {...})`. After login/signup/logout call
   `ref.invalidate(sessionStatusProvider)`; `currentUser*` providers follow.
4. **Server copy**: the Ionic pages read labels from `text.<key>`. Use
   `ref.texts.get('<key>', 'English fallback')` (import
   `presentation/core/extensions/app_texts_extension.dart`) for those same
   keys, with the string from the live API as the fallback. Copy that never
   came from `text.*` is a plain literal.
5. **Navigation**: only `Routes` enum members. `context.pushNamed(Routes.x.name, extra: ...)`,
   `context.goNamed(Routes.home.name)` for tab switches, `context.pop(result)`
   for pickers. Path params: `pathParameters: {'id': '$id'}`.
6. **Theme**: never hard-code colours, sizes or text styles. Use
   `context.color.*` (incl. `context.color.accent.eco` for impact stats),
   `context.dimensions.space/radius/size/elevation.*`, `context.textStyle.*`.
   Buttons: `FilledButton` (primary), `OutlinedButton`, `TextButton`.
7. **Shared widgets** (`presentation/core/widgets/`): `SectionCard`,
   `SectionHeader`, `DetailRow`, `EmptyState`, `StatusBadge`/`TagChip`/
   `statusColors`/`statusLabel`, `AppNetworkImage` (+ `UploadKind`),
   `UserAvatar`, `LoadingIndicator`, `FailureView`, `AppFeedback.toast/error/
   confirm/alert`, `LoginRequired`/`requireLogin`. Formatting:
   `presentation/core/utils/formatters.dart`.
8. **Files**: one widget class per file in `<feature>/widgets/` when a
   fragment is reused or larger than ~60 lines. No helper methods that
   return widgets (custom lint). No cross-feature imports; share through
   `presentation/core`.
9. **Lists**: pull-to-refresh with `RefreshIndicator` and `ref.invalidate`.
   Skeletons in the Ionic pages become a `LoadingIndicator` centred, or a
   lightweight shimmer-free placeholder.
10. **Design**: modern, airy, card-based. 16 px gutters, 16 px radius cards
    with the card shadow, ink-black primary buttons, eco green for CO2 /
    trees stats, status pills for order states. Keep every piece of
    information and every action the Ionic page had.

## Verification

From the project root with the SDK on PATH
(`export PATH="$HOME/development/flutter-stable/bin:$PATH"`):

```bash
dart run build_runner build --delete-conflicting-outputs   # after adding @riverpod code
flutter analyze lib/src/presentation/features/<feature>
```

Your feature must analyze with zero errors. Warnings from the custom
guardian rules are acceptable when unavoidable, but prefer to fix them.

## Localization

The Ionic app was English only. The Flutter app adds Arabic with full right-to-left layout:
gen-l10n ARB files under `lib/src/core/localization/`, `context.l10n` accessor, a persisted
locale (`localizationProvider`, `CacheKey.language`), `LanguageSheet` picker, locale-aware
`Formatters` (Western digits), and `localized_labels.dart` for enum display names. Server
`texts` copy applies only in English.
