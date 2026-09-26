import 'package:carryon/src/data/mappers/json_mappers.dart';
import 'package:carryon/src/data/services/network/exceptions.dart';
import 'package:carryon/src/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appSettings reads the payments block with defaults', () {
    final settings = CatalogMapper.appSettings({
      'shufti_enabled': true,
      'payments': {
        'online_payment_enabled': false,
        'currency': 'usd',
        'commission_percent': 15,
        'payout_minimum': 20,
        'payout_hold_days': 3,
        'payment_deadline_hours': 24,
        'payout_methods': [
          {'code': 'omt', 'name': 'OMT'},
          {'code': 'bank_transfer'},
        ],
      },
    });
    final p = settings.payments;
    expect(p.onlinePaymentEnabled, isFalse);
    expect(p.currency, 'USD');
    expect(p.commissionPercent, 15);
    expect(p.payoutMethods.map((m) => m.code), ['omt', 'bank_transfer']);
    expect(p.payoutMethods.last.name, 'bank_transfer');

    expect(CatalogMapper.appSettings({}).payments.commissionPercent, 15);
  });

  test('appSettings reads the live verification switch', () {
    expect(CatalogMapper.appSettings({}).shuftiLive, isFalse);
    expect(CatalogMapper.appSettings({'shufti_live': true}).shuftiLive, isTrue);
  });

  test('identity_live_required becomes a liveRequired identity failure', () {
    expect(
      () => Json.requireDone({
        'msg': 'error',
        'reason': 'identity_live_required',
        'error': 'Please update CarryOn.',
      }),
      throwsA(
        isA<IdentityRejectedException>().having(
          (e) => e.kind,
          'kind',
          IdentityVerificationFailureKind.liveRequired,
        ),
      ),
    );
  });

  test('parcel order reads the wallet columns', () {
    final order = ParcelOrderMapper.fromJson({
      'id': 1196,
      'user_id': 3598,
      'status': 'Assigned',
      'payment_method': 'stripe',
      'payment_status': 'unpaid',
      'payment_amount': '45.00',
      'payment_currency': 'USD',
      'commission_amount': '6.75',
      'carrier_earning': '38.25',
      'payment_deadline_at': '2026-09-25T11:54:00.000000Z',
      's_country': 'Lebanon',
      'r_country': 'United Arab Emirates',
    });
    expect(order.carrierEarning, 38.25);
    expect(order.commissionAmount, 6.75);
    expect(order.paymentDeadlineAt, isNotNull);
    expect(order.canPayNow, isTrue);
  });

  test('stripePaymentIntent maps the create response', () {
    final intent = CatalogMapper.stripePaymentIntent({
      'message': 'done',
      'client_secret': 'pi_1_secret_2',
      'payment_intent_id': 'pi_1',
      'publishable_key': 'pk_test_x',
      'payment_amount': '45.00',
      'payment_currency': 'usd',
    });
    expect(intent.clientSecret, 'pi_1_secret_2');
    expect(intent.amount, 45);
    expect(intent.currency, 'USD');
  });
}
