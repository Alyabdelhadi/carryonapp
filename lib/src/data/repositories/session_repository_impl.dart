import 'dart:convert';

import '../../domain/entities/app_texts.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/session_repository.dart';
import '../mappers/json_mappers.dart';
import '../services/cache/cache_service.dart';

/// Preference-backed session. Synchronous reads so the router gate and
/// widgets can consult it without an `await`.
final class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this.local);

  final CacheService local;

  @override
  int? get userId => local.get<int>(CacheKey.userId);

  @override
  bool get isLoggedIn => (userId ?? 0) > 0;

  @override
  AppUser? get user {
    final raw = local.get<String>(CacheKey.userData);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUserMapper.fromJson(Json.asMap(jsonDecode(raw)));
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveUser(AppUser user) async {
    await local.save(CacheKey.userId, user.id);
    await local.save(CacheKey.userData, jsonEncode(AppUserMapper.toJson(user)));
    if (user.role != null) {
      await local.save(CacheKey.userRole, user.role!);
    }
  }

  @override
  Future<void> clearSession() {
    return local.remove([
      CacheKey.userId,
      CacheKey.userData,
      CacheKey.userRole,
    ]);
  }

  @override
  bool get notificationsEnabled =>
      local.get<bool>(CacheKey.notificationsEnabled) ?? true;

  @override
  Future<void> setNotificationsEnabled(bool enabled) {
    return local.save(CacheKey.notificationsEnabled, enabled);
  }

  @override
  AppTexts get cachedTexts {
    final raw = local.get<String>(CacheKey.appTexts);
    if (raw == null || raw.isEmpty) return const AppTexts.empty();
    try {
      return CatalogMapper.texts(jsonDecode(raw));
    } on Object {
      return const AppTexts.empty();
    }
  }

  @override
  Future<void> cacheTexts(AppTexts texts) {
    return local.save(CacheKey.appTexts, jsonEncode(texts.toMap()));
  }
}
