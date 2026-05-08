import 'package:equatable/equatable.dart';

abstract class VoiceState extends Equatable {
  const VoiceState();

  @override
  List<Object?> get props => [];
}

class VoiceInitial extends VoiceState {}

class VoiceConnecting extends VoiceState {}

class VoiceConnected extends VoiceState {}

class VoiceDisconnected extends VoiceState {}

/// 用户打断AI — AI停止播放，转为聆听用户
class VoiceListening extends VoiceState {}

/// AI正在处理用户的语音输入
class VoiceProcessingInput extends VoiceState {}

class VoiceRecording extends VoiceState {
  final Duration duration;

  const VoiceRecording({this.duration = Duration.zero});

  @override
  List<Object?> get props => [duration];
}

class VoiceProcessing extends VoiceState {}

class VoiceReceivingText extends VoiceState {
  final String text;

  const VoiceReceivingText(this.text);

  @override
  List<Object?> get props => [text];
}

class VoiceReceivingAudio extends VoiceState {
  final String audioData;

  const VoiceReceivingAudio(this.audioData);

  @override
  List<Object?> get props => [audioData];
}

class VoiceConversationCreated extends VoiceState {
  final String conversationId;
  const VoiceConversationCreated(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class VoiceUserText extends VoiceState {
  final String text;
  const VoiceUserText(this.text);
  @override
  List<Object?> get props => [text];
}

class VoiceAiFullText extends VoiceState {
  final String text;
  const VoiceAiFullText(this.text);
  @override
  List<Object?> get props => [text];
}

class VoiceDone extends VoiceState {}

class VoiceErrorState extends VoiceState {
  final String message;

  const VoiceErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
