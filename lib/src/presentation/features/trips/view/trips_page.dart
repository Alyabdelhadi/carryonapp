import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/failure_view.dart';
import '../../../core/widgets/login_required_view.dart';
import '../riverpod/my_trips_provider.dart';
import '../widgets/trip_card.dart';

/// The "Trips" tab (Ionic `my`): the carrier's declared routes, split into
/// upcoming and past, with the "Add New Trip" footer action.
class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tripMyTripsTitle)),
      body: const LoginRequired(child: _SignedInTrips()),
    );
  }
}

enum _Segment { upcoming, past }

class _SignedInTrips extends ConsumerStatefulWidget {
  const _SignedInTrips();

  @override
  ConsumerState<_SignedInTrips> createState() => _SignedInTripsState();
}

class _SignedInTripsState extends ConsumerState<_SignedInTrips> {
  _Segment _segment = .upcoming;

  Future<void> _openForm({Trip? trip}) async {
    await context.pushNamed<bool>(Routes.tripForm.name, extra: trip);
    if (!mounted) return;
    // The Ionic page reloads on every `ionViewWillEnter`.
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) ref.invalidate(myTripsProvider(userId));
  }

  Future<void> _refresh(int userId) async {
    ref.invalidate(myTripsProvider(userId));
    try {
      await ref.read(myTripsProvider(userId).future);
    } on Object {
      // The failure is rendered by the body; the indicator only waits.
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final trips = ref.watch(myTripsProvider(userId));

    return Column(
      children: [
        Expanded(
          child: switch (trips) {
            AsyncValue(hasValue: true, value: final all?) => _TripsBody(
              trips: all,
              segment: _segment,
              onSegmentChanged: (s) => setState(() => _segment = s),
              onRefresh: () => _refresh(userId),
              onOpen: (trip) => _openForm(trip: trip),
              onAdd: _openForm,
            ),
            AsyncError(:final error) => FailureView(
              error: error,
              onRetry: () => ref.invalidate(myTripsProvider(userId)),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
        _AddTripFooter(onPressed: _openForm),
      ],
    );
  }
}

class _TripsBody extends StatelessWidget {
  const _TripsBody({
    required this.trips,
    required this.segment,
    required this.onSegmentChanged,
    required this.onRefresh,
    required this.onOpen,
    required this.onAdd,
  });

  final List<Trip> trips;
  final _Segment segment;
  final ValueChanged<_Segment> onSegmentChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<Trip> onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: context.dimensions.space.s80),
          children: [
            EmptyState(
              icon: Icons.flight_takeoff_rounded,
              title: l10n.tripEmptyTitle,
              message: l10n.tripEmptyMessage,
              actionLabel: l10n.tripAddNew,
              onAction: onAdd,
            ),
          ],
        ),
      );
    }

    final visible = trips
        .where(
          (t) => switch (segment) {
            .upcoming => t.isUpcoming,
            .past => !t.isUpcoming,
          },
        )
        .toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.dimensions.space.s16,
            context.dimensions.space.s4,
            context.dimensions.space.s16,
            context.dimensions.space.s12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_Segment>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor: context.color.background.surface,
                foregroundColor: context.color.text.muted,
                selectedBackgroundColor: context.color.primary.tint,
                selectedForegroundColor: context.color.primary.strong,
                side: BorderSide(
                  color: context.color.border.defaultValue,
                  width: context.dimensions.border.xs,
                ),
              ),
              segments: [
                ButtonSegment(
                  value: _Segment.upcoming,
                  label: Text(l10n.tripSegmentUpcoming),
                ),
                ButtonSegment(
                  value: _Segment.past,
                  label: Text(l10n.tripSegmentPast),
                ),
              ],
              selected: {segment},
              onSelectionChanged: (s) => onSegmentChanged(s.first),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: visible.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: context.dimensions.space.s32),
                    children: [
                      EmptyState(
                        icon: segment == .upcoming
                            ? Icons.event_available_rounded
                            : Icons.history_rounded,
                        title: segment == .upcoming
                            ? l10n.tripNoUpcomingTitle
                            : l10n.tripNoPastTitle,
                        message: segment == .upcoming
                            ? l10n.tripNoUpcomingMessage
                            : l10n.tripNoPastMessage,
                        actionLabel: segment == .upcoming
                            ? l10n.tripAddNew
                            : null,
                        onAction: segment == .upcoming ? onAdd : null,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.dimensions.space.s16,
                      context.dimensions.space.s4,
                      context.dimensions.space.s16,
                      context.dimensions.space.s24 +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        Gap(context.dimensions.space.s12),
                    itemBuilder: (context, index) {
                      final trip = visible[index];
                      return TripCard(trip: trip, onTap: () => onOpen(trip));
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// The Ionic footer: a full-width ink-black "Add New Trip" button.
class _AddTripFooter extends StatelessWidget {
  const _AddTripFooter({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.color.background.surface,
        boxShadow: context.dimensions.elevation.navigation,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.dimensions.space.s16,
            context.dimensions.space.s12,
            context.dimensions.space.s16,
            context.dimensions.space.s12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.tripAddNew),
            ),
          ),
        ),
      ),
    );
  }
}
