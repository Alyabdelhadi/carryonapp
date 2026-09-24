import '../../core/base/result.dart';
import '../../core/base/unit.dart';
import '../../domain/entities/address.dart';
import '../../domain/failures/business_failure.dart';
import '../../domain/repositories/address_repository.dart';
import '../base/repository.dart';
import '../mappers/json_mappers.dart';
import '../services/network/rest_client.dart';

final class AddressRepositoryImpl extends Repository
    implements AddressRepository {
  AddressRepositoryImpl({required this.remote, required super.crashReporter});

  final RestClient remote;

  @override
  Future<Result<List<Address>, BusinessFailure>> list(int userId) {
    return asyncGuard(() async {
      final response = await remote.addresses(userId);
      return Json.asList(response.data).map(AddressMapper.fromJson).toList();
    });
  }

  @override
  Future<Result<Address, BusinessFailure>> create(AddressInput input) {
    return asyncGuard(() async {
      final response = await remote.createAddress(
        AddressMapper.inputToJson(input),
      );
      final body = Json.requireDone(response.data);
      return AddressMapper.fromJson(Json.asMap(body['address']));
    });
  }

  @override
  Future<Result<Address, BusinessFailure>> update(int id, AddressInput input) {
    return asyncGuard(() async {
      final response = await remote.updateAddress(
        id,
        AddressMapper.inputToJson(input),
      );
      final body = Json.requireDone(response.data);
      return AddressMapper.fromJson(Json.asMap(body['address']));
    });
  }

  @override
  Future<Result<Unit, BusinessFailure>> delete({
    required int userId,
    required int addressId,
  }) {
    return asyncGuard(() async {
      final response = await remote.deleteAddress(userId, addressId);
      Json.requireDone(response.data);
      return Unit.value;
    });
  }
}
