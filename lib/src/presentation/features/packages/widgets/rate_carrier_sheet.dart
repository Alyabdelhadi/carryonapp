import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/base/result.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/order_actions_provider.dart';

/// Opens the star-rating sheet for the carrier of [orderId]. Resolves true
/// when a rating was submitted.
Future<bool> showRateCarrierSheet(
  BuildContext context, {
  required int carrierId,
  required int orderId,
}) async {
  final rated = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: RateCarrierSheet(carrierId: carrierId, orderId: orderId),
    ),
  );
  return rated ?? false;
}

class RateCarrierSheet extends ConsumerStatefulWidget {
  const RateCarrierSheet({
    super.key,
    required this.carrierId,
    required this.orderId,
  });

  final int carrierId;
  final int orderId;

  @override
  ConsumerState<RateCarrierSheet> createState() => _RateCarrierSheetState();
}

class _RateCarrierSheetState extends ConsumerState<RateCarrierSheet> {
  int _stars = 0;

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_stars == 0) {
      AppFeedback.toast(context, l10n.pkwSelectRatingFirst);
      return;
    }
    final result = await ref
        .read(rateCarrierProvider.notifier)
        .submit(
          carrierId: widget.carrierId,
          orderId: widget.orderId,
          rating: _stars.toDouble(),
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        AppFeedback.toast(context, l10n.pkwRatingSubmitted);
        Navigator.of(context).pop(true);
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(carrierProfileProvider(widget.carrierId));
    final busy = ref.watch(rateCarrierProvider).isLoading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.dimensions.space.s24,
          context.dimensions.space.s8,
          context.dimensions.space.s24,
          context.dimensions.space.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeadingLevel3Text(
              ref.texts.get('rating_title', l10n.pkwGiveRating),
            ),
            Gap(context.dimensions.space.s16),
            RateCarrierProfile(profile: profile),
            Gap(context.dimensions.space.s20),
            BodySmallText.muted(
              ref.texts.get('rating_des', l10n.pkwRatingHelps),
              textAlign: TextAlign.center,
            ),
            Gap(context.dimensions.space.s12),
            RateCarrierStars(
              value: _stars,
              onChanged: busy ? null : (v) => setState(() => _stars = v),
            ),
            Gap(context.dimensions.space.s24),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? SizedBox(
                      width: context.dimensions.size.iconMedium,
                      height: context.dimensions.size.iconMedium,
                      child: const CircularProgressIndicator(),
                    )
                  : Text(ref.texts.get('submit_btn', l10n.pkwSubmit)),
            ),
          ],
        ),
      ),
    );
  }
}

class RateCarrierProfile extends StatelessWidget {
  const RateCarrierProfile({super.key, required this.profile});

  final AsyncValue<AppUser> profile;

  @override
  Widget build(BuildContext context) {
    final avatarSize = context.dimensions.space.s80;
    return switch (profile) {
      AsyncData(:final value) => Column(
        children: [
          UserAvatar(
            initials: Formatters.initials(value.name),
            selfie: value.selfie,
            size: avatarSize,
          ),
          Gap(context.dimensions.space.s12),
          HeadingLevel3Text(value.name, textAlign: TextAlign.center),
          Gap(context.dimensions.space.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                size: context.dimensions.size.iconSmall,
                color: context.color.status.warning,
              ),
              Gap(context.dimensions.space.s4),
              BodySmallText.muted(
                context.l10n.pkwRatingScore(
                  Formatters.compact(
                    value.averageRating ?? 0,
                    fractionDigits: 1,
                  ),
                ),
              ),
              Gap(context.dimensions.space.s12),
              Icon(
                Icons.inventory_2_outlined,
                size: context.dimensions.size.iconSmall,
                color: context.color.text.muted,
              ),
              Gap(context.dimensions.space.s4),
              BodySmallText.muted(
                context.l10n.pkwPackagesDelivered(
                  value.carriedPackagesCount ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
      AsyncError() => BodySmallText.muted(
        context.l10n.pkwCarrierProfileUnavailable,
      ),
      _ => SizedBox(
        height: avatarSize,
        child: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class RateCarrierStars extends StatelessWidget {
  const RateCarrierStars({super.key, required this.value, this.onChanged});

  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            iconSize: context.dimensions.size.iconDisplay,
            color: star <= value
                ? context.color.status.warning
                : context.color.text.muted,
            icon: Icon(
              star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            ),
            onPressed: onChanged == null ? null : () => onChanged!(star),
          ),
      ],
    );
  }
}
