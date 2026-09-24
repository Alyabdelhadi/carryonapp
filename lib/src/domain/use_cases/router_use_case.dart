import '../repositories/router_repository.dart';

final class GetSessionStatusUseCase {
  GetSessionStatusUseCase(this.repository);

  final RouterRepository repository;

  Future<bool> call() {
    return repository.hasSession();
  }
}
