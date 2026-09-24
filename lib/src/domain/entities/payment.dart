/// What `POST /payments/stripe/create` returns: everything the Stripe
/// payment sheet needs for one order.
class StripePaymentIntent {
  const StripePaymentIntent({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.publishableKey,
    required this.amount,
    required this.currency,
  });

  final String clientSecret;
  final String paymentIntentId;
  final String publishableKey;
  final double amount;
  final String currency;
}
