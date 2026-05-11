import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:health_xiaohe/core/network/api_endpoints.dart';

class WebSocketClient {
  static const String _wsScheme = 'ws://';
  static const String _wssScheme = 'wss://';

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  StreamController<Uint8List>? _binaryController;
  Timer? _pingTimer;
  String? _token;
  bool _isConnected = false;

  Stream<Map<String, dynamic>>? get messages => _messageController?.stream;
  Stream<Uint8List>? get binaryMessages => _binaryController?.stream;
  bool get isConnected => _isConnected;

  void connect(String token, {String? conversationId}) {
    _token = token;
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    _binaryController = StreamController<Uint8List>.broadcast();

    final wsUrl = _buildWsUrl(conversationId: conversationId);
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (data) {
        try {
          if (data is String) {
            final decoded = json.decode(data);
            _messageController?.add(decoded as Map<String, dynamic>);
          } else if (data is Uint8List) {
            _binaryController?.add(data);
          }
        } catch (_) {
          // Controller already closed
        }
      },
      onError: (error) {
        try {
          _messageController?.addError(error);
        } catch (_) {}
      },
      onDone: () {
        _isConnected = false;
        try { _messageController?.close(); } catch (_) {}
        try { _binaryController?.close(); } catch (_) {}
      },
    );

    _isConnected = true;
    _startPingTimer();
  }

  String _buildWsUrl({String? conversationId}) {
    final baseUrl = ApiEndpoints.baseUrl;
    String wsUrl;
    if (baseUrl.startsWith('https://')) {
      wsUrl = baseUrl.replaceFirst('https://', _wssScheme);
    } else {
      wsUrl = baseUrl.replaceFirst('http://', _wsScheme);
    }
    wsUrl = '$wsUrl${ApiEndpoints.voiceWs}?token=$_token';
    if (conversationId != null && conversationId.isNotEmpty) {
      wsUrl = '$wsUrl&conversation_id=$conversationId';
    }
    return wsUrl;
  }

  void send(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(json.encode(message));
    }
  }

  void sendBinary(Uint8List data) {
    if (_channel != null) {
      _channel!.sink.add(data);
    }
  }

  void sendSessionUpdate({
    List<String> modalities = const ['text', 'audio'],
    String voice = 'akura',
    String instructions = '',
  }) {
    send({
      'type': 'session.update',
      'session': {
        'modalities': modalities,
        'voice': voice,
        'input_audio_format': 'pcm',
        'output_audio_format': 'pcm',
        'instructions': instructions,
        'turn_detection': {
          'type': 'semantic_vad',
          'threshold': 0.5,
          'silence_duration_ms': 800,
        },
      },
    });
  }

  void sendAudioChunk(String base64Audio) {
    send({
      'type': 'input_audio_buffer.append',
      'audio': base64Audio,
    });
  }

  void commitAudioBuffer() {
    send({'type': 'input_audio_buffer.commit'});
  }

  void createResponse() {
    send({'type': 'response.create'});
  }

  void disconnect() {
    _pingTimer?.cancel();
    _isConnected = false;
    _channel?.sink.close();
    _messageController?.close();
    _binaryController?.close();
    _channel = null;
  }

  void _startPingTimer() {
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_isConnected) {
        try {
          _channel?.sink.add(json.encode({'type': 'ping'}));
        } catch (_) {
          // WebSocket disconnected silently, will reconnect via onDone
        }
      }
    });
  }
}
