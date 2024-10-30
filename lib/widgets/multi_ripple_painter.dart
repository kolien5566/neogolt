import 'package:flutter/material.dart';
import 'package:neoglot/language_selection/language_enum.dart';

class MultiRipplePainter extends CustomPainter {
  final List<Ripple> ripples;
  final LanguageEnum language;

  MultiRipplePainter({
    required this.ripples,
    required this.language,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var ripple in ripples) {
      final double progress = ripple.animation.value;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final double maxRadius = size.width / 2;
      double currentRadius;
      double alphaProgress;

      if (ripple.inward) {
        // 波纹向内
        currentRadius = maxRadius * (1 - progress);
        alphaProgress = 1 - progress; // 使用反向进度来计算透明度
      } else {
        // 波纹向外
        currentRadius = maxRadius * progress;
        alphaProgress = progress;
      }

      // 修改透明度计算，始终使外圈更透明
      final double alpha = (1.0 - alphaProgress * alphaProgress).clamp(0.0, 1.0);

      Color baseColor = Colors.blueAccent;
      if ((language == LanguageEnum.CN && ripple.inward) || (language != LanguageEnum.CN && !ripple.inward)) {
        baseColor = Colors.redAccent;
      }
      paint.color = baseColor.withOpacity(alpha * 0.3);

      if (currentRadius > 0) {
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          currentRadius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MultiRipplePainter oldDelegate) {
    return true;
  }
}

class Ripple {
  late AnimationController controller;
  late Animation<double> animation;
  final bool inward;

  Ripple({
    required TickerProvider vsync,
    required Duration duration,
    required this.inward,
  }) {
    controller = AnimationController(vsync: vsync, duration: duration);
    animation = controller;
    controller.forward();
  }

  void dispose() {
    controller.dispose();
  }
}
