import 'package:carryon/src/data/mappers/json_mappers.dart';
import 'package:carryon/src/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overview maps the /wallet payload', () {
    final overview = WalletMapper.overview({
      'msg': 'done',
      'wallet': {
        'balance': 102,
        'available': 0,
        'pending': 102,
        'currency': 'USD',
      },
      'rules': {
        'online_payment_enabled': true,
        'currency': 'USD',
        'commission_percent': 15,
        'payout_minimum': 20,
        'payout_hold_days': 3,
        'payment_deadline_hours': 24,
        'payout_methods': [
          {'code': 'omt', 'name': 'OMT'},
        ],
      },
      'transactions': [
        {
          'id': 12,
          'type': 'earning',
          'amount': '102.00',
          'currency': 'USD',
          'parcel_order_id': 1183,
          'available_at': '2099-01-01T00:00:00.000000Z',
          'balance_after': '102.00',
          'note': 'Package #1183 delivered',
          'created_at': '2026-09-24T11:33:02.000000Z',
        },
        {
          'id': 13,
          'type': 'payout',
          'amount': '-50.00',
          'currency': 'USD',
          'payout_request_id': 4,
          'balance_after': '52.00',
        },
      ],
      'open_payout': {
        'id': 4,
        'amount': '50.00',
        'currency': 'USD',
        'method': 'omt',
        'details': {'phone': '70143335'},
        'status': 'pending',
      },
    });

    expect(overview.summary.pending, 102);
    expect(overview.rules.payoutMethods.single.name, 'OMT');
    expect(overview.transactions.first.type, WalletTransactionType.earning);
    expect(overview.transactions.first.isOnHold, isTrue);
    expect(overview.transactions.last.amount, -50);
    expect(overview.openPayout?.details['phone'], '70143335');
    expect(overview.openPayout?.isPending, isTrue);
    expect(overview.canRequestPayout, isFalse);
    expect(overview.hasActivity, isTrue);
  });

  test('canRequestPayout needs the minimum and no open request', () {
    const rules = PaymentRules(payoutMinimum: 20);
    expect(
      const WalletOverview(
        summary: WalletSummary(balance: 30, available: 30),
        rules: rules,
      ).canRequestPayout,
      isTrue,
    );
    expect(
      const WalletOverview(
        summary: WalletSummary(balance: 30, available: 10, pending: 20),
        rules: rules,
      ).canRequestPayout,
      isFalse,
    );
  });
}
