import 'package:flutter/material.dart';

abstract final class AppSurfaceTokens {
  static const double pageHorizontalPadding = 20;
  static const double pageBottomPadding = 100;
  static const double sectionGap = 22;
  static const double cardRadius = 18;
  static const double heroRadius = 24;
  static const double compactRadius = 16;

  static BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);

  static BorderRadius get heroBorderRadius => BorderRadius.circular(heroRadius);

  static BorderRadius get compactBorderRadius =>
      BorderRadius.circular(compactRadius);
}
