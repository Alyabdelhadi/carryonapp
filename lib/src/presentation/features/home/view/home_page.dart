import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../data/services/network/endpoints.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/router/route_args.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/failure_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/connectivity_provider.dart';
import '../riverpod/home_providers.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/home_header.dart';
import '../widgets/home_loading_placeholder.dart';
import '../widgets/offline_view.dart';
import '../widgets/service_card.dart';
import '../widgets/update_prompt_dialog.dart';

/// The home tab: greeting header, banner carousel, the three service
/// actions and the second banner row. Goes offline with a retry view, and
/// checks the store version shortly after the first build and every
/// [AppConfig.updateCheckInterval] while it lives.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _initialUpdateCheckDelay = Duration(seconds: 3);

  Timer? _initialUpdateCheck;
  Timer? _periodicUpdateCheck;
  bool _updatePromptOpen = false;

  @override
  void initState() {
    super.initState();
    _initialUpdateCheck = Timer(_initialUpdateCheckDelay, _checkForUpdates);
    _periodicUpdateCheck = Timer.periodic(
      AppConfig.updateCheckInterval,
      (_) => _checkForUpdates(),
    );
  }

  @override
  void dispose() {
    _initialUpdateCheck?.cancel();
    _periodicUpdateCheck?.cancel();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    if (_updatePromptOpen) return;
    final String currentVersion;
    try {
      currentVersion = (await PackageInfo.fromPlatform()).version;
    } on Object {
      return;
    }
    if (!mounted) return;

    final useCase = ref.read(checkAppUpdateUseCaseProvider);
    final decision = await useCase.call(
      currentVersion: currentVersion,
      isIos: Platform.isIOS,
    );
    if (!mounted || !decision.shouldPrompt) return;

    _updatePromptOpen = true;
    final l10n = context.l10n;
    final choice = await showDialog<UpdateChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdatePromptDialog(
        currentVersion: decision.currentVersion,
        latestVersion: decision.latestVersion!,
      ),
    );
    _updatePromptOpen = false;
    if (!mounted) return;

    switch (choice) {
      case UpdateChoice.remindTomorrow:
        await useCase.postpone();
        if (!mounted) return;
        AppFeedback.toast(context, l10n.homeUpdateReminderToast);
      case UpdateChoice.updateNow:
        await useCase.clearPostpone();
        final store = Uri.parse(
          Platform.isIOS ? Endpoints.appStoreUrl : Endpoints.playStoreUrl,
        );
        await launchUrl(store, mode: LaunchMode.externalApplication);
      case null:
        break;
    }
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(homeSlidersProvider)
      ..invalidate(homeSecondarySlidersProvider)
      ..invalidate(homeServicesProvider)
      ..invalidate(homePlaceProvider)
      ..invalidate(homeMatchingPackagesCountProvider)
      ..invalidate(homeUpcomingTripsCountProvider);
    await Future.wait<Object?>([
      ref.read(homeSlidersProvider.future),
      ref.read(homeSecondarySlidersProvider.future),
      ref.read(homeServicesProvider.future),
    ]).catchError((Object _) => const <Object?>[]);
  }

  void _retryConnection() {
    ref.invalidate(isOnlineProvider);
    unawaited(_refresh());
  }

  /// Mirrors the original `setCate(id)`: every action needs a session.
  void _openService(int id, String loginMessage) {
    switch (id) {
      case 1:
        unawaited(
          requireLogin(
            context,
            ref,
            () => context.pushNamed(
              Routes.orderForm.name,
              extra: const OrderFormArgs(flow: ParcelFlow.send),
            ),
            message: loginMessage,
          ),
        );
      case 2:
        _openMatching(loginMessage);
      case 3:
        unawaited(
          requireLogin(
            context,
            ref,
            () => context.pushNamed(
              Routes.orderForm.name,
              extra: const OrderFormArgs(flow: ParcelFlow.receive),
            ),
            message: loginMessage,
          ),
        );
    }
  }

  void _openMatching(String loginMessage) {
    unawaited(
      requireLogin(
        context,
        ref,
        () => context.pushNamed(Routes.matching.name),
        message: loginMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider).value ?? true;
    final loginMessage = ref.texts.get(
      'access_page',
      context.l10n.coreLoginToAccessPage,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: isOnline
            ? RefreshIndicator(
                onRefresh: _refresh,
                child: _HomeBody(
                  onServiceTap: (id) => _openService(id, loginMessage),
                  onPackagesTap: () => _openMatching(loginMessage),
                  onTripsTap: () => context.goNamed(Routes.trips.name),
                ),
              )
            : OfflineView(onRefresh: _retryConnection),
      ),
    );
  }
}

/// The scrolling content while online.
class _HomeBody extends ConsumerWidget {
  const _HomeBody({
    required this.onServiceTap,
    required this.onPackagesTap,
    required this.onTripsTap,
  });

  final ValueChanged<int> onServiceTap;
  final VoidCallback onPackagesTap;
  final VoidCallback onTripsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = context.dimensions.space;
    final sliders = ref.watch(homeSlidersProvider);
    final secondary = ref.watch(homeSecondarySlidersProvider);
    final services = ref.watch(homeServicesProvider);
    final isLoading = services.isLoading && sliders.isLoading;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // The floating tab bar hands its height down as the bottom inset.
      padding: EdgeInsets.fromLTRB(
        space.s16,
        space.s16,
        space.s16,
        space.s32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        HomeHeader(onPackagesTap: onPackagesTap, onTripsTap: onTripsTap),
        Gap(space.s24),
        if (isLoading)
          const HomeLoadingPlaceholder()
        else ...[
          switch (sliders) {
            AsyncData(:final value) when value.isNotEmpty => Padding(
              padding: EdgeInsets.only(bottom: space.s24),
              child: BannerCarousel(images: value, aspectRatio: 2),
            ),
            AsyncLoading() => const HomeLoadingPlaceholder(showServices: false),
            _ => const SizedBox.shrink(),
          },
          HeadingLevel3Text(context.l10n.homeHeadline),
          Gap(space.s16),
          switch (services) {
            AsyncData(:final value) => ServiceGrid(
              services: value,
              onTap: (service) => onServiceTap(service.id),
            ),
            AsyncError(:final error) => Padding(
              padding: EdgeInsets.symmetric(vertical: space.s24),
              child: FailureView(
                error: error,
                onRetry: () => ref.invalidate(homeServicesProvider),
              ),
            ),
            _ => const HomeLoadingPlaceholder(showBanner: false),
          },
          switch (secondary) {
            AsyncData(:final value) when value.isNotEmpty => Padding(
              padding: EdgeInsets.only(top: space.s12),
              child: BannerCarousel(
                images: value,
                aspectRatio: 2.4,
                fit: BoxFit.contain,
                showIndicators: false,
              ),
            ),
            _ => const SizedBox.shrink(),
          },
        ],
      ],
    );
  }
}
