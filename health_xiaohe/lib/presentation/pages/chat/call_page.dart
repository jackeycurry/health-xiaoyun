import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:health_xiaohe/core/audio/audio_recorder_stub.dart'
    if (dart.library.html) 'package:health_xiaohe/core/audio/audio_recorder_web.dart'
    if (dart.library.io) 'package:health_xiaohe/core/audio/audio_recorder_android.dart';
import 'package:health_xiaohe/core/audio/audio_player_stub.dart'
    if (dart.library.html) 'package:health_xiaohe/core/audio/audio_player_web.dart'
    if (dart.library.io) 'package:health_xiaohe/core/audio/audio_player_android.dart';
import 'package:health_xiaohe/core/camera/camera_capture_stub.dart'
    if (dart.library.html) 'package:health_xiaohe/core/camera/camera_capture_web.dart'
    if (dart.library.io) 'package:health_xiaohe/core/camera/camera_capture_android.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/core/storage/local_storage.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_event.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_state.dart';
import 'package:health_xiaohe/presentation/widgets/voice/transcript_card.dart';
import 'package:health_xiaohe/presentation/widgets/voice/voice_avatar.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _cameraCapture = CameraCapture();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _videoEnabled = false;
  bool _callStarted = false;
  bool _audioFlowing = false; // 至少发送过一次音频后才允许发送图像
  int _callDuration = 0;
  Timer? _timer;
  String _aiText = '';
  String _userText = '';
  String? _conversationId;
  VoiceBloc? _voiceBloc;
  VoiceAvatarMode _avatarMode = VoiceAvatarMode.connecting;

  @override
  void initState() {
    super.initState();
    _voiceBloc = context.read<VoiceBloc>();
    _initRecording();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCall());
  }

  void _startCall() {
    final token = GetIt.instance<LocalStorage>().getJwtToken() ?? '';
    final convId = GoRouterState.of(context).uri.queryParameters['conversationId'];
    _voiceBloc?.add(VoiceConnect(token, conversationId: convId));
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

  Future<void> _initRecording() async {
    debugPrint('[CALL] _initRecording enter (user gesture active)');
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      debugPrint('[CALL] hasPermission=$hasPermission');
      if (!hasPermission) {
        debugPrint('[CALL] permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请允许麦克风权限')),
          );
        }
        return;
      }
      debugPrint('[CALL] starting audio recorder...');
      var chunkCount = 0;
      await _audioRecorder.startRecording((base64) {
        chunkCount++;
        if (chunkCount <= 5) debugPrint('[CALL] audio chunk #$chunkCount len=${base64.length}');
        if (_callStarted && !_isMuted) {
          _voiceBloc?.add(VoiceSendAudioChunk(base64));
          if (!_audioFlowing) {
            _audioFlowing = true;
            debugPrint('[CALL] audio flowing, images now allowed');
          }
        }
      });
      debugPrint('[CALL] startRecording completed');
    } catch (e) {
      debugPrint('[CALL] initRecording error: $e');
    }
  }

  Future<void> _startVideo() async {
    try {
      final hasPermission = await _cameraCapture.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请允许摄像头权限')),
          );
        }
        return;
      }
      await _cameraCapture.startCapture((base64Jpeg) {
        if (_audioFlowing) {
          _voiceBloc?.add(VoiceSendImageChunk(base64Jpeg));
        }
      });
      debugPrint('[CALL] video capture started');
    } catch (e) {
      debugPrint('[CALL] startVideo error: $e');
    }
  }

  void _stopVideo() {
    _cameraCapture.stopCapture();
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
    _audioPlayer.dispose();
    _cameraCapture.dispose();
    _voiceBloc?.add(VoiceDisconnect());
    super.dispose();
  }

  void _handleStateChange(VoiceState state) {
    if (state is VoiceConnected && !_callStarted) {
      _callStarted = true;
      _startTimer();
      _audioRecorder.gateOn();
      setState(() => _avatarMode = VoiceAvatarMode.idle);
    } else if (state is VoiceConnected) {
      _audioRecorder.unmute();
      _audioRecorder.gateOn();
      setState(() => _avatarMode = VoiceAvatarMode.idle);
    } else if (state is VoiceListening) {
      _audioRecorder.unmute();
      _audioRecorder.gateOff();
      _audioPlayer.stop();
      setState(() {
        _aiText = '';
        _avatarMode = VoiceAvatarMode.listening;
      });
    } else if (state is VoiceConversationCreated) {
      _conversationId = state.conversationId;
    } else if (state is VoiceUserText) {
      setState(() => _userText = state.text);
    } else if (state is VoiceReceivingText) {
      setState(() {
        _aiText = state.text;
        _avatarMode = VoiceAvatarMode.speaking;
      });
    } else if (state is VoiceReceivingAudio) {
      _audioRecorder.mute();
      _audioPlayer.play(state.audioData);
      setState(() => _avatarMode = VoiceAvatarMode.speaking);
    } else if (state is VoiceProcessingInput) {
      _audioRecorder.mute();
      setState(() => _avatarMode = VoiceAvatarMode.processing);
    } else if (state is VoiceConnecting) {
      setState(() => _avatarMode = VoiceAvatarMode.connecting);
    } else if (state is VoiceDone) {
      _endCall();
    } else if (state is VoiceDisconnected) {
      if (_callStarted) _endCall();
    } else if (state is VoiceErrorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.danger,
        ),
      );
      _endCall();
    }
  }

  String _statusTextFor(VoiceState state) {
    if (state is VoiceConnecting) return '正在连接...';
    if (state is VoiceProcessingInput) return '正在理解...';
    if (state is VoiceListening) return '正在聆听...';
    if (state is VoiceReceivingText || state is VoiceReceivingAudio) {
      return '正在回复';
    }
    if (state is VoiceConnected) {
      return _aiText.isNotEmpty ? '请继续提问' : '已接通，请说话';
    }
    return '准备中...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2A3F),
              Color(0xFF071521),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<VoiceBloc, VoiceState>(
            listener: (context, state) => _handleStateChange(state),
            builder: (context, state) {
              return Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        VoiceAvatar(mode: _avatarMode, size: 132),
                        const SizedBox(height: 28),
                        const Text(
                          '健康小云',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildAnimatedStatus(state),
                        const SizedBox(height: 24),
                        if (_userText.isNotEmpty)
                          TranscriptCard(
                            role: TranscriptRole.user,
                            text: _userText,
                          ),
                        if (_userText.isNotEmpty && _aiText.isNotEmpty)
                          const SizedBox(height: 10),
                        if (_aiText.isNotEmpty)
                          TranscriptCard(
                            role: TranscriptRole.ai,
                            text: _aiText,
                          ),
                      ],
                    ),
                  ),
                  _buildControlButtons(state),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _callStarted ? _formatDuration(_callDuration) : '00:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatus(VoiceState state) {
    final text = _statusTextFor(state);
    final showDots = state is VoiceReceivingText ||
        state is VoiceReceivingAudio ||
        state is VoiceProcessingInput ||
        state is VoiceConnecting;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: Row(
        key: ValueKey(text),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.65),
              letterSpacing: 0.3,
            ),
          ),
          if (showDots) ...[
            const SizedBox(width: 6),
            const _TypingDots(),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButtons(VoiceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CtrlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? '已静音' : '麦克风',
            background: _isMuted
                ? AppColors.danger.withOpacity(0.85)
                : Colors.white.withOpacity(0.12),
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),
          _CtrlButton(
            icon: _videoEnabled ? Icons.videocam : Icons.videocam_off,
            label: _videoEnabled ? '视频中' : '视频',
            background: _videoEnabled
                ? AppColors.primary.withOpacity(0.85)
                : Colors.white.withOpacity(0.12),
            onTap: () {
              setState(() {
                _videoEnabled = !_videoEnabled;
                if (_videoEnabled) {
                  _startVideo();
                } else {
                  _stopVideo();
                }
              });
            },
          ),
          _CtrlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: '扬声器',
            background: _isSpeakerOn
                ? AppColors.primary.withOpacity(0.85)
                : Colors.white.withOpacity(0.12),
            onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
          ),
          _CtrlButton(
            icon: Icons.call_end,
            label: '挂断',
            background: AppColors.danger,
            size: 64,
            iconSize: 28,
            elevated: true,
            onTap: _endCall,
          ),
        ],
      ),
    );
  }

  void _endCall() {
    _stopTimer();
    _callStarted = false;
    _audioRecorder.dispose();
    _audioPlayer.stop();
    _cameraCapture.dispose();
    _voiceBloc?.add(VoiceDisconnect());
    if (mounted) {
      if (_conversationId != null) {
        context.go('/chat?conversationId=$_conversationId');
      } else {
        context.go('/chat');
      }
    }
  }
}

class _CtrlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color background;
  final double size;
  final double iconSize;
  final bool elevated;
  final VoidCallback onTap;

  const _CtrlButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
    this.size = 56,
    this.iconSize = 24,
    this.elevated = false,
  });

  @override
  State<_CtrlButton> createState() => _CtrlButtonState();
}

class _CtrlButtonState extends State<_CtrlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.background,
                shape: BoxShape.circle,
                boxShadow: widget.elevated
                    ? [
                        BoxShadow(
                          color: widget.background.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: widget.iconSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = i / 3;
            final t = ((_controller.value + offset) % 1.0);
            final opacity = (1.0 - (t - 0.5).abs() * 2).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity * 0.8),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
