part of '../colors.dart';

/// The brand hue. CarryOn's identity is ink-black surfaces with a leaf
/// green accent for everything "eco" (trees saved, CO2 avoided), so the
/// brand ramp is a warm near-black and the accent ramp is green.
abstract final class _Brand {
  static const Color s50 = Color(0xFFF2F3F5);
  static const Color s400 = Color(0xFF3A3F47);
  static const Color s500 = Color(0xFF1B1F26);
  static const Color s600 = Color(0xFF0E1117);
}

/// The eco accent: leaf green.
abstract final class _Leaf {
  static const Color s50 = Color(0xFFE6F7EF);
  static const Color s100 = Color(0xFFC3EBD6);
  static const Color s500 = Color(0xFF0FA36B);
  static const Color s600 = Color(0xFF0B8557);
  static const Color s900 = Color(0xFF0F2B20);
}

/// The route highlight: sky teal, used for "in transit" and map accents.
abstract final class _Sky {
  static const Color s50 = Color(0xFFE3F5F7);
  static const Color s500 = Color(0xFF3AB0BA);
  static const Color s900 = Color(0xFF0F2E31);
}

/// The gray ramp both modes are built from.
abstract final class _Neutral {
  static const Color s0 = Color(0xFFFFFFFF);
  static const Color s100 = Color(0xFFF4F5F7);
  static const Color s200 = Color(0xFFE8EAEE);
  static const Color s300 = Color(0xFFD9DDE3);
  static const Color s500 = Color(0xFF7C8593);
  static const Color s700 = Color(0xFF4A515C);
  static const Color s800 = Color(0xFF2C3139);
  static const Color s900 = Color(0xFF1B1F26);
  static const Color s950 = Color(0xFF121417);
  static const Color s1000 = Color(0xFF000000);
}

/// Success.
abstract final class _Green {
  static const Color s50 = Color(0xFFEBFBEE);
  static const Color s500 = Color(0xFF2F9E44);
  static const Color s900 = Color(0xFF132A1B);
}

/// Warning.
abstract final class _Amber {
  static const Color s50 = Color(0xFFFFF6DB);
  static const Color s500 = Color(0xFFF59F00);
  static const Color s900 = Color(0xFF2E2510);
}

/// Danger.
abstract final class _Red {
  static const Color s50 = Color(0xFFFFF0F0);
  static const Color s500 = Color(0xFFCB202D);
  static const Color s900 = Color(0xFF2C1517);
}

/// Information.
abstract final class _Blue {
  static const Color s50 = Color(0xFFE7F1FF);
  static const Color s500 = Color(0xFF2F6FE0);
  static const Color s900 = Color(0xFF11293C);
}

/// Purple, for the "picked up" state.
abstract final class _Violet {
  static const Color s50 = Color(0xFFF0EDFF);
  static const Color s500 = Color(0xFF826BFF);
  static const Color s900 = Color(0xFF1E1840);
}
