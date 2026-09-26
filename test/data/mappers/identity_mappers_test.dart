import 'package:carryon/src/data/mappers/json_mappers.dart';
import 'package:carryon/src/data/services/network/exceptions.dart';
import 'package:carryon/src/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserMapper identity', () {
    Map<String, dynamic> user(Map<String, dynamic> extra) => {
      'id': 7,
      'name': 'Ali',
      'email': 'a@b.c',
      'phone': '1',
      ...extra,
    };

    test('is_verified wins', () {
      final u = AppUserMapper.fromJson(
        user({'is_verified': true, 'identity_status': null}),
      );
      expect(u.identityStatus, IdentityStatus.verified);
      expect(u.isVerified, isTrue);
    });

    test('maps pending, declined, invalid; old accounts are none', () {
      IdentityStatus of(Object? s) => AppUserMapper.fromJson(
        user({'is_verified': false, 'identity_status': s}),
      ).identityStatus;
      expect(of('pending'), IdentityStatus.pending);
      expect(of('declined'), IdentityStatus.declined);
      expect(of('invalid'), IdentityStatus.invalid);
      expect(of(null), IdentityStatus.none);
      // a user cached before this field existed
      expect(
        AppUserMapper.fromJson(user({})).identityStatus,
        IdentityStatus.none,
      );
    });

    test('round-trips through the session cache', () {
      final u = AppUserMapper.fromJson(user({'identity_status': 'pending'}));
      final back = AppUserMapper.fromJson(AppUserMapper.toJson(u));
      expect(back.identityStatus, IdentityStatus.pending);
      final verified = AppUserMapper.fromJson(user({'is_verified': true}));
      expect(
        AppUserMapper.fromJson(AppUserMapper.toJson(verified)).isVerified,
        isTrue,
      );
    });
  });

  group('Json.requireDone identity reasons', () {
    test('declined / invalid / unavailable become typed exceptions', () {
      TypeMatcher<IdentityRejectedException> kind(
        IdentityVerificationFailureKind k,
      ) => isA<IdentityRejectedException>().having((e) => e.kind, 'kind', k);
      expect(
        () => Json.requireDone({
          'msg': 'error',
          'error': 'x',
          'reason': 'identity_declined',
        }),
        throwsA(kind(IdentityVerificationFailureKind.declined)),
      );
      expect(
        () => Json.requireDone({
          'msg': 'error',
          'error': 'x',
          'reason': 'identity_invalid',
          'detail': 'Blurry',
        }),
        throwsA(
          kind(IdentityVerificationFailureKind.invalid)
              .having((e) => e.detail, 'detail', 'Blurry'),
        ),
      );
      expect(
        () => Json.requireDone({
          'msg': 'error',
          'error': 'x',
          'reason': 'identity_unavailable',
        }),
        throwsA(kind(IdentityVerificationFailureKind.unreachable)),
      );
    });

    test('other errors stay plain', () {
      expect(
        () => Json.requireDone({'msg': 'error', 'error': 'Email exists'}),
        throwsA(isNot(isA<IdentityRejectedException>())),
      );
    });
  });
}
