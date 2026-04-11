import 'package:flutter/material.dart';

class NeoBrutalism {
  static const Color background = Color(0xFFF4F4F0);
  static const Color paper = Color(0xFFFFFEF8);
  static const Color ink = Color(0xFF111111);
  static const Color yellow = Color(0xFFFFE44D);
  static const Color cyan = Color(0xFF36D9F6);
  static const Color pink = Color(0xFFFF7BAC);
  static const Color green = Color(0xFF97FF2F);
  static const Color muted = Color(0xFFE7E5DD);

  static const double borderWidth = 2;
  static const double shadowOffset = 4;

  static BoxDecoration card({required Color color}) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: ink, width: borderWidth),
      boxShadow: const [
        BoxShadow(
          color: ink,
          offset: Offset(shadowOffset, shadowOffset),
        ),
      ],
    );
  }

  static BoxDecoration flatCard({required Color color}) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: ink, width: borderWidth),
    );
  }

  static TextStyle get hero => const TextStyle(
        fontSize: 54,
        fontWeight: FontWeight.w900,
        height: 0.92,
        color: ink,
      );

  static TextStyle get title => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: ink,
      );

  static TextStyle get label => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
        color: ink,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: ink,
      );
}
