import '../../domain/repositories/router_repository.dart';
import '../../domain/repositories/session_repository.dart';

class RouterRepositoryImpl extends RouterRepository {
  RouterRepositoryImpl({required this.session});

  final SessionRepository session;

  @override
  Future<bool> hasSession() async => session.isLoggedIn;
}
