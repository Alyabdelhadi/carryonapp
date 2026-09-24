import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/localization.dart';
import '../application_state/session_status_provider/session_status_provider.dart';
import '../gen/assets.gen.dart';
import 'glass_navigation_bar.dart';

/// The bottom tab bar: Home, Packages, Trips and Account (which reads
/// "Login" while signed out, as in the original app). The bar floats over
/// the page as frosted glass; `extendBody` lets content scroll beneath it
/// and hands the pages the bar's height as their bottom inset.
class NavigationShell extends ConsumerWidget {
  const NavigationShell({super.key, required this.statefulNavigationShell});

  final StatefulNavigationShell statefulNavigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = switch (ref.watch(sessionStatusProvider)) {
      AsyncData(value: .authenticated) => true,
      _ => false,
    };

    return Scaffold(
      extendBody: true,
      body: statefulNavigationShell,
      bottomNavigationBar: GlassNavigationBar(
        selectedIndex: statefulNavigationShell.currentIndex,
        onSelected: (index) => statefulNavigationShell.goBranch(
          index,
          initialLocation: index == statefulNavigationShell.currentIndex,
        ),
        items: [
          GlassNavigationItem(
            label: context.locale.home,
            icon: Assets.icons.navHome,
            selectedIcon: Assets.icons.navHomeFilled,
          ),
          GlassNavigationItem(
            label: context.locale.packages,
            icon: Assets.icons.navPackages,
            selectedIcon: Assets.icons.navPackagesFilled,
          ),
          GlassNavigationItem(
            label: context.locale.trips,
            icon: Assets.icons.navTrips,
            selectedIcon: Assets.icons.navTripsFilled,
          ),
          GlassNavigationItem(
            label: isLoggedIn ? context.locale.account : context.locale.login,
            icon: Assets.icons.navAccount,
            selectedIcon: Assets.icons.navAccountFilled,
          ),
        ],
      ),
    );
  }
}
