import 'package:health_xiaohe/data/models/user_model.dart';

abstract class AuthRepository {
  Future<AuthResult> login(String phone, String password);
  Future<AuthResult> register(String phone, String password, {String? nickname});
  Future<AuthResult> getCurrentUser();
  Future<void> logout();
  bool get isLoggedIn;
  String? get token;
}

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  AuthResult.success(this.user)
      : success = true,
        error = null;

  AuthResult.failure(this.error)
      : success = false,
        user = null;
}
