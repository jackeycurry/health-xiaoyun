import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_state.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_event.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_state.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _callDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  void _startCall() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<VoiceBloc>().add(VoiceConnect(authState.user.id));
    }
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

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _stopTimer();
    context.read<VoiceBloc>().add(VoiceDisconnect());
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
              if (state is VoiceConnected) {
                _startTimer();
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
                  // AI Avatar and info
                  _buildCallStatus(state),
                  const SizedBox(height: 40),
                  // Timer
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
                  // Control buttons
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
    String? aiMessage;

    if (state is VoiceConnected) {
      statusText = '已接听';
    } else if (state is VoiceReceivingText) {
      aiMessage = state.text;
    } else if (state is VoiceDone) {
      statusText = '通话结束';
    }

    return Column(
      children: [
        // Avatar with pulse animation
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
        if (aiMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '健康小荷: $aiMessage',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlButtons(BuildContext context, VoiceState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute button
        _buildControlButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          backgroundColor: _isMuted
              ? AppColors.danger.withOpacity(0.8)
              : Colors.white.withOpacity(0.15),
          onTap: () {
            setState(() => _isMuted = !_isMuted);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isMuted ? '已静音' : '已取消静音'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        const SizedBox(width: 30),
        // End call button
        _buildControlButton(
          icon: Icons.call_end,
          backgroundColor: AppColors.danger,
          size: 72,
          iconSize: 28,
          onTap: _endCall,
        ),
        const SizedBox(width: 30),
        // Speaker button
        _buildControlButton(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
          backgroundColor: _isSpeakerOn
              ? AppColors.primary.withOpacity(0.8)
              : Colors.white.withOpacity(0.15),
          onTap: () {
            setState(() => _isSpeakerOn = !_isSpeakerOn);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isSpeakerOn ? '已开启扬声器' : '已关闭扬声器'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
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
    context.read<VoiceBloc>().add(VoiceDisconnect());
    if (mounted) {
      context.go('/chat');
    }
  }
}
