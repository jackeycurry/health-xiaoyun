import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_xiaohe/core/network/websocket_client.dart';
import 'voice_event.dart';
import 'voice_state.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final WebSocketClient _webSocketClient;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _binarySubscription;
  String _accumulatedText = '';

  static const String _healthInstructions = '''你是一位专业的AI健康助手，名叫"健康小荷"。请根据用户的语音问题提供健康建议。

重要原则：
1. 仅提供健康信息参考，不能替代专业医生诊断
2. 严重症状要提醒用户及时就医
3. 回答要专业、温暖、易懂，控制在50字以内
4. 如果不确定，建议寻求专业医疗帮助
5. 回复语言：简体中文''';

  VoiceBloc(this._webSocketClient) : super(VoiceInitial()) {
    on<VoiceConnect>(_onConnect);
    on<VoiceDisconnect>(_onDisconnect);
    on<VoiceSendAudioChunk>(_onSendAudioChunk);
    on<VoiceCommitAudio>(_onCommitAudio);
    on<VoiceReceiveMessage>(_onReceiveMessage);
    on<VoiceReceiveBinary>(_onReceiveBinary);
    on<VoiceError>(_onError);
  }

  void _onConnect(VoiceConnect event, Emitter<VoiceState> emit) {
    emit(VoiceConnecting());

    _webSocketClient.connect(event.token);

    _messageSubscription?.cancel();
    _messageSubscription = _webSocketClient.messages?.listen(
      (message) {
        add(VoiceReceiveMessage(message));
      },
      onError: (error) {
        add(VoiceError(error.toString()));
      },
    );

    _binarySubscription?.cancel();
    _binarySubscription = _webSocketClient.binaryMessages?.listen(
      (data) {
        add(VoiceReceiveBinary(data));
      },
    );

    // Send session update configuration
    _webSocketClient.sendSessionUpdate(
      modalities: ['text', 'audio'],
      voice: 'akura',
      instructions: _healthInstructions,
    );

    emit(VoiceConnected());
  }

  void _onDisconnect(VoiceDisconnect event, Emitter<VoiceState> emit) {
    _messageSubscription?.cancel();
    _binarySubscription?.cancel();
    _webSocketClient.disconnect();
    _accumulatedText = '';
    emit(VoiceDisconnected());
  }

  void _onSendAudioChunk(VoiceSendAudioChunk event, Emitter<VoiceState> emit) {
    _webSocketClient.sendAudioChunk(event.base64Audio);
  }

  void _onCommitAudio(VoiceCommitAudio event, Emitter<VoiceState> emit) {
    _webSocketClient.commitAudioBuffer();
    _webSocketClient.createResponse();
    emit(VoiceProcessing());
  }

  void _onReceiveMessage(VoiceReceiveMessage event, Emitter<VoiceState> emit) {
    final message = event.message;
    final type = message['type'] as String?;

    switch (type) {
      case 'session.updated':
        // Session confirmed, ready for audio
        break;

      case 'response.text.delta':
        final text = message['text'] as String? ?? '';
        _accumulatedText += text;
        emit(VoiceReceivingText(_accumulatedText));
        break;

      case 'response.audio.delta':
        final audio = message['audio'] as String? ?? '';
        emit(VoiceReceivingAudio(audio));
        break;

      case 'response.done':
        emit(VoiceDone());
        _accumulatedText = '';
        break;

      case 'error':
        final error = message['message'] ?? message.toString();
        add(VoiceError(error.toString()));
        break;
    }
  }

  void _onReceiveBinary(VoiceReceiveBinary event, Emitter<VoiceState> emit) {
    // Handle binary audio data if needed
  }

  void _onError(VoiceError event, Emitter<VoiceState> emit) {
    emit(VoiceErrorState(event.error));
    _accumulatedText = '';
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _binarySubscription?.cancel();
    _webSocketClient.disconnect();
    return super.close();
  }
}
