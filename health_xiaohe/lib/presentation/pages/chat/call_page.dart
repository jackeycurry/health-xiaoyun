import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:health_xiaohe/core/audio/audio_recorder_stub.dart'
    if (dart.library.html) 'package:health_xiaohe/core/audio/audio_recorder_web.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/core/storage/local_storage.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_event.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_state.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _audioRecorder = AudioRecorder();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callStarted = false;
  int _callDuration = 0;
  Timer? _timer;
  String _aiText = '';
  VoiceBloc? _voiceBloc;

  @override
  void initState() {
    super.initState();
    _voiceBloc = context.read<VoiceBloc>();
    _startCall();
  }

  void _startCall() {
    final token = GetIt.instance<LocalStorage>().getJwtToken() ?? '';
    _voiceBloc?.add(VoiceConnect(token));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _startRecording() async {
    debugPrint('[CALL] _startRecording enter');
    try {
      debugPrint('[CALL] checking permission...');
      final hasPermission = await _audioRecorder.hasPermission();
      debugPrint('[CALL] hasPermission=$hasPermission');
      if (!hasPermission) {
        debugPrint('[CALL] permission denied, ending call');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请允许麦克风权限')),
          );
          _endCall();
        }
        return;
      }
      debugPrint('[CALL] starting audio recorder...');
      var chunkCount = 0;
      await _audioRecorder.startRecording((base64) {
        chunkCount++;
        if (chunkCount <= 5) debugPrint('[CALL] audio chunk #$chunkCount len=${base64.length}');
        if (!_isMuted) {
          _voiceBloc?.add(VoiceSendAudioChunk(base64));
        }
      });
      debugPrint('[CALL] startRecording completed');
    } catch (e) {
      debugPrint('[CALL] startRecording error: $e');
    }
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _stopTimer();
    _audioRecorder.dispose();
    _voiceBloc?.add(VoiceDisconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A2A3A),
              Color(0xFF0d1520),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<VoiceBloc, VoiceState>(
            listener: (context, state) {
              if (state is VoiceConnected && !_callStarted) {
                _callStarted = true;
                _startTimer();
                _startRecording();
              } else if (state is VoiceReceivingText) {
                setState(() => _aiText = state.text);
              } else if (state is VoiceDone) {
                _endCall();
              } else if (state is VoiceErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.danger,
                  ),
                );
                _endCall();
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  const Spacer(),
                  _buildCallStatus(state),
                  const SizedBox(height: 24),
                  if (_aiText.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _aiText,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (state is VoiceConnected)
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  const Spacer(),
                  _buildControlButtons(context, state),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCallStatus(VoiceState state) {
    String statusText = '正在连接...';

    if (state is VoiceConnected) {
      statusText = _aiText.isNotEmpty ? '已接听' : '已接通，请说话...';
    } else if (state is VoiceReceivingText) {
      statusText = '正在回复...';
    } else if (state is VoiceConnecting) {
      statusText = '正在连接...';
    }

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Center(
            child: Text('🌿', style: TextStyle(fontSize: 60)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '健康小荷',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(BuildContext context, VoiceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              backgroundColor: _isMuted
                  ? AppColors.danger.withOpacity(0.8)
                  : Colors.white.withOpacity(0.15),
              onTap: () {
                setState(() => _isMuted = !_isMuted);
              },
            ),
            const SizedBox(width: 30),
            _buildControlButton(
              icon: Icons.call_end,
              backgroundColor: AppColors.danger,
              size: 64,
              iconSize: 28,
              onTap: _endCall,
            ),
            const SizedBox(width: 30),
            _buildControlButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              backgroundColor: _isSpeakerOn
                  ? AppColors.primary.withOpacity(0.8)
                  : Colors.white.withOpacity(0.15),
              onTap: () {
                setState(() => _isSpeakerOn = !_isSpeakerOn);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    double size = 60,
    double iconSize = 28,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  void _endCall() {
    _stopTimer();
    _callStarted = false;
    _audioRecorder.dispose();
    _voiceBloc?.add(VoiceDisconnect());
    if (mounted) {
      context.go('/chat');
    }
  }
}
