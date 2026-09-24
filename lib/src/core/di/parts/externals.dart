part of '../dependency_injection.dart';

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

/// The single sink for programmer bugs — the repository guards and the
/// global error handlers both report here. Override with a Crashlytics- or
/// Sentry-backed implementation to ship crash telemetry; the default logs.
@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) => const LoggingCrashReporter();

/// Whether `Firebase.initializeApp` succeeded at bootstrap. Overridden by
/// `bootstrap()`; false means push features fail softly.
@Riverpod(keepAlive: true)
bool firebaseReady(Ref ref) => false;

/// The single place to adapt the network stack. Every [DioBuilder]
/// argument below is a deliberate seam; change it here, never in
/// transport code. The CarryOn backend has no bearer tokens, so the token
/// store and refresh endpoint are inert: every endpoint is unmarked
/// (public) and identifies the user by a `user_id` parameter.
@Riverpod(keepAlive: true)
NetworkStack networkStack(Ref ref) {
  final logger = kDebugMode
      ? PrettyDioLogger(requestHeader: false, compact: true)
      : null;

  return DioBuilder(
    config: const NetworkConfig(
      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 40),
      sendTimeout: Duration(seconds: 60),
      defaultHeaders: {'Accept': 'application/json'},
    ),
    store: SecureTokenStore(),
    errorParser: const DefaultServerErrorParser(),
    refreshEndpoint: Endpoints.login,
    localeResolver: () => ref.read(localeRepositoryProvider).getLanguage(),
    extraInterceptors: const [],
    logger: logger,
  ).build();
}

@Riverpod(keepAlive: true)
TokenManager tokenManager(Ref ref) => ref.watch(networkStackProvider).tokens;
