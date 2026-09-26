// Token session against a local backend with API_LEGACY_USER_ID_AUTH off:
// login through the UI, the signed-in tabs work with the access token,
// and a stolen refresh token (used by someone else first) signs the app
// out on its next refresh. Prints `E2E:` markers for screenshots.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/auth_session_test.dart -d <udid> \
//     --dart-define=CARRYON_API_BASE=http://127.0.0.1:8000/api \
//     --dart-define=CARRYON_DISABLE_PUSH=true \
//     --dart-define=CARRYON_EMAIL=<account> --dart-define=CARRYON_PASSWORD=<pw>
import 'dart:convert';
import 'dart:io';

import 'package:carryon/main.dart' as app;
import 'package:carryon/src/core/di/dependency_injection.dart';
import 'package:carryon/src/data/services/network/endpoints.dart';
import 'package:carryon/src/presentation/core/application_state/logout_provider/logout_provider.dart';
import 'package:carryon/src/presentation/core/widgets/glass_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('CARRYON_EMAIL');
const _password = String.fromEnvironment('CARRYON_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('token session: login, use, theft -> signed out', (tester) async {
    await app.main();
    await tester.pump();
    await _pumpUntilAny(tester, [_navLabel('Login'), _navLabel('Account')]);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GlassNavigationBar)),
    );

    // start signed out
    if (_navLabel('Account').evaluate().isNotEmpty) {
      await container.read(logoutProvider.notifier).call();
      await _pumpUntil(tester, _navLabel('Login'));
    }

    await tester.tap(_navLabel('Login'));
    await _pumpUntil(tester, _fieldWithHint('Email'));
    await tester.enterText(_fieldWithHint('Email'), _email);
    await tester.enterText(_fieldWithHint('Password'), _password);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await _pumpUntil(tester, _navLabel('Account'), timeout: 40);
    _mark('signed-in');

    final tokens = container.read(tokenManagerProvider);
    final access = await tokens.accessToken;
    final refresh = await tokens.refreshToken;
    expect(access, isNotNull);
    expect(refresh, isNotNull);
    final who = await _call('GET', '/auth/whoami', bearer: access);
    expect(who.$1, 200);
    _mark('token-valid user=${who.$2['user_id']}');

    for (final tab in ['Packages', 'Trips', 'Account']) {
      await tester.tap(_navLabel(tab));
      await _settle(tester, 4);
      expect(find.textContaining('Unauthenticated'), findsNothing);
      expect(find.textContaining('Please login'), findsNothing);
      _mark('tab-${tab.toLowerCase()}');
    }

    // someone else uses the refresh token first
    final stolen = await _call(
      'POST',
      '/auth/refresh',
      body: {'refreshToken': refresh},
    );
    expect(stolen.$1, 200);
    _mark('refresh-token-stolen');

    // the app's access token died with that rotation; its next API call
    // (here: refreshing the profile) gets a 401, refreshes with the
    // now-used token -> the server revokes the whole session
    final userId = who.$2['user_id'] as int;
    final result = await container.read(fetchUserUseCaseProvider).call(userId);
    _mark('next-call-after-theft ${result.runtimeType}');
    await _pumpUntil(tester, _navLabel('Login'), timeout: 30);
    _mark('signed-out-after-theft');
    expect(await tokens.refreshToken, isNull);

    // and the thief's fresh pair is dead too
    final thief = await _call(
      'GET',
      '/auth/whoami',
      bearer: stolen.$2['accessToken'] as String?,
    );
    expect(thief.$1, 401);
    _mark('thief-token-revoked');
    await _settle(tester, 3);
  });
}

Future<(int, Map<String, dynamic>)> _call(
  String method,
  String path, {
  Map<String, Object?>? body,
  String? bearer,
}) async {
  final client = HttpClient();
  final request = await client.openUrl(
    method,
    Uri.parse('${Endpoints.base}$path'),
  );
  request.headers.set('Accept', 'application/json');
  if (bearer != null) request.headers.set('Authorization', 'Bearer $bearer');
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
  }
  final response = await request.close();
  final text = await response.transform(utf8.decoder).join();
  client.close();
  final decoded = text.isEmpty ? null : jsonDecode(text);
  return (
    response.statusCode,
    decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
  );
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(GlassNavigationBar),
  matching: find.text(label),
);

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

void _mark(String step) => debugPrint('E2E: $step');

Future<void> _settle(WidgetTester tester, int seconds) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int timeout = 40,
}) => _pumpUntilAny(tester, [finder], timeout: timeout);

Future<void> _pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  int timeout = 40,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: timeout));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finders.any((f) => f.evaluate().isNotEmpty)) return;
  }
  throw TestFailure('Timed out waiting for any of $finders');
}
