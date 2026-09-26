part of '../dependency_injection.dart';

// ------------------------------------------------------------------ auth

@riverpod
LoginUseCase loginUseCase(Ref ref) {
  return LoginUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
}

@riverpod
SignupUseCase signupUseCase(Ref ref) {
  return SignupUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
}

@riverpod
VerifyIdentityUseCase verifyIdentityUseCase(Ref ref) {
  return VerifyIdentityUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
ResolveIdentityGateUseCase resolveIdentityGateUseCase(Ref ref) {
  return ResolveIdentityGateUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
}

@riverpod
FetchUserUseCase fetchUserUseCase(Ref ref) {
  return FetchUserUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
UpdateProfileUseCase updateProfileUseCase(Ref ref) {
  return UpdateProfileUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
DeleteAccountUseCase deleteAccountUseCase(Ref ref) {
  return DeleteAccountUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  );
}

@riverpod
PasswordResetUseCase passwordResetUseCase(Ref ref) {
  return PasswordResetUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
LogoutUseCase logoutUseCase(Ref ref) {
  return LogoutUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
}

@riverpod
RateOrderUseCase rateOrderUseCase(Ref ref) {
  return RateOrderUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
GetSessionUseCase getSessionUseCase(Ref ref) {
  return GetSessionUseCase(ref.watch(sessionRepositoryProvider));
}

// --------------------------------------------------------------- catalog

@riverpod
GetServicesUseCase getServicesUseCase(Ref ref) {
  return GetServicesUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
GetParcelCategoriesUseCase getParcelCategoriesUseCase(Ref ref) {
  return GetParcelCategoriesUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
GetSlidersUseCase getSlidersUseCase(Ref ref) {
  return GetSlidersUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
GetAppTextsUseCase getAppTextsUseCase(Ref ref) {
  return GetAppTextsUseCase(
    ref.watch(catalogRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
}

@riverpod
GetHomeStatsUseCase getHomeStatsUseCase(Ref ref) {
  return GetHomeStatsUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
GetAppVersionUseCase getAppVersionUseCase(Ref ref) {
  return GetAppVersionUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
GetCountriesUseCase getCountriesUseCase(Ref ref) {
  return GetCountriesUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
GetCitiesUseCase getCitiesUseCase(Ref ref) {
  return GetCitiesUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
GetPaymentMethodsUseCase getPaymentMethodsUseCase(Ref ref) {
  return GetPaymentMethodsUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
CheckAppUpdateUseCase checkAppUpdateUseCase(Ref ref) {
  return CheckAppUpdateUseCase(ref.watch(catalogRepositoryProvider));
}

// --------------------------------------------------------- parcel orders

@riverpod
SaveParcelOrderUseCase saveParcelOrderUseCase(Ref ref) {
  return SaveParcelOrderUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
GetMyCreatedOrdersUseCase getMyCreatedOrdersUseCase(Ref ref) {
  return GetMyCreatedOrdersUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
GetMyCarriedOrdersUseCase getMyCarriedOrdersUseCase(Ref ref) {
  return GetMyCarriedOrdersUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
GetMatchingOrdersUseCase getMatchingOrdersUseCase(Ref ref) {
  return GetMatchingOrdersUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
MarkMatchingOrderReadUseCase markMatchingOrderReadUseCase(Ref ref) {
  return MarkMatchingOrderReadUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
TransitionParcelOrderUseCase transitionParcelOrderUseCase(Ref ref) {
  return TransitionParcelOrderUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
ExtendParcelOrderUseCase extendParcelOrderUseCase(Ref ref) {
  return ExtendParcelOrderUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
GetQuickPicksUseCase getQuickPicksUseCase(Ref ref) {
  return GetQuickPicksUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
GetAppSettingsUseCase getAppSettingsUseCase(Ref ref) {
  return GetAppSettingsUseCase(ref.watch(catalogRepositoryProvider));
}

@riverpod
FetchParcelOrderUseCase fetchParcelOrderUseCase(Ref ref) {
  return FetchParcelOrderUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
StartOrderPaymentUseCase startOrderPaymentUseCase(Ref ref) {
  return StartOrderPaymentUseCase(ref.watch(parcelOrderRepositoryProvider));
}

@riverpod
SyncOrderPaymentUseCase syncOrderPaymentUseCase(Ref ref) {
  return SyncOrderPaymentUseCase(ref.watch(parcelOrderRepositoryProvider));
}

// ---------------------------------------------------------------- wallet

@riverpod
GetWalletOverviewUseCase getWalletOverviewUseCase(Ref ref) {
  return GetWalletOverviewUseCase(ref.watch(walletRepositoryProvider));
}

@riverpod
GetPayoutsUseCase getPayoutsUseCase(Ref ref) {
  return GetPayoutsUseCase(ref.watch(walletRepositoryProvider));
}

@riverpod
RequestPayoutUseCase requestPayoutUseCase(Ref ref) {
  return RequestPayoutUseCase(ref.watch(walletRepositoryProvider));
}

@riverpod
CancelPayoutUseCase cancelPayoutUseCase(Ref ref) {
  return CancelPayoutUseCase(ref.watch(walletRepositoryProvider));
}

// ----------------------------------------------------------------- trips

@riverpod
GetMyTripsUseCase getMyTripsUseCase(Ref ref) {
  return GetMyTripsUseCase(ref.watch(tripRepositoryProvider));
}

@riverpod
SaveTripUseCase saveTripUseCase(Ref ref) {
  return SaveTripUseCase(ref.watch(tripRepositoryProvider));
}

@riverpod
DeleteTripUseCase deleteTripUseCase(Ref ref) {
  return DeleteTripUseCase(ref.watch(tripRepositoryProvider));
}

// ------------------------------------------------------------- addresses

@riverpod
GetAddressesUseCase getAddressesUseCase(Ref ref) {
  return GetAddressesUseCase(ref.watch(addressRepositoryProvider));
}

@riverpod
SaveAddressUseCase saveAddressUseCase(Ref ref) {
  return SaveAddressUseCase(ref.watch(addressRepositoryProvider));
}

@riverpod
DeleteAddressUseCase deleteAddressUseCase(Ref ref) {
  return DeleteAddressUseCase(ref.watch(addressRepositoryProvider));
}

// -------------------------------------------------------------- location

@riverpod
GetCurrentPositionUseCase getCurrentPositionUseCase(Ref ref) {
  return GetCurrentPositionUseCase(ref.watch(locationRepositoryProvider));
}

@riverpod
GetCurrentPlaceUseCase getCurrentPlaceUseCase(Ref ref) {
  return GetCurrentPlaceUseCase(ref.watch(locationRepositoryProvider));
}

@riverpod
ReverseGeocodeUseCase reverseGeocodeUseCase(Ref ref) {
  return ReverseGeocodeUseCase(ref.watch(locationRepositoryProvider));
}

@riverpod
SearchPlacesUseCase searchPlacesUseCase(Ref ref) {
  return SearchPlacesUseCase(ref.watch(locationRepositoryProvider));
}

// --------------------------------------------------------- notifications

@riverpod
SetupPushUseCase setupPushUseCase(Ref ref) {
  return SetupPushUseCase(
    ref.watch(notificationRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
}

@riverpod
SetNotificationsEnabledUseCase setNotificationsEnabledUseCase(Ref ref) {
  return SetNotificationsEnabledUseCase(
    ref.watch(notificationRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
}

// ------------------------------------------------------- locale & router

@riverpod
GetCurrentLocaleUseCase getCurrentLocaleUseCase(Ref ref) {
  return GetCurrentLocaleUseCase(ref.watch(localeRepositoryProvider));
}

@riverpod
SetCurrentLocaleUseCase setCurrentLocaleUseCase(Ref ref) {
  return SetCurrentLocaleUseCase(ref.watch(localeRepositoryProvider));
}

@riverpod
ResetRepositoryUseCase resetRepositoryUseCase(Ref ref) {
  return const ResetRepositoryUseCase();
}

@riverpod
GetSessionStatusUseCase getSessionStatusUseCase(Ref ref) {
  return GetSessionStatusUseCase(ref.watch(routerRepositoryProvider));
}
