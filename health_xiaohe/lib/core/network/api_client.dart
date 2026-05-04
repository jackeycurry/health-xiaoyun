import 'package:dio/dio.dart';
import 'package:health_xiaohe/core/network/api_endpoints.dart';
import 'package:health_xiaohe/core/storage/local_storage.dart';
import 'package:get_it/get_it.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        final localStorage = GetIt.instance<LocalStorage>();
        final token = localStorage.getJwtToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle common errors
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // Auth endpoints
  Future<Response> login(String phone, String password) async {
    return _dio.post(ApiEndpoints.login, data: {
      'phone': phone,
      'password': password,
    });
  }

  Future<Response> register(String phone, String password, {String? nickname}) async {
    return _dio.post(ApiEndpoints.register, data: {
      'phone': phone,
      'password': password,
      if (nickname != null) 'nickname': nickname,
    });
  }

  Future<Response> getMe() async {
    return _dio.get(ApiEndpoints.me);
  }

  // Health record endpoints
  Future<Response> getHealthRecords({
    String? recordType,
    int limit = 20,
    int offset = 0,
  }) async {
    return _dio.get(ApiEndpoints.healthRecords, queryParameters: {
      if (recordType != null) 'record_type': recordType,
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> getLatestRecords() async {
    return _dio.get(ApiEndpoints.latestRecords);
  }

  Future<Response> createHealthRecord(Map<String, dynamic> data) async {
    return _dio.post(ApiEndpoints.healthRecords, data: data);
  }

  Future<Response> deleteHealthRecord(String recordId) async {
    return _dio.delete(ApiEndpoints.healthRecord(recordId));
  }

  // Chat endpoints
  Future<Response> chat(List<Map<String, String>> messages, {bool stream = false}) async {
    return _dio.post(ApiEndpoints.chat, data: {
      'messages': messages,
      'stream': stream,
    });
  }

  // Conversation endpoints
  Future<Response> getConversations() async {
    return _dio.get(ApiEndpoints.conversations);
  }

  Future<Response> getConversationDetail(String id) async {
    return _dio.get(ApiEndpoints.conversationDetail(id));
  }

  // Voice chat (base64 audio)
  Future<Response> voiceChat(String base64Audio) async {
    return _dio.post(ApiEndpoints.voiceChat, data: {
      'audio': base64Audio,
    });
  }
}
