import '../../../core/gen/l10n/app_localizations.dart';
import '../../../domain/entities/entities.dart';

/// Localized display names for domain enums, which carry wire values only.
extension ParcelOrderStatusLabel on ParcelOrderStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ParcelOrderStatus.unassigned => l10n.statusUnassigned,
    ParcelOrderStatus.assigned => l10n.statusAssigned,
    ParcelOrderStatus.picked => l10n.statusPicked,
    ParcelOrderStatus.transit => l10n.statusTransit,
    ParcelOrderStatus.delivered => l10n.statusDelivered,
    ParcelOrderStatus.cancelled => l10n.statusCancelled,
    ParcelOrderStatus.expired => l10n.statusExpired,
    ParcelOrderStatus.unknown => l10n.statusUnknown,
  };
}

extension TripFrequencyLabel on TripFrequency {
  String label(AppLocalizations l10n) => switch (this) {
    TripFrequency.oneTime => l10n.tripFrequencyOneTime,
    TripFrequency.daily => l10n.tripFrequencyDaily,
    TripFrequency.weekdays => l10n.tripFrequencyWeekdays,
    TripFrequency.weekends => l10n.tripFrequencyWeekends,
  };
}
