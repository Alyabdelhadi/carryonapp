import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device has a network route. Emits the current state first,
/// then every change. Invalidate it to re-check (the offline view's retry).
///
/// "Offline" is only reported when the platform still says `none` after a
/// short grace period: iOS (and simulators in particular) emit a transient
/// `none` right after launch or a hot restart, and the Ionic app likewise
/// waited before trusting a reconnect. Going back online is immediate.
final isOnlineProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final connectivity = Connectivity();
  yield await _confirmedState(
    connectivity,
    await connectivity.checkConnectivity(),
  );
  await for (final results in connectivity.onConnectivityChanged) {
    yield await _confirmedState(connectivity, results);
  }
});

const _offlineGrace = Duration(seconds: 2);

Future<bool> _confirmedState(
  Connectivity connectivity,
  List<ConnectivityResult> results,
) async {
  if (_isOnline(results)) return true;
  await Future<void>.delayed(_offlineGrace);
  return _isOnline(await connectivity.checkConnectivity());
}

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}
