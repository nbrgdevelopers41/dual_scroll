import 'package:flutter/material.dart';

class ScrollBar {
  /// The thickness of this Scrollbar when mouse hovers on this.
  ///
  /// if null, then uses 12px as the default value.
  final double? hoverThickness;

  /// The thickness of this Scrollbar
  ///
  /// if null, Default Thickness: 8px
  final double? thickness;

  /// Determines the Scrollbar Track's visibility.
  final VisibilityOption scrollTrackVisible;

  /// Determines the Scrollbar position pill's visibility.
  final VisibilityOption scrollPillVisible;

  /// The radius of the rounded ends of the Scrollbar's pill.
  final Radius roundedEndsRadius;

  const ScrollBar({
    required this.hoverThickness,
    required this.thickness,
    required this.scrollPillVisible,
    required this.scrollTrackVisible,
    required this.roundedEndsRadius,
  }) : assert(hoverThickness == null || thickness == null
            ? true
            : hoverThickness >= thickness);

  factory ScrollBar.defaultScrollBar() {
    return const ScrollBar(
      hoverThickness: 12.0,
      thickness: 8.0,
      scrollPillVisible: VisibilityOption.onHover,
      scrollTrackVisible: VisibilityOption.onHover,
      roundedEndsRadius: Radius.elliptical(5.0, 5.0),
    );
  }

  factory ScrollBar.showAlways() {
    return const ScrollBar(
      hoverThickness: 12.0,
      thickness: 8.0,
      scrollPillVisible: VisibilityOption.always,
      scrollTrackVisible: VisibilityOption.always,
      roundedEndsRadius: Radius.elliptical(5.0, 5.0),
    );
  }
}

enum VisibilityOption {
  onHover,
  always,
}
