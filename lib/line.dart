import 'package:flutter/material.dart';

class Line {
  final Color color;
  final Offset offset;
  final int width;
  final AnimationController controller;

  const Line({
    required this.color,
    required this.offset,
    required this.width,
    required this.controller,
  });
}
