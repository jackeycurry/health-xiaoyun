import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyJwtToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserNickname = 'user_nickname';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // JWT Token
  Future<void> saveJwtToken(String token) async {
    await _prefs.setString(_keyJwtToken, token);
  }

  String? getJwtToken() => _prefs.getString(_keyJwtToken);

  Future<void> clearJwtToken() async {
    await _prefs.remove(_keyJwtToken);
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_keyUserId, userId);
  }

  String? getUserId() => _prefs.getString(_keyUserId);

  // User Phone
  Future<void> saveUserPhone(String phone) async {
    await _prefs.setString(_keyUserPhone, phone);
  }

  String? getUserPhone() => _prefs.getString(_keyUserPhone);

  // User Nickname
  Future<void> saveUserNickname(String nickname) async {
    await _prefs.setString(_keyUserNickname, nickname);
  }

  String? getUserNickname() => _prefs.getString(_keyUserNickname);

  // Clear all auth data (logout)
  Future<void> clearAuth() async {
    await _prefs.remove(_keyJwtToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserPhone);
    await _prefs.remove(_keyUserNickname);
  }

  bool get isLoggedIn => getJwtToken() != null;
}
