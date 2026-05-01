import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:health_xiaohe/core/network/api_client.dart';
import 'package:health_xiaohe/data/models/chat_message_model.dart';
import 'package:health_xiaohe/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _apiClient;

  ChatRepositoryImpl(this._apiClient);

  @override
  Stream<String> getChatStream(List<ChatMessageModel> messages) async* {
    final apiMessages = messages.map((m) => m.toApiFormat()).toList();

    try {
      final response = await _apiClient.dio.post(
        '/api/consult/chat/stream',
        data: {'messages': apiMessages},
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;

      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              return;
            }
            try {
              final json = jsonDecode(data);
              // Backend returns {"content": "xxx"}
              final content = json['content'];
              if (content != null && content.toString().isNotEmpty) {
                yield content.toString();
              }
            } catch (_) {
              // Skip invalid JSON
            }
          }
        }
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? '发送消息失败');
    }
  }

  @override
  Future<ChatResult<ChatMessageModel>> sendMessage(List<ChatMessageModel> messages) async {
    try {
      final apiMessages = messages.map((m) => m.toApiFormat()).toList();
      final response = await _apiClient.chat(apiMessages);

      final content = response.data['choices']?[0]?['message']?['content'] ?? '';
      return ChatResult.success(ChatMessageModel.assistant(content));
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? '发送消息失败';
      return ChatResult.failure(message.toString());
    } catch (e) {
      return ChatResult.failure('发送消息失败: $e');
    }
  }
}
