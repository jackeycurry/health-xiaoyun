import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:health_xiaohe/data/models/sse_chunk.dart';

/// Web 平台 SSE 流式 — XHR + 定时器轮询 responseText。
///
/// 某些浏览器对 text/event-stream 不触发 LOADING 状态，
/// 因此用定时器每 100ms 读取 responseText 增量实现流式效果。
Stream<SseChunk> fetchSseStream({
  required String path,
  required Map<String, dynamic> body,
}) async* {
  final controller = StreamController<SseChunk>();

  final xhr = html.HttpRequest();
  xhr.open('POST', path);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.setRequestHeader('Accept', 'text/event-stream');

  int lastLength = 0;
  String lineBuffer = '';
  Timer? timer;

  void processIncremental(String text) {
    if (text.length <= lastLength) return;

    final newData = lineBuffer + text.substring(lastLength);
    lastLength = text.length;

    final lines = newData.split('\n');
    lineBuffer = lines.removeLast();

    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data: ')) continue;
      final data = trimmed.substring(6);
      if (data == '[DONE]') {
        timer?.cancel();
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

  timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    processIncremental(xhr.responseText ?? '');
  });

  xhr.onReadyStateChange.listen((_) {
    if (xhr.readyState == html.HttpRequest.DONE) {
      timer?.cancel();
      if (lineBuffer.trim().startsWith('data: ')) {
        final data = lineBuffer.trim().substring(6);
        if (data != '[DONE]') {
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
      controller.close();
    }
  });

  xhr.onError.listen((_) {
    timer?.cancel();
    controller.addError(Exception('网络请求失败'));
    controller.close();
  });

  xhr.send(jsonEncode(body));

  yield* controller.stream;
}
