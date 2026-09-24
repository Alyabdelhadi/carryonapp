import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/address.dart';
import '../failures/business_failure.dart';
import '../repositories/address_repository.dart';

final class GetAddressesUseCase {
  GetAddressesUseCase(this.addresses);

  final AddressRepository addresses;

  Future<Result<List<Address>, BusinessFailure>> call(int userId) =>
      addresses.list(userId);
}

final class SaveAddressUseCase {
  SaveAddressUseCase(this.addresses);

  final AddressRepository addresses;

  Future<Result<Address, BusinessFailure>> call(
    AddressInput input, {
    int? addressId,
  }) {
    return addressId == null
        ? addresses.create(input)
        : addresses.update(addressId, input);
  }
}

final class DeleteAddressUseCase {
  DeleteAddressUseCase(this.addresses);

  final AddressRepository addresses;

  Future<Result<Unit, BusinessFailure>> call({
    required int userId,
    required int addressId,
  }) {
    return addresses.delete(userId: userId, addressId: addressId);
  }
}
