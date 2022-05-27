import 'dart:ui';

import 'package:flutter/material.dart';

import 'line.dart';

class MyPainter extends CustomPainter {
  final List<Line?> lines;

  MyPainter({
    required this.lines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(Paint()..color = Colors.white);
    for (final Line? line in lines) {
      if (line != null) {
        final myPaint = Paint()
          ..color = line.color.withOpacity(0.1)
          ..strokeWidth = line.width + (line.controller.value * 10)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.darken;

        canvas.drawPoints(PointMode.points, [line.offset], myPaint);

        final Paint water = Paint()
          ..color = Colors.white
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, line.width * 0.1 * line.controller.value);

        final Paint whitePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = line.width * 0.2;

        canvas.drawCircle(
            line.offset, line.width * 0.2 * line.controller.value, water);

        // canvas.drawLine(
        //     line.offset,
        //     Offset(line.offset.dx,
        //         line.offset.dy + (line.width * 0.5 * line.controller.value)),
        //     whitePaint);
      }
    }
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(MyPainter oldDelegate) => false;
}
