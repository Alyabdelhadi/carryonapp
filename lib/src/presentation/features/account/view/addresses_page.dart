import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/failure_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/login_required_view.dart';
import '../riverpod/addresses_provider.dart';
import '../widgets/address_tile.dart';

/// "My Addresses": the saved address book with add, edit and delete.
class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.accMyAddresses)),
        body: const LoginRequired(child: SizedBox.shrink()),
      );
    }
    return _AddressesBody(userId: userId);
  }
}

class _AddressesBody extends ConsumerStatefulWidget {
  const _AddressesBody({required this.userId});

  final int userId;

  @override
  ConsumerState<_AddressesBody> createState() => _AddressesBodyState();
}

class _AddressesBodyState extends ConsumerState<_AddressesBody> {
  bool _busy = false;

  Future<void> _refresh() async {
    ref.invalidate(myAddressesProvider(widget.userId));
    try {
      await ref.read(myAddressesProvider(widget.userId).future);
    } on Object {
      // Rendered by the body; the indicator only needs to stop.
    }
  }

  Future<void> _add() async {
    await context.pushNamed(Routes.addressForm.name);
    if (mounted) ref.invalidate(myAddressesProvider(widget.userId));
  }

  Future<void> _edit(Address address) async {
    await context.pushNamed(Routes.addressForm.name, extra: address);
    if (mounted) ref.invalidate(myAddressesProvider(widget.userId));
  }

  /// Asks, deletes, and resolves true when the row is gone.
  Future<bool> _delete(Address address) async {
    final l10n = context.l10n;
    final confirmed = await AppFeedback.confirm(
      context,
      title: l10n.accDeleteAddressTitle,
      message: l10n.accDeleteAddressMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.back,
      destructive: true,
    );
    if (!confirmed || !mounted) return false;

    setState(() => _busy = true);
    final result = await ref
        .read(deleteAddressUseCaseProvider)
        .call(userId: widget.userId, addressId: address.id);
    if (!mounted) return false;
    setState(() => _busy = false);

    switch (result) {
      case Success():
        AppFeedback.toast(context, l10n.accAddressDeleted);
        ref.invalidate(myAddressesProvider(widget.userId));
        return true;
      case Error(:final error):
        AppFeedback.error(context, error);
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(myAddressesProvider(widget.userId));
    final l10n = context.l10n;
    final addLabel = ref.texts.get('address_add', l10n.accAddNewAddress);
    final space = context.dimensions.space;

    final body = switch (addresses) {
      AsyncData(:final value) when value.isEmpty => EmptyState(
        icon: Icons.location_off_outlined,
        title: l10n.accNoAddressesTitle,
        message: ref.texts.get('address_msg', l10n.accNoAddressesMessage),
        actionLabel: addLabel,
        onAction: _add,
      ),
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(space.s16),
          itemCount: value.length,
          separatorBuilder: (_, _) => Gap(space.s12),
          itemBuilder: (context, index) {
            final address = value[index];
            return Dismissible(
              key: ValueKey(address.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _delete(address),
              background: const _DeleteBackground(),
              child: AddressTile(
                address: address,
                onEdit: () => _edit(address),
                onDelete: () => _delete(address),
              ),
            );
          },
        ),
      ),
      AsyncError(:final error) => FailureView(error: error, onRetry: _refresh),
      _ => const Center(child: LoadingIndicator()),
    };

    final hasRows = addresses.value?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: context.color.background.canvas,
      appBar: AppBar(
        title: Text(l10n.accMyAddresses),
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            tooltip: l10n.close,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
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
      bottomNavigationBar: hasRows
          ? SafeArea(
              minimum: EdgeInsets.all(space.s16),
              child: FilledButton.icon(
                onPressed: _busy ? null : _add,
                icon: const Icon(Icons.add_rounded),
                label: Text(addLabel),
              ),
            )
          : null,
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsets.symmetric(horizontal: context.dimensions.space.s24),
      decoration: BoxDecoration(
        color: context.color.status.dangerTint,
        borderRadius: BorderRadius.circular(context.dimensions.radius.large),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        color: context.color.status.danger,
        size: context.dimensions.size.iconLarge,
      ),
    );
  }
}
