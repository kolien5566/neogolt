import 'package:flutter/material.dart';

class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double maxRadius;
  final bool shrink;

  RipplePainter({
    required this.animationValue,
    required this.color,
    required this.maxRadius,
    required this.shrink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    double currentRadius = shrink ? maxRadius * (1 - animationValue) : maxRadius * animationValue;

    // 确保半径在合理范围内
    currentRadius = currentRadius.clamp(0.0, maxRadius);

    // 绘制多个圆环，模拟波纹扩散效果
    int rippleCount = 3;
    for (int i = 0; i < rippleCount; i++) {
      double rippleRadius = currentRadius - (currentRadius / rippleCount) * i;
      if (rippleRadius > 0) {
        // 调整透明度，使得更小的圆环更透明
        paint.color = color.withOpacity((shrink ? 1.0 - animationValue : animationValue) * 0.7 * (1 - i / rippleCount));
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          rippleRadius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.maxRadius != maxRadius ||
        oldDelegate.shrink != shrink;
  }
}
