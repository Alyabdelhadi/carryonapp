import 'package:carryon/src/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

ParcelOrder _order({
  required String method,
  String? paymentStatus,
  ParcelOrderStatus status = ParcelOrderStatus.assigned,
}) {
  const address = OrderAddress(
    name: 'Home',
    country: 'Lebanon',
    lat: 33.89,
    lng: 35.5,
  );
  return ParcelOrder(
    id: 1,
    userId: 10,
    carrierId: 20,
    status: status,
    sender: address,
    receiver: address,
    paymentMethod: method,
    paymentStatus: paymentStatus,
  );
}

void main() {
  group('OrderPaymentStatus.fromWire', () {
    test('maps every backend value', () {
      for (final status in OrderPaymentStatus.values) {
        expect(
          OrderPaymentStatus.fromWire(status.wire, online: true),
          status,
        );
      }
    });

    test('legacy "pending" and null fall back by payment method', () {
      expect(
        OrderPaymentStatus.fromWire('pending', online: true),
        OrderPaymentStatus.unpaid,
      );
      expect(
        OrderPaymentStatus.fromWire(null, online: false),
        OrderPaymentStatus.cash,
      );
    });
  });

  group('ParcelOrder payment getters', () {
    test('cash orders never await payment', () {
      final order = _order(method: 'cash_on_delivery', paymentStatus: 'cash');
      expect(order.isOnlinePayment, isFalse);
      expect(order.awaitingPayment, isFalse);
      expect(order.canPayNow, isFalse);
    });

    test('an accepted unpaid card order can be paid now', () {
      final order = _order(method: 'stripe', paymentStatus: 'unpaid');
      expect(order.isOnlinePayment, isTrue);
      expect(order.awaitingPayment, isTrue);
      expect(order.canPayNow, isTrue);
    });

    test('legacy numeric method id counts as card', () {
      final order = _order(method: '2', paymentStatus: 'failed');
      expect(order.isOnlinePayment, isTrue);
      expect(order.canPayNow, isTrue);
    });

    test('pay now only while assigned', () {
      final unassigned = _order(
        method: 'stripe',
        paymentStatus: 'unpaid',
        status: ParcelOrderStatus.unassigned,
      );
      expect(unassigned.awaitingPayment, isTrue);
      expect(unassigned.canPayNow, isFalse);
    });

    test('paid and refunded orders are settled', () {
      expect(_order(method: 'stripe', paymentStatus: 'paid').isPaid, isTrue);
      expect(
        _order(method: 'stripe', paymentStatus: 'paid').awaitingPayment,
        isFalse,
      );
      expect(
        _order(method: 'stripe', paymentStatus: 'refunded').awaitingPayment,
        isFalse,
      );
      expect(
        _order(
          method: 'stripe',
          paymentStatus: 'refund_pending',
        ).awaitingPayment,
        isFalse,
      );
    });
  });

  test('PaymentRules.carrierShare applies the commission', () {
    const rules = PaymentRules(commissionPercent: 15);
    expect(rules.carrierShare(100), 85);
    expect(rules.carrierShare(0), 0);
  });
}
