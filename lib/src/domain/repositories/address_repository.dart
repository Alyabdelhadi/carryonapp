import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../entities/address.dart';
import '../failures/business_failure.dart';

abstract interface class AddressRepository {
  Future<Result<List<Address>, BusinessFailure>> list(int userId);

  Future<Result<Address, BusinessFailure>> create(AddressInput input);

  Future<Result<Address, BusinessFailure>> update(int id, AddressInput input);

  Future<Result<Unit, BusinessFailure>> delete({
    required int userId,
    required int addressId,
  });
}
