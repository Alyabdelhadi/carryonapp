import 'package:carryon/src/data/services/network/auth/token_manager.dart';
import 'package:carryon/src/data/services/network/auth/token_store.dart';
import 'package:carryon/src/data/services/network/request_auth.dart';
import 'package:carryon/src/data/services/network/transport/interceptors/auth_header_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import '../helpers.dart';

/// CarryOn's additions to the token template: expiry-aware refresh, the
/// session-expired hook, and "our API only" for the Authorization header.
void main() {
  late Dio dio;
  late DioAdapter adapter;
  late FakeTokenStore store;
  late TokenManager tokens;
  final sent = <RequestOptions>[];

  void setupWith(Map<TokenKey, String> initial) {
    sent.clear();
    dio = Dio(BaseOptions(baseUrl: '$testBaseUrl/api'));
    adapter = DioAdapter(dio: dio);
    store = FakeTokenStore(initial: initial);
    tokens = TokenManager(
      store: store,
      transport: dio,
      refreshEndpoint: testRefreshPath,
    );
    dio.interceptors
      ..add(AuthHeaderInterceptor(tokens, ownApiBaseUrl: '$testBaseUrl/api'))
      ..add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent.add(options);
            handler.next(options);
          },
        ),
      );
  }

  String expiresIn(Duration d) =>
      '${DateTime.now().add(d).millisecondsSinceEpoch}';

  test('persist stores the expiry and refresh keeps it current', () async {
    setupWith({});
    await tokens.persist(
      access: 'a1',
      refresh: 'r1',
      expiresIn: const Duration(hours: 1),
    );
    final stored = int.parse((await store.read(TokenKey.expiresAt))!);
    expect(
      DateTime.fromMillisecondsSinceEpoch(stored).difference(DateTime.now()),
      greaterThan(const Duration(minutes: 59)),
    );
  });

  test('an access token about to expire is refreshed before use', () async {
    setupWith({
      TokenKey.access: 'old',
      TokenKey.refresh: 'r1',
      TokenKey.expiresAt: expiresIn(const Duration(seconds: 20)),
    });
    adapter
      ..onPost(
        testRefreshPath,
        (s) => s.reply(200, {
          'accessToken': 'fresh',
          'refreshToken': 'r2',
          'expiresIn': 3600,
        }),
        data: {'refreshToken': 'r1'},
      )
      ..onGet('/wallet', (s) => s.reply(200, {'msg': 'done'}));

    await dio.get<dynamic>('/wallet');

    final wallet = sent.lastWhere((o) => o.path == '/wallet');
    expect(wallet.headers['Authorization'], 'Bearer fresh');
    expect(await tokens.refreshToken, 'r2');
    // the refresh call itself went out without a bearer token
    final refresh = sent.firstWhere((o) => o.path == testRefreshPath);
    expect(refresh.headers['Authorization'], isNull);
    expect(refresh.extra[requestAuthKey], RequestAuth.public);
  });

  test('a fresh token is used as is', () async {
    setupWith({
      TokenKey.access: 'a1',
      TokenKey.refresh: 'r1',
      TokenKey.expiresAt: expiresIn(const Duration(minutes: 30)),
    });
    adapter.onGet('/wallet', (s) => s.reply(200, {'msg': 'done'}));

    await dio.get<dynamic>('/wallet');

    expect(sent.single.headers['Authorization'], 'Bearer a1');
  });

  test('the token is never sent to another host', () async {
    setupWith({
      TokenKey.access: 'a1',
      TokenKey.refresh: 'r1',
      TokenKey.expiresAt: expiresIn(const Duration(minutes: 30)),
    });
    adapter.onGet(
      'https://maps.googleapis.com/maps/api/geocode/json',
      (s) => s.reply(200, {}),
    );

    await dio.get<dynamic>('https://maps.googleapis.com/maps/api/geocode/json');

    expect(sent.single.headers['Authorization'], isNull);
  });

  test('a rejected refresh token ends the session once', () async {
    setupWith({
      TokenKey.access: 'a1',
      TokenKey.refresh: 'r1',
      TokenKey.expiresAt: expiresIn(const Duration(seconds: 5)),
    });
    var expired = 0;
    tokens.onSessionExpired = () => expired++;
    adapter
      ..onPost(
        testRefreshPath,
        (s) => s.reply(401, {'reason': 'refresh_invalid'}),
        data: {'refreshToken': 'r1'},
      )
      ..onGet('/wallet', (s) => s.reply(401, {'reason': 'unauthenticated'}));

    await expectLater(
      dio.get<dynamic>('/wallet'),
      throwsA(isA<DioException>()),
    );

    expect(expired, 1);
    expect(await tokens.accessToken, isNull);
    expect(await tokens.refreshToken, isNull);
    expect(await store.read(TokenKey.expiresAt), isNull);
  });
}
