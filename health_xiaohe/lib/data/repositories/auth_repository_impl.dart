import 'package:dio/dio.dart';
import 'package:health_xiaohe/core/network/api_client.dart';
import 'package:health_xiaohe/core/storage/local_storage.dart';
import 'package:health_xiaohe/data/models/user_model.dart';
import 'package:health_xiaohe/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  AuthRepositoryImpl(this._apiClient, this._localStorage);

  @override
  bool get isLoggedIn => _localStorage.isLoggedIn;

  @override
  String? get token => _localStorage.getJwtToken();

  @override
  Future<AuthResult> login(String phone, String password) async {
    try {
      final response = await _apiClient.login(phone, password);
      final token = TokenModel.fromJson(response.data);
      await _localStorage.saveJwtToken(token.accessToken);

      // Fetch user info after login
      return getCurrentUser();
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? '登录失败';
      return AuthResult.failure(message.toString());
    } catch (e) {
      return AuthResult.failure('登录失败: $e');
    }
  }

  @override
  Future<AuthResult> register(String phone, String password, {String? nickname}) async {
    try {
      final response = await _apiClient.register(phone, password, nickname: nickname);
      final user = UserModel.fromJson(response.data);
      return AuthResult.success(user);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? '注册失败';
      return AuthResult.failure(message.toString());
    } catch (e) {
      return AuthResult.failure('注册失败: $e');
    }
  }

  @override
  Future<AuthResult> getCurrentUser() async {
    try {
      final response = await _apiClient.getMe();
      final user = UserModel.fromJson(response.data);
      await _localStorage.saveUserId(user.id);
      await _localStorage.saveUserPhone(user.phone);
      if (user.nickname != '健康用户') {
        await _localStorage.saveUserNickname(user.nickname);
      }
      return AuthResult.success(user);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? '获取用户信息失败';
      return AuthResult.failure(message.toString());
    } catch (e) {
      return AuthResult.failure('获取用户信息失败: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _localStorage.clearAuth();
  }
}
