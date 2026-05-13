import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';

enum VoiceAvatarMode {
  /// 连接中 — 旋转光环
  connecting,

  /// 待机 — 缓慢呼吸
  idle,

  /// 用户说话 — 内聚脉冲
  listening,

  /// AI 处理中 — 快速旋转环
  processing,

  /// AI 说话 — 多层向外涟漪
  speaking,
}

class VoiceAvatar extends StatefulWidget {
  final VoiceAvatarMode mode;
  final double size;

  const VoiceAvatar({
    super.key,
    required this.mode,
    this.size = 140,
  });

  @override
  State<VoiceAvatar> createState() => _VoiceAvatarState();
}

class _VoiceAvatarState extends State<VoiceAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _ripple;
  late final AnimationController _pulse;
  late final AnimationController _rotation;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _applyMode();
  }

  @override
  void didUpdateWidget(covariant VoiceAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _applyMode();
    }
  }

  void _applyMode() {
    switch (widget.mode) {
      case VoiceAvatarMode.speaking:
        _ripple.repeat();
        _pulse.stop();
        _rotation.stop();
        break;
      case VoiceAvatarMode.listening:
        _pulse.repeat(reverse: true);
        _ripple.stop();
        _rotation.stop();
        break;
      case VoiceAvatarMode.processing:
        _rotation.repeat();
        _ripple.stop();
        _pulse.stop();
        break;
      case VoiceAvatarMode.connecting:
        _rotation.repeat();
        _ripple.stop();
        _pulse.stop();
        break;
      case VoiceAvatarMode.idle:
        _ripple.stop();
        _pulse.stop();
        _rotation.stop();
        break;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _ripple.dispose();
    _pulse.dispose();
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = widget.size * 2.2; // 给涟漪留空间
    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _ripple, _pulse, _rotation]),
        builder: (context, _) {
          return CustomPaint(
            painter: _AvatarPainter(
              mode: widget.mode,
              breath: _breath.value,
              ripple: _ripple.value,
              pulse: _pulse.value,
              rotation: _rotation.value,
              coreSize: widget.size,
            ),
            child: Center(
              child: _buildCore(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCore() {
    final scale = 1.0 + (_breath.value - 0.5) * 0.08; // 0.96 ~ 1.04
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '🌿',
            style: TextStyle(fontSize: widget.size * 0.42),
          ),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final VoiceAvatarMode mode;
  final double breath;
  final double ripple;
  final double pulse;
  final double rotation;
  final double coreSize;

  _AvatarPainter({
    required this.mode,
    required this.breath,
    required this.ripple,
    required this.pulse,
    required this.rotation,
    required this.coreSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final coreRadius = coreSize / 2;

    switch (mode) {
      case VoiceAvatarMode.speaking:
        _drawRipples(canvas, center, coreRadius);
        break;
      case VoiceAvatarMode.listening:
        _drawPulse(canvas, center, coreRadius);
        break;
      case VoiceAvatarMode.processing:
      case VoiceAvatarMode.connecting:
        _drawRotatingArc(canvas, center, coreRadius);
        break;
      case VoiceAvatarMode.idle:
        _drawIdleHalo(canvas, center, coreRadius);
        break;
    }
  }

  void _drawIdleHalo(Canvas canvas, Offset center, double r) {
    final t = breath;
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.12 + t * 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * (1.18 + t * 0.04), paint);
  }

  void _drawRipples(Canvas canvas, Offset center, double r) {
    // 三个错位涟漪向外扩散
    for (int i = 0; i < 3; i++) {
      final progress = (ripple + i / 3) % 1.0;
      final radius = r * (1.0 + progress * 1.15);
      final opacity = (1.0 - progress) * 0.55;
      final paint = Paint()
        ..color = AppColors.primary.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 - progress * 2.0;
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawPulse(Canvas canvas, Offset center, double r) {
    // 双层光晕，呼吸式聚拢
    final t = pulse;
    final outerRadius = r * (1.35 - t * 0.1);
    final outerOpacity = 0.18 + t * 0.18;
    final outerPaint = Paint()
      ..color = AppColors.primary.withOpacity(outerOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, outerPaint);

    final innerRadius = r * (1.15 - t * 0.05);
    final innerPaint = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.35 + t * 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  void _drawRotatingArc(Canvas canvas, Offset center, double r) {
    // 旋转的渐变弧线
    final radius = r * 1.22;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          AppColors.primary.withOpacity(0.0),
          AppColors.primary.withOpacity(0.0),
          AppColors.primary.withOpacity(0.6),
          AppColors.primaryDark.withOpacity(0.9),
        ],
        stops: const [0.0, 0.5, 0.85, 1.0],
        transform: GradientRotation(rotation * math.pi * 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) =>
      old.mode != mode ||
      old.breath != breath ||
      old.ripple != ripple ||
      old.pulse != pulse ||
      old.rotation != rotation;
}
