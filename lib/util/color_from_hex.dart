import 'package:flutter/material.dart';

extension ColorFromHex on String {
  Color toColor() {
    final isValidHex = RegExp(r'^#[0-9a-fA-F]{6}$|^#[0-9a-fA-F]{8}$').hasMatch(this);
    if (!isValidHex) {
      throw FormatException("Invalid hex string: $this");
    }

    Color color;
    if (length == 7) {
      color = Color(int.parse('0xff${substring(1, 7)}'));
    } else if (length == 9) {
      color = Color(int.parse('0x${substring(1, 9)}'));
    } else {
      throw FormatException("Invalid hex string: $this");
    }

    return color;
  }
}

extension ColorToHex on Color {
  String toHex() {
    return '#${value.toRadixString(16).padLeft(8, '0')}';
  }
}
