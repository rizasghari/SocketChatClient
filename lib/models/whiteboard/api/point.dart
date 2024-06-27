import 'dart:ffi';

import 'package:flutter/material.dart';

class Point {
  double x;
  double y;

  Point({required this.x, required this.y});

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  Offset toOffset() {
    return Offset(x, y);
  }

  factory Point.fromOffset(Offset offset) {
    return Point(x: offset.dx, y: offset.dy);
  }

  bool isEndOfSubDrawing() {
    return x == -1 && y == -1;
  }
}
