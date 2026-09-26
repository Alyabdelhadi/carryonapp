import 'package:carryon/src/domain/entities/entities.dart';
import 'package:carryon/src/domain/use_cases/app_update_use_case.dart';
import 'package:carryon/src/domain/use_cases/auth_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser _user(IdentityStatus status) => AppUser(
  id: 1,
  name: 'A',
  email: 'a@b.c',
  phone: '1',
  identityStatus: status,
);

void main() {
  test('gate per identity status', () {
    IdentityGate gate(IdentityStatus s) =>
        ResolveIdentityGateUseCase.gateFor(_user(s));
    expect(gate(IdentityStatus.verified), IdentityGate.verified);
    expect(gate(IdentityStatus.pending), IdentityGate.underReview);
    expect(gate(IdentityStatus.none), IdentityGate.required);
    expect(gate(IdentityStatus.declined), IdentityGate.required);
    expect(gate(IdentityStatus.invalid), IdentityGate.required);
    expect(ResolveIdentityGateUseCase.gateFor(null), IdentityGate.required);
  });

  test('store version comparison', () {
    expect(CheckAppUpdateUseCase.isNewer('56.0.0', '55.0.0'), isTrue);
    expect(CheckAppUpdateUseCase.isNewer('55.0.1', '55.0.0'), isTrue);
    expect(CheckAppUpdateUseCase.isNewer('55.0.0', '55.0.0'), isFalse);
    expect(CheckAppUpdateUseCase.isNewer('50.0.0', '55.0.0'), isFalse);
    expect(CheckAppUpdateUseCase.isNewer('26.0', '55.0.0'), isFalse);
  });
}
