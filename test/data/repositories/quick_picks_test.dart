import 'package:carryon/src/core/base/result.dart';
import 'package:carryon/src/data/repositories/catalog_repository_impl.dart';
import 'package:carryon/src/data/services/network/rest_client.dart';
import 'package:carryon/src/domain/entities/entities.dart';
import 'package:carryon/src/domain/repositories/session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import '../../core/base/fake_crash_reporter.dart';

class _NoSession implements SessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late DioAdapter adapter;
  late CatalogRepositoryImpl repo;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local/api'));
    adapter = DioAdapter(dio: dio);
    repo = CatalogRepositoryImpl(
      remote: RestClient(dio),
      session: _NoSession(),
      crashReporter: FakeCrashReporter(),
    );
  });

  test(
    'weights split by where the admin shows them; tips keep 0 as Free',
    () async {
      adapter
        ..onGet(
          '/weights',
          (s) => s.reply(200, [
            {
              'value': '0.5',
              'kg': 0.5,
              'in_order_form': true,
              'in_calculator': true,
            },
            {
              'value': '3',
              'kg': 3,
              'in_order_form': false,
              'in_calculator': true,
            },
            {
              'value': '25',
              'kg': 25,
              'in_order_form': true,
              'in_calculator': false,
            },
          ]),
        )
        ..onGet(
          '/tips',
          (s) => s.reply(200, [
            {'value': '0', 'amount': 0, 'is_free': true},
            {'value': '15', 'amount': 15, 'is_free': false},
          ]),
        );

      final result = await repo.quickPicks();

      final picks = (result as Success<QuickPicks, dynamic>).data;
      expect(picks.orderWeightsKg, [0.5, 25]);
      expect(picks.calculatorWeightsKg, [0.5, 3]);
      expect(picks.rewards, [0, 15]);
    },
  );

  test('empty lists fall back to the shipped defaults', () async {
    adapter
      ..onGet('/weights', (s) => s.reply(200, <Object>[]))
      ..onGet('/tips', (s) => s.reply(200, <Object>[]));

    final result = await repo.quickPicks();

    final picks = (result as Success<QuickPicks, dynamic>).data;
    expect(picks.orderWeightsKg, QuickPicks.defaults.orderWeightsKg);
    expect(picks.calculatorWeightsKg, QuickPicks.defaults.calculatorWeightsKg);
    expect(picks.rewards, QuickPicks.defaults.rewards);
  });

  test('chip labels', () {
    expect(QuickPicks.format(0.5), '0.5');
    expect(QuickPicks.format(2), '2');
    expect(QuickPicks.format(12.25), '12.25');
    expect(QuickPicks.format(100), '100');
  });
}
