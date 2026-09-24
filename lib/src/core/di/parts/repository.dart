part of '../dependency_injection.dart';

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  return SessionRepositoryImpl(ref.watch(cacheServiceProvider));
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(restClientServiceProvider),
    session: ref.watch(sessionRepositoryProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) {
  return CatalogRepositoryImpl(
    remote: ref.watch(restClientServiceProvider),
    session: ref.watch(sessionRepositoryProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
ParcelOrderRepository parcelOrderRepository(Ref ref) {
  return ParcelOrderRepositoryImpl(
    remote: ref.watch(restClientServiceProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) {
  return WalletRepositoryImpl(
    remote: ref.watch(restClientServiceProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
TripRepository tripRepository(Ref ref) {
  return TripRepositoryImpl(
    remote: ref.watch(restClientServiceProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
AddressRepository addressRepository(Ref ref) {
  return AddressRepositoryImpl(
    remote: ref.watch(restClientServiceProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) {
  return LocationRepositoryImpl(
    remote: ref.watch(restClientServiceProvider),
    local: ref.watch(cacheServiceProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(
    firebaseReady: ref.watch(firebaseReadyProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
IdentityVerificationRepository identityVerificationRepository(Ref ref) {
  return IdentityVerificationRepositoryImpl(
    remote: ref.watch(restClientServiceProvider),
    crashReporter: ref.watch(crashReporterProvider),
  );
}

@Riverpod(keepAlive: true)
RouterRepository routerRepository(Ref ref) {
  return RouterRepositoryImpl(session: ref.watch(sessionRepositoryProvider));
}

@Riverpod(keepAlive: true)
LocaleRepository localeRepository(Ref ref) {
  return LocaleRepositoryImpl(ref.watch(cacheServiceProvider));
}
