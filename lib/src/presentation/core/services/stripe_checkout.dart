import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logger/log.dart';
import '../../../domain/entities/entities.dart';

/// How the Stripe payment sheet ended.
sealed class StripeCheckoutOutcome {
  const StripeCheckoutOutcome();
}

/// The card was charged (Stripe confirmed the intent on-device).
final class StripeCheckoutSucceeded extends StripeCheckoutOutcome {
  const StripeCheckoutSucceeded();
}

/// The user closed the sheet.
final class StripeCheckoutCancelled extends StripeCheckoutOutcome {
  const StripeCheckoutCancelled();
}

/// Stripe refused the payment or the sheet failed to open.
final class StripeCheckoutFailed extends StripeCheckoutOutcome {
  const StripeCheckoutFailed(this.message);

  final String? message;
}

/// Thin wrapper over the Stripe payment sheet. The publishable key comes
/// with every PaymentIntent from the backend, so nothing is compiled in.
class StripeCheckout {
  String? _configuredKey;

  Future<StripeCheckoutOutcome> pay(
    StripePaymentIntent intent, {
    ThemeMode style = ThemeMode.light,
  }) async {
    try {
      if (_configuredKey != intent.publishableKey) {
        Stripe.publishableKey = intent.publishableKey;
        await Stripe.instance.applySettings();
        _configuredKey = intent.publishableKey;
      }
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: AppConfig.appName,
          style: style,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return const StripeCheckoutSucceeded();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return const StripeCheckoutCancelled();
      }
      Log.warning('Stripe sheet failed: ${e.error.message}');
      return StripeCheckoutFailed(e.error.localizedMessage ?? e.error.message);
    } on Object catch (e) {
      Log.warning('Stripe sheet error: $e');
      return const StripeCheckoutFailed(null);
    }
  }
}

final stripeCheckoutProvider = Provider<StripeCheckout>((ref) {
  return StripeCheckout();
});
