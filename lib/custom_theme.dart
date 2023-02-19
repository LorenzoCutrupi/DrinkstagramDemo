import 'dart:ui';

import 'package:flutter/cupertino.dart';

class CustomTheme {
  const CustomTheme();

  static const Color loginGradientStart = Color(0xDD000000);
  static const Color loginGradientEnd = Color(0xFF000000);
  static const Color buttonGradientEnd = Color(0xFFFFC107);
  static const Color buttonGradientStart = Color(0xFFFFCA28);
  static const Color buttonText = Color(0xFFFFA000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[loginGradientStart, loginGradientEnd],
    stops: <double>[0.0, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}