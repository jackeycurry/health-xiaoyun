import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:health_xiaohe/data/models/sse_chunk.dart';

/// Web 平台 SSE 流式 — XMLHttpRequest.onReadyStateChange 增量读取
///
/// XHR 的 responseText 在 chunk 到达时实时更新，追踪已读长度
/// 仅处理增量数据，实现逐字"打字机"流式效果。
Stream<SseChunk> fetchSseStream({
  required String path,
  required Map<String, dynamic> body,
}) {
  final controller = StreamController<SseChunk>();
  final xhr = html.HttpRequest();
  xhr.open('POST', path);
  xhr.setRequestHeader('Content-Type', 'application/json');

  int lastLength = 0;
  String lineBuffer = '';

  xhr.onReadyStateChange.listen((_) {
    if (xhr.readyState == html.HttpRequest.LOADING ||
        xhr.readyState == html.HttpRequest.DONE) {
      final text = xhr.responseText ?? '';
      if (text.length <= lastLength) return;

      final newData = lineBuffer + text.substring(lastLength);
      lastLength = text.length;

      final lines = newData.split('\n');
      lineBuffer = lines.removeLast();

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
            final convId = json['conversation_id'];
            if (content != null && content.toString().isNotEmpty) {
              controller.add(SseChunk(content: content.toString()));
            }
            if (convId != null && convId.toString().isNotEmpty) {
              controller.add(SseChunk(conversationId: convId.toString()));
            }
          } catch (_) {}
        }
      }

      if (xhr.readyState == html.HttpRequest.DONE) {
        if (lineBuffer.startsWith('data: ') && lineBuffer != 'data: [DONE]') {
          final data = lineBuffer.substring(6);
          try {
            final json = jsonDecode(data);
            final content = json['content'];
            final convId = json['conversation_id'];
            if (content != null && content.toString().isNotEmpty) {
              controller.add(SseChunk(content: content.toString()));
            }
            if (convId != null && convId.toString().isNotEmpty) {
              controller.add(SseChunk(conversationId: convId.toString()));
            }
          } catch (_) {}
        }
        controller.close();
      }
    }
  });

  xhr.onError.listen((_) {
    controller.addError(
      Exception('网络请求失败，请检查后端服务是否启动'),
    );
    controller.close();
  });

  xhr.send(jsonEncode(body));

  return controller.stream;
}
