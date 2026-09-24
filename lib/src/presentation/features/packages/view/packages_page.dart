import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/login_required_view.dart';
import '../riverpod/package_lists_provider.dart';
import '../widgets/package_list_segment.dart';

enum _PackagesSegment { created, carried }

/// The Packages tab (Ionic `parcel`): "My Packages" and "Carried Packages".
class PackagesPage extends ConsumerStatefulWidget {
  const PackagesPage({super.key});

  @override
  ConsumerState<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends ConsumerState<PackagesPage> {
  _PackagesSegment _segment = .created;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.packages)),
      body: LoginRequired(
        child: _PackagesBody(
          segment: _segment,
          onSegmentChanged: (s) => setState(() => _segment = s),
        ),
      ),
    );
  }
}

class _PackagesBody extends ConsumerWidget {
  const _PackagesBody({required this.segment, required this.onSegmentChanged});

  final _PackagesSegment segment;
  final ValueChanged<_PackagesSegment> onSegmentChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.dimensions.space.s16,
            context.dimensions.space.s8,
            context.dimensions.space.s16,
            context.dimensions.space.s8,
          ),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_PackagesSegment>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _PackagesSegment.created,
                  label: Text(context.l10n.pkgMyPackages),
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
                ButtonSegment(
                  value: _PackagesSegment.carried,
                  label: Text(context.l10n.pkgCarriedPackages),
                  icon: const Icon(Icons.flight_takeoff_outlined),
                ),
              ],
              selected: {segment},
              onSelectionChanged: (s) => onSegmentChanged(s.first),
            ),
          ),
        ),
        Gap(context.dimensions.space.s4),
        Expanded(
          child: switch (segment) {
            .created => PackageListSegment(
              provider: myCreatedOrdersProvider(userId),
              emptyTitle: context.l10n.pkgCreatedEmptyTitle,
              emptyMessage: context.l10n.pkgCreatedEmptyMessage(
                context.l10n.appTitle,
              ),
            ),
            .carried => PackageListSegment(
              provider: myCarriedOrdersProvider(userId),
              emptyTitle: context.l10n.pkgCarriedEmptyTitle,
              emptyMessage: context.l10n.pkgAddTripMatchMessage,
              emptyActionLabel: context.l10n.pkgAddNewTrip,
              onEmptyAction: () => context.pushNamed(Routes.tripForm.name),
            ),
          },
        ),
      ],
    );
  }
}
