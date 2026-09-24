import '../../../domain/entities/entities.dart';

/// Typed `extra` payloads for routes that carry an object. Pass them with
/// `context.pushNamed(Routes.x.name, extra: args)` and read them in the
/// route builder; a missing or mistyped extra falls back to the route's
/// empty state instead of crashing.

/// `/order-form`: create in [flow], or edit [order].
class OrderFormArgs {
  const OrderFormArgs({required this.flow, this.order});

  final ParcelFlow flow;
  final ParcelOrder? order;

  bool get isEdit => order != null;
}

/// `/address-picker`: which side is being captured and the value to edit.
/// The picker pops with an [OrderAddress] result.
class AddressPickerArgs {
  const AddressPickerArgs({
    required this.title,
    this.initial,
    this.isSenderSide = true,
  });

  final String title;
  final OrderAddress? initial;
  final bool isSenderSide;
}

/// `/carbon-calculator`: optional pre-filled route.
class CarbonCalculatorArgs {
  const CarbonCalculatorArgs({this.fromCity, this.toCity, this.weightKg});

  final String? fromCity;
  final String? toCity;
  final double? weightKg;
}
