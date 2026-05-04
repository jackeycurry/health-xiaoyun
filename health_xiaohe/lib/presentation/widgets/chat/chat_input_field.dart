import 'package:flutter/material.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback? onVoicePressed;
  final VoidCallback? onHealthRecordPressed;
  final VoidCallback? onCallPressed;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    this.onVoicePressed,
    this.onHealthRecordPressed,
    this.onCallPressed,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();
  bool _isRecording = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Health record quick add button
            GestureDetector(
              onTap: widget.onHealthRecordPressed,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.favorite_outline,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Text input
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: '请输入您的健康问题...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    suffixIcon: GestureDetector(
                      onTapDown: (_) => _startRecording(),
                      onTapUp: (_) => _stopRecording(),
                      onTapCancel: () => _stopRecording(),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: _isRecording ? AppColors.danger : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Send button
            GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Call button
            GestureDetector(
              onTap: widget.onCallPressed,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    widget.onSendMessage(text);
    _controller.clear();
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    widget.onVoicePressed?.call();
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
  }
}
