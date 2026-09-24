import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../data/services/network/endpoints.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/localization_provider/localization_provider.dart';
import '../../../core/application_state/app_settings_provider/app_settings_provider.dart';
import '../../../core/application_state/logout_provider/logout_provider.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/failure_view.dart';
import '../../../core/widgets/language_sheet.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/stat_icon.dart';
import '../riverpod/account_providers.dart';
import '../riverpod/wallet_providers.dart';
import '../widgets/account_header.dart';
import '../widgets/app_version_line.dart';
import '../widgets/menu_row.dart';
import '../widgets/notifications_toggle_row.dart';
import '../widgets/stat_tile.dart';

/// The account tab: fresh profile stats, the settings menu, logout and
/// account deletion. The tab gate only renders this while signed in.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const Scaffold(body: LoginRequired(child: SizedBox.shrink()));
    }
    return _AccountBody(userId: userId);
  }
}

class _AccountBody extends ConsumerStatefulWidget {
  const _AccountBody({required this.userId});

  final int userId;

  @override
  ConsumerState<_AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends ConsumerState<_AccountBody> {
  bool _busy = false;

  Future<void> _refresh() async {
    ref.invalidate(accountProfileProvider(widget.userId));
    ref.invalidate(accountTripsCountProvider(widget.userId));
    ref.invalidate(walletOverviewProvider(widget.userId));
    try {
      await ref.read(accountProfileProvider(widget.userId).future);
    } on Object {
      // The body renders the failure; the indicator only needs to stop.
    }
  }

  Future<void> _openTerms() async {
    final opened = await launchUrl(
      Uri.parse(Endpoints.termsUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      AppFeedback.toast(context, context.l10n.accCouldNotOpenLink);
    }
  }

  Future<void> _logout() async {
    final l10n = context.l10n;
    final confirmed = await AppFeedback.confirm(
      context,
      title: l10n.areYouSure,
      message: l10n.accLogoutConfirmMessage,
      confirmLabel: l10n.accLogoutConfirmLabel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    await ref.read(logoutProvider.notifier).call();
    if (!mounted) return;
    setState(() => _busy = false);

    final outcome = ref.read(logoutProvider);
    if (outcome case AsyncError(:final error)) {
      AppFeedback.error(context, error);
      return;
    }
    context.goNamed(Routes.home.name);
  }

  Future<void> _deleteAccount() async {
    final l10n = context.l10n;
    final confirmed = await AppFeedback.confirm(
      context,
      title: l10n.areYouSure,
      message: l10n.accDeleteConfirmMessage,
      confirmLabel: l10n.accDeleteConfirmLabel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final result = await ref
        .read(deleteAccountUseCaseProvider)
        .call(widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success():
        AppFeedback.toast(context, l10n.accAccountDeleted);
        ref
          ..invalidate(sessionStatusProvider)
          ..invalidate(currentUserProvider)
          ..invalidate(currentUserIdProvider);
        context.goNamed(Routes.home.name);
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;

    // The use case refreshed the stored user; let the rest of the app see
    // the new name / role / stats.
    ref.listen(accountProfileProvider(userId), (previous, next) {
      if (next is AsyncData<AppUser>) ref.invalidate(currentUserProvider);
    });

    final profile = ref.watch(accountProfileProvider(userId));
    final tripsCount = ref.watch(accountTripsCountProvider(userId)).value;
    final cached = ref.watch(currentUserProvider);
    final user = profile.value ?? cached;

    final Widget body;
    if (user == null) {
      body = switch (profile) {
        AsyncError(:final error) => FailureView(
          error: error,
          onRetry: _refresh,
        ),
        _ => const Center(child: LoadingIndicator()),
      };
    } else {
      body = _AccountContent(
        user: user,
        tripsCount: tripsCount,
        onRefresh: _refresh,
        onOpenTerms: _openTerms,
        onLogout: _logout,
        onDelete: _deleteAccount,
      );
    }

    return Scaffold(
      backgroundColor: context.color.background.canvas,
      appBar: AppBar(
        title: Text(ref.texts.get('account_title', context.l10n.account)),
      ),
      body: Stack(
        children: [
          body,
          if (_busy)
            ColoredBox(
              color: context.color.background.scrim.withValues(alpha: 0.3),
              child: const Center(child: LoadingIndicator()),
            ),
        ],
      ),
    );
  }
}

class _AccountContent extends ConsumerWidget {
  const _AccountContent({
    required this.user,
    required this.tripsCount,
    required this.onRefresh,
    required this.onOpenTerms,
    required this.onLogout,
    required this.onDelete,
  });

  final AppUser user;
  final int? tripsCount;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenTerms;
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = context.dimensions.space;
    final l10n = context.l10n;
    // The wallet only matters once card payment is on, or when this user
    // already has money moving through it.
    final wallet = ref.watch(walletOverviewProvider(user.id)).value;
    final showWallet =
        ref.watch(paymentRulesProvider).onlinePaymentEnabled ||
        (wallet?.hasActivity ?? false);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          space.s16,
          space.s16,
          space.s16,
          space.s32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AccountHeader(
            user: user,
            onTap: () => context.pushNamed(Routes.profile.name),
          ),
          Gap(space.s16),
          StatsStrip(
            tiles: [
              StatTile(
                icon: StatIcon.star,
                value: Formatters.rating(
                  user.averageRating,
                  count: user.ratingsCount,
                  fresh: l10n.newRating,
                ),
                label: l10n.accRating,
              ),
              StatTile(
                icon: StatIcon.box,
                value: '${user.carriedPackagesCount ?? 0}',
                label: l10n.packages,
              ),
              StatTile(
                icon: StatIcon.plane,
                value: '${tripsCount ?? 0}',
                label: l10n.trips,
              ),
              StatTile(
                icon: StatIcon.trees,
                value: Formatters.compact(user.treesSaved ?? 0),
                label: l10n.accTrees,
              ),
            ],
          ),
          Gap(space.s24),
          SectionHeader(title: l10n.accSettings),
          Gap(space.s12),
          MenuSection(
            children: [
              MenuRow(
                icon: Icons.settings_outlined,
                label: l10n.accAccountDetails,
                onTap: () => context.pushNamed(Routes.profile.name),
              ),
              MenuRow(
                icon: Icons.language_rounded,
                label: l10n.language,
                value: LanguageSheet.nativeName(
                  ref.watch(localizationProvider),
                ),
                onTap: () => LanguageSheet.show(context),
              ),
              const NotificationsToggleRow(),
              MenuRow(
                icon: Icons.inventory_2_outlined,
                label: l10n.packages,
                onTap: () => context.goNamed(Routes.packages.name),
              ),
              if (showWallet)
                MenuRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.walTitle,
                  value: wallet == null
                      ? null
                      : Formatters.money(
                          wallet.summary.balance,
                          wallet.summary.currency,
                        ),
                  onTap: () => context.pushNamed(Routes.wallet.name),
                ),
              MenuRow(
                icon: Icons.location_on_outlined,
                label: l10n.accMyAddresses,
                onTap: () => context.pushNamed(Routes.addresses.name),
              ),
              MenuRow(
                icon: Icons.calculate_outlined,
                label: l10n.accCarbonCalculator,
                onTap: () => context.pushNamed(Routes.carbonCalculator.name),
              ),
              MenuRow(
                icon: Icons.description_outlined,
                label: l10n.accTermsAndConditions,
                onTap: onOpenTerms,
              ),
              MenuRow(
                icon: Icons.logout_rounded,
                label: ref.texts.get('logout', l10n.logout),
                onTap: onLogout,
              ),
            ],
          ),
          Gap(space.s16),
          MenuSection(
            children: [
              MenuRow(
                icon: Icons.delete_outline_rounded,
                label: l10n.accDeleteMyAccount,
                destructive: true,
                onTap: onDelete,
              ),
            ],
          ),
          Gap(space.s16),
          const AppVersionLine(),
        ],
      ),
    );
  }
}
