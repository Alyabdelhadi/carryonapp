import 'package:dio/dio.dart';

/// Request-extra key marking an endpoint that legitimately takes longer
/// than the default timeouts, e.g. signup, where the backend runs the
/// Shufti identity check (about 20 s) before answering:
///
/// ```dart
/// @Extra({slowRequestKey: true})
/// @POST('/signup')
/// ```
const slowRequestKey = 'timeout.slow';

/// Gives requests marked with [slowRequestKey] the long [timeout] for
/// sending and receiving; every other request keeps the defaults.
class SlowRequestInterceptor extends Interceptor {
  const SlowRequestInterceptor(this.timeout);

  final Duration timeout;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[slowRequestKey] == true) {
      options
        ..sendTimeout = timeout
        ..receiveTimeout = timeout;
    }
    handler.next(options);
  }
}
