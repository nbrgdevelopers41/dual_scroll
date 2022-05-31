import 'package:flutter/material.dart';

/// A class to store the setting for [ScrollBar]
class ScrollBarSettings {
  /// Defaults to [ScrollViewKeyboardDismissBehavior.manual]
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// The vertical and horizontal scroll physics. Both Default to [BouncingScrollPhysics]
  final ScrollPhysics verticalPhysics, horizontalPhysics;

  /// The padding between the scrollbar(s) and the child of this widget.
  final EdgeInsetsGeometry? verticalPadding, horizontalPadding;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? verticalRestorationId;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? horizontalRestorationId;

  /// Defaults to [Clip.hardEdge]
  final Clip clipBehavior;

  const ScrollBarSettings({
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.verticalRestorationId,
    this.horizontalRestorationId,
    this.verticalPhysics = const BouncingScrollPhysics(),
    this.horizontalPhysics = const BouncingScrollPhysics(),
    this.verticalPadding,
    this.horizontalPadding,
  });
}
