import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health_xiaohe/core/network/api_client.dart';
import 'package:health_xiaohe/data/models/chat_message_model.dart';
import 'package:health_xiaohe/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _apiClient;

  ChatRepositoryImpl(this._apiClient);

  @override
  Stream<String> getChatStream(List<ChatMessageModel> messages) async* {
    final apiMessages = messages.map((m) => m.toApiFormat()).toList();

    if (kIsWeb) {
      // Web 平台
      yield* _getChatStreamWeb(apiMessages);
    } else {
      // 其他平台
      yield* _getChatStreamNative(apiMessages);
    }
  }

  Stream<String> _getChatStreamWeb(List<Map<String, String>> apiMessages) async* {
    final token = _apiClient.dio.options.headers['Authorization'] ?? '';
    final tokenValue = token.toString().replaceFirst('Bearer ', '');
    final baseUrl = _apiClient.dio.options.baseUrl;

    // 构建 SSE URL
    final sseUrl = '$baseUrl/api/consult/chat/stream';

    try {
      // 在 web 上使用 Dio 的 stream 模式
      final response = await Dio().post(
        sseUrl,
        data: {'messages': apiMessages},
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $tokenValue',
            'Content-Type': 'application/json',
          },
        ),
      );

      final stream = response.data as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              return;
            }
            try {
              final json = jsonDecode(data);
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
    } catch (e) {
      yield* Stream.error(e);
    }
  }

  Stream<String> _getChatStreamNative(List<Map<String, String>> apiMessages) async* {
    final controller = StreamController<String>();

    try {
      final response = await _apiClient.dio.post(
        '/api/consult/chat/stream',
        data: {'messages': apiMessages},
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      response.data.stream.listen(
        (chunk) {
          final lines = utf8.decode(chunk, allowMalformed: true).split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                controller.close();
                return;
              }
              try {
                final json = jsonDecode(data);
                final content = json['content'];
                if (content != null && content.toString().isNotEmpty) {
                  controller.add(content.toString());
                }
              } catch (_) {
                // Skip invalid JSON
              }
            }
          }
        },
        onError: (error) {
          controller.addError(error);
          controller.close();
        },
        onDone: () {
          controller.close();
        },
      );
    } on DioException catch (e) {
      controller.addError(Exception(e.response?.data?['detail'] ?? '发送消息失败'));
      controller.close();
    }

    yield* controller.stream;
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
