// app_spacing.dart – Design tokens for spacing

import 'package:flutter/widgets.dart';

class AppSpacing {
  // General purpose spacing values (in logical pixels)
  static const double xs = 4.0;   // extra‑small
  static const double sm = 8.0;   // small
  static const double md = 16.0;  // medium (default for many paddings)
  static const double lg = 24.0;  // large
  static const double xl = 32.0;  // extra‑large

  // Shortcut EdgeInsets constructors
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets symmetricHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets symmetricHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets symmetricHorizontalLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets symmetricVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets symmetricVerticalMd = EdgeInsets.symmetric(vertical: md);
}
