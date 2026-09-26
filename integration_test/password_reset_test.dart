// Forgot password against a local backend whose mailer writes to the
// Laravel log (.env.local MAIL_MAILER=log): the test reads the emailed
// code from that log, as a user would read their inbox. Prints `E2E:`
// markers for screenshots.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/password_reset_test.dart -d <udid> \
//     --dart-define=CARRYON_API_BASE=http://127.0.0.1:8000/api \
//     --dart-define=CARRYON_DISABLE_PUSH=true \
//     --dart-define=CARRYON_EMAIL=<account> \
//     --dart-define=CARRYON_MAIL_LOG=<backend>/storage/logs/laravel.log
import 'dart:convert';
import 'dart:io';

import 'package:carryon/main.dart' as app;
import 'package:carryon/src/data/services/network/endpoints.dart';
import 'package:carryon/src/presentation/core/router/router.dart';
import 'package:carryon/src/presentation/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('CARRYON_EMAIL');
const _mailLog = String.fromEnvironment('CARRYON_MAIL_LOG');
const _newPassword = String.fromEnvironment(
  'CARRYON_NEW_PASSWORD',
  defaultValue: 'newpass123',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('forgot password by emailed code', (tester) async {
    await app.main();
    await tester.pump();
    await _pumpUntil(tester, find.byType(Scaffold), timeout: 30);
    await _settle(tester, 4);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    // ignore: unawaited_futures
    container.read(goRouterProvider).pushNamed(Routes.forgotPassword.name);
    await _pumpUntil(tester, find.text('Send code'));
    _mark('email-step');

    final logOffset = File(_mailLog).lengthSync();
    await tester.enterText(_field('email'), _email);
    await tester.tap(find.text('Send code'));
    await _pumpUntil(tester, find.text('Check your email'));
    await _settle(tester, 2); // let the step cross-fade finish
    _mark('code-step');
    final code = await _codeFromLog(logOffset);

    // a wrong code first
    final wrong = code == '000000' ? '111111' : '000000';
    await tester.enterText(_field('code'), wrong);
    await _pumpUntil(tester, find.textContaining('code is incorrect'));
    _mark('wrong-code');
    await _settle(tester, 3);

    await tester.tap(_field('code'));
    await tester.pump();
    await tester.enterText(_field('code'), code);
    await _settle(tester, 2);
    if (find.text('Set a new password').evaluate().isEmpty) {
      await tester.tap(find.text('Verify code'));
    }
    await _pumpUntil(tester, find.text('Set a new password'));
    await _settle(tester, 2);
    _mark('password-step');

    await tester.enterText(_field('password', 0), _newPassword);
    await tester.enterText(_field('password', 1), _newPassword);
    await tester.tap(find.text('Save password'));
    await _pumpUntil(tester, find.textContaining('Password changed'));
    _mark('changed');
    await _settle(tester, 3);

    final login = await _post('/login', {
      'email': _email,
      'password': _newPassword,
    });
    expect(login['msg'], 'done');
    _mark('login-with-new-password-ok');
  });
}

/// The newest 6-digit code written to the mail log after [offset].
Future<String> _codeFromLog(int offset) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  final pattern = RegExp(r'reset code is: (\d{6})');
  while (DateTime.now().isBefore(deadline)) {
    final file = File(_mailLog);
    final raf = file.openSync()..setPositionSync(offset);
    final added = utf8.decode(
      raf.readSync(file.lengthSync() - offset),
      allowMalformed: true,
    );
    raf.closeSync();
    final matches = pattern.allMatches(added).toList();
    if (matches.isNotEmpty) return matches.last.group(1)!;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw TestFailure('No reset code in $_mailLog');
}

Future<Map<String, dynamic>> _post(
  String path,
  Map<String, String> body,
) async {
  final client = HttpClient();
  final request = await client.postUrl(Uri.parse('${Endpoints.base}$path'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));
  final response = await request.close();
  final text = await response.transform(utf8.decoder).join();
  client.close();
  return jsonDecode(text) as Map<String, dynamic>;
}

/// The [index]th text field of the step keyed [step] on the page.
Finder _field(String step, [int index = 0]) => find
    .descendant(
      of: find.byKey(ValueKey(step)),
      matching: find.byType(TextFormField),
    )
    .at(index);

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
}) async {
  final deadline = DateTime.now().add(Duration(seconds: timeout));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}
