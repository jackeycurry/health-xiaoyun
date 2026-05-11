import 'package:equatable/equatable.dart';

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object?> get props => [];
}

class VoiceConnect extends VoiceEvent {
  final String token;
  final String? conversationId; // 续接之前的文字对话

  const VoiceConnect(this.token, {this.conversationId});

  @override
  List<Object?> get props => [token, conversationId];
}

class VoiceDisconnect extends VoiceEvent {}

class VoiceSendAudioChunk extends VoiceEvent {
  final String base64Audio;

  const VoiceSendAudioChunk(this.base64Audio);

  @override
  List<Object?> get props => [base64Audio];
}

class VoiceCommitAudio extends VoiceEvent {}

class VoiceReceiveMessage extends VoiceEvent {
  final Map<String, dynamic> message;

  const VoiceReceiveMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class VoiceReceiveBinary extends VoiceEvent {
  final List<int> data;

  const VoiceReceiveBinary(this.data);

  @override
  List<Object?> get props => [data];
}

class VoiceError extends VoiceEvent {
  final String error;

  const VoiceError(this.error);

  @override
  List<Object?> get props => [error];
}

class VoiceSendImageChunk extends VoiceEvent {
  final String base64Jpeg;
  const VoiceSendImageChunk(this.base64Jpeg);
  @override
  List<Object?> get props => [base64Jpeg];
}

class VoiceStartRecording extends VoiceEvent {}

class VoiceStopRecording extends VoiceEvent {}
