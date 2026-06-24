import 'package:flutter/material.dart';

/// Breakpoints and layout helpers for mobile, tablet, and web.
class Responsive {
  const Responsive._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double maxContentWidth = 1280;

  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) => width(context) < mobile;
  static bool isTablet(BuildContext context) =>
      width(context) >= mobile && width(context) < desktop;
  static bool isDesktop(BuildContext context) => width(context) >= desktop;
  static bool isWide(BuildContext context) => width(context) >= tablet;

  /// Horizontal padding that scales with screen size.
  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  /// Number of columns for IPO grid on wide screens.
  static int gridColumns(BuildContext context) {
    final w = width(context);
    if (w >= desktop) return 3;
    if (w >= tablet) return 2;
    return 1;
  }

  /// Centers content and caps width on large screens.
  static Widget constrain(Widget child, {double? maxWidth}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? maxContentWidth),
        child: child,
      ),
    );
  }

  static T value<T>(BuildContext context,
      {required T mobile, T? tablet, required T desktop}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }
}
