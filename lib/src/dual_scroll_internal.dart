import 'package:dual_scroll/src/pannable_scroll_view_mobile.dart';
import 'package:dual_scroll/src/scrollbar.dart';
import 'package:dual_scroll/src/scrollbar_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scrolls Horizontally Or Vertically the [child], Independent/Dependant of Platform, which can be controlled by [isPlatformIndependent]
class DualScroll extends StatefulWidget {
  /// The controller for the vertical scrollable view, useful when using [DualScroll] with a ListView/GridView as the child
  final ScrollController? verticalScrollController;

  /// The controller for the horizontal scrollable view, useful when using [DualScroll] with a ListView/GridView as the child
  final ScrollController? horizontalScrollController;

  /// The vertical Scrollbar
  final ScrollBar verticalScrollBar;

  /// The horizontal scroll bar
  final ScrollBar horizontalScrollBar;

  /// The child which will be scrolled horizontally and vertically.
  final Widget child;

  /// The pill color.
  final Color? pillColor;

  /// The dimmed color for the pill
  final Color? dimmedPillColor;

  /// The color of the track.
  final Color? trackColor;

  /// The color when a mouse hovers on the scrollbar(s)/pill(s)
  final Color? hoverColor;

  /// The color when the track is dimmed/Not hovered upon
  final Color? trackColorDimmed;

  /// The settings for the scrollbar
  final ScrollBarSettings settings;

  /// Defines whether the returned widget implementation contains panning/scrolling based on the platform or not.
  final bool isPlatformIndependent;

  const DualScroll({
    Key? key,
    required this.child,
    required this.verticalScrollBar,
    required this.horizontalScrollBar,
    this.isPlatformIndependent = false,
    this.verticalScrollController,
    this.horizontalScrollController,
    this.pillColor,
    this.dimmedPillColor,
    this.trackColor,
    this.trackColorDimmed,
    this.hoverColor,
    this.settings = const ScrollBarSettings(),
  }) : super(key: key);

  @override
  State<DualScroll> createState() =>
      // ignore: no_logic_in_create_state
      isPlatformIndependent
          ? _DualScrollState()
          : isMobile()
              ? _MobileDualScrollState()
              : _DualScrollState();

  bool isMobile() => (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS);
}

class _DualScrollState extends State<DualScroll> {
  late ScrollController horizontalScrollController = ScrollController();
  late ScrollController verticalScrollController = ScrollController();

  double? width = 0;
  double? height = 0;
  double prevWidth = 0;
  double prevHeight = 0;
  double? horizCompleteSize = 0;
  double? vertCompleteSize = 0;

  final _horizTrackKey = GlobalKey();
  final _vertTrackKey = GlobalKey();

  bool isHorizontalHovering = false;
  bool isVerticalHovering = false;

  double? horizpillCurrentTravel = 0;
  double? vertpillCurrentTravel = 0;

  double _horizVP = 0;
  double _vertVP = 0;
  double _horizMaxExt = 0.1;
  double _vertMaxExt = 0.1;
  double _horizPillSize = 60;
  double _vertPillSize = 60;

  late ScrollBarSettings scrollBarSettings;

  late ScrollBar horizontalScrollBar, verticalScrollBar;

  ScrollBar getScrollBar(Axis orientation) =>
      orientation == Axis.horizontal ? horizontalScrollBar : verticalScrollBar;

  @override
  void initState() {
    super.initState();

    scrollBarSettings = widget.settings;

    horizontalScrollBar = widget.horizontalScrollBar;
    verticalScrollBar = widget.verticalScrollBar;

    horizontalScrollController =
        widget.horizontalScrollController ?? ScrollController();
    verticalScrollController =
        widget.verticalScrollController ?? ScrollController();

    horizontalScrollController
        .addListener(() => updatePillPositionWhenScrolled(Axis.horizontal));
    verticalScrollController
        .addListener(() => updatePillPositionWhenScrolled(Axis.vertical));

    horizontalScrollController.addListener(() => _refreshValues());

    verticalScrollController.addListener(() => _refreshValues());
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    if (width != prevWidth || height != prevHeight) {
      Future.delayed(Duration.zero, () {
        setState(() {
          _initializeController(Axis.vertical);
          _initializeController(Axis.horizontal);
          _keepPillInCheckWhenScreenResized(Axis.vertical);
          _keepPillInCheckWhenScreenResized(Axis.horizontal);
        });
      });
      prevHeight = height!;
      prevWidth = width!;
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            clipBehavior: scrollBarSettings.clipBehavior,
            dragStartBehavior: DragStartBehavior.start,
            keyboardDismissBehavior: scrollBarSettings.keyboardDismissBehavior,
            restorationId: scrollBarSettings.verticalRestorationId,
            padding: scrollBarSettings.verticalPadding,
            physics: scrollBarSettings.verticalPhysics,
            scrollDirection: Axis.vertical,
            controller: _getController(Axis.vertical),
            child: SingleChildScrollView(
              clipBehavior: scrollBarSettings.clipBehavior,
              dragStartBehavior: DragStartBehavior.start,
              keyboardDismissBehavior:
                  scrollBarSettings.keyboardDismissBehavior,
              restorationId: scrollBarSettings.horizontalRestorationId,
              padding: scrollBarSettings.horizontalPadding,
              physics: scrollBarSettings.horizontalPhysics,
              scrollDirection: Axis.horizontal,
              controller: _getController(Axis.horizontal),
              child: widget.child,
            ),
          ),
        ),
        _horizVP <= _horizMaxExt
            ? const SizedBox(
                width: 0,
                height: 0,
              )
            : _getScrollBarTrack(
                orientation: Axis.horizontal,
                trackColor: widget.trackColor,
                dimmedColor: widget.trackColorDimmed,
              ),
        _horizVP == _horizMaxExt
            ? const SizedBox(
                width: 0,
                height: 0,
              )
            : _getScrollablePill(orientation: Axis.horizontal),
        _vertVP == _vertMaxExt
            ? const SizedBox(
                width: 0,
                height: 0,
              )
            : _getScrollBarTrack(
                orientation: Axis.vertical,
                trackColor: widget.trackColor,
                dimmedColor: widget.trackColorDimmed,
              ),
        _vertVP == _vertMaxExt
            ? const SizedBox(
                width: 0,
                height: 0,
              )
            : _getScrollablePill(orientation: Axis.vertical),
      ],
    );
  }

  /// Refreshes the controller values in order to avoid using stale values.
  _refreshValues() {
    /// If condition checks whether the scroll controller is attached or not
    if (_getController(Axis.horizontal).hasClients) {
      var controller = _getController(Axis.horizontal);
      horizCompleteSize = controller.position.maxScrollExtent;
      _horizMaxExt = (controller.position.viewportDimension +
          controller.position.maxScrollExtent);
      _horizVP = controller.position.viewportDimension;
      _horizPillSize = _getPillSize(Axis.horizontal);
    }

    /// If condition checks whether the scroll controller is attached or not
    if (_getController(Axis.vertical).hasClients) {
      var controller = _getController(Axis.vertical);
      vertCompleteSize = controller.position.maxScrollExtent;
      _vertMaxExt = (controller.position.viewportDimension +
          controller.position.maxScrollExtent);
      _vertVP = controller.position.viewportDimension;
      _vertPillSize = _getPillSize(Axis.vertical);
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.horizontalScrollController != null
        ? widget.horizontalScrollController?.dispose()
        : horizontalScrollController.dispose();
    horizontalScrollController.dispose();

    widget.verticalScrollController != null
        ? widget.verticalScrollController?.dispose()
        : verticalScrollController.dispose();
    verticalScrollController.dispose();
  }

  updatePillPositionWhenScrolled(Axis orientation) {
    ScrollController controller = _getController(orientation);
    setState(() {
      if (orientation == Axis.horizontal) {
        horizpillCurrentTravel = (controller.offset) / getRatio(orientation);
      } else {
        vertpillCurrentTravel =
            (controller.position.pixels) / getRatio(orientation);
      }
    });
  }

  double getRatio(Axis orientation) {
    ScrollController? controller = _getController(orientation);
    return (controller.position.maxScrollExtent /
        (controller.position.viewportDimension - _getPillSize(orientation)));
  }

  double _getPillSize(Axis orientation) {
    ScrollController? controller = _getController(orientation);

    double size = (controller.position.viewportDimension /
            (controller.position.maxScrollExtent -
                controller.position.minScrollExtent +
                controller.position.viewportDimension)) *
        controller.position.viewportDimension;

    if (size < 60) {
      return 60.0;
    } else {
      return size;
    }
  }

  double _getViewPort(Axis orientation) =>
      _getController(orientation).position.viewportDimension;

  // double _getTotalScrollableSize(Axis orientation) =>
  //     _getController(orientation).position.maxScrollExtent;

  // double _jumpTo(delta, Axis orientation) =>
  //     (delta * getRatio) + _getController(orientation).offset;

  // double _getTrackLength(Axis orientation) => orientation == Axis.horizontal
  //     ? _horizTrackKey.currentContext!.size!.width
  //     : _vertTrackKey.currentContext!.size!.width;

  void _onDragUpdate(DragUpdateDetails duDetails, {required Axis orientation}) {
    if (orientation == Axis.horizontal) {
      if (0 > horizpillCurrentTravel!) {
        horizpillCurrentTravel = 0;
      } else if (horizpillCurrentTravel! >
          _getViewPort(orientation) - _getPillSize(orientation)) {
        horizpillCurrentTravel =
            _getViewPort(orientation) - _getPillSize(orientation);
      } else if (0 <= horizpillCurrentTravel! &&
          horizpillCurrentTravel! <=
              _getViewPort(orientation) - _getPillSize(orientation)) {
        horizpillCurrentTravel = horizpillCurrentTravel! + duDetails.delta.dx;
        if (horizpillCurrentTravel! != 0 ||
            horizpillCurrentTravel! !=
                _getViewPort(orientation) - _getPillSize(orientation)) {
          _getController(orientation)
              .jumpTo(horizpillCurrentTravel! * getRatio(orientation));
        }
      }
    } else {
      if (vertpillCurrentTravel! < 0) {
        vertpillCurrentTravel = 0;
      } else if (vertpillCurrentTravel! >
          _getViewPort(orientation) - _getPillSize(orientation)) {
        vertpillCurrentTravel =
            _getViewPort(orientation) - _getPillSize(orientation);
      } else if (vertpillCurrentTravel! >= 0 &&
          vertpillCurrentTravel! <=
              _getViewPort(orientation) - _getPillSize(orientation)) {
        vertpillCurrentTravel = vertpillCurrentTravel! + duDetails.delta.dy;
        if (vertpillCurrentTravel! != 0 ||
            vertpillCurrentTravel! !=
                _getViewPort(orientation) - _getPillSize(orientation)) {
          _getController(orientation)
              .jumpTo(vertpillCurrentTravel! * getRatio(orientation));
        }
      }
    }
  }

  void _onTapTrack(TapDownDetails tapDownDetails, {required Axis orientation}) {
    double horizTrackLengthFromPillPosition =
        horizpillCurrentTravel! + _horizPillSize;
    double vertTrackLengthFromPillPosition =
        vertpillCurrentTravel! + _vertPillSize;

    if (orientation == Axis.horizontal) {
      if (tapDownDetails.localPosition.dx > horizpillCurrentTravel!) {
        if (horizTrackLengthFromPillPosition < _horizVP - _horizPillSize) {
          horizpillCurrentTravel = horizpillCurrentTravel! + _horizPillSize;
          horizontalScrollController.animateTo(
              horizpillCurrentTravel! * getRatio(orientation),
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.linear);
        } else {
          horizpillCurrentTravel = _horizVP - _horizPillSize;
          horizontalScrollController.animateTo(
              horizpillCurrentTravel! * getRatio(orientation),
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.linear);
        }
      } else if (tapDownDetails.localPosition.dx < horizpillCurrentTravel!) {
        if (horizpillCurrentTravel! > _horizPillSize) {
          horizpillCurrentTravel = horizpillCurrentTravel! - _horizPillSize;
          horizontalScrollController.animateTo(
              horizpillCurrentTravel! * getRatio(orientation),
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.linear);
        } else if (horizpillCurrentTravel! < _horizPillSize) {
          horizpillCurrentTravel = 0;
          horizontalScrollController.animateTo(
              horizpillCurrentTravel! * getRatio(orientation),
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.linear);
        }
      }
    } else {
      if (tapDownDetails.localPosition.dy > vertpillCurrentTravel!) {
        if (vertTrackLengthFromPillPosition < _vertVP - _vertPillSize) {
          vertpillCurrentTravel = vertpillCurrentTravel! + _vertPillSize;
          verticalScrollController.animateTo(
              vertpillCurrentTravel! * getRatio(orientation),
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.linear);
        } else {
          vertpillCurrentTravel = _vertVP - _vertPillSize;
          verticalScrollController.animateTo(
              vertpillCurrentTravel! * getRatio(orientation),
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.linear);
        }
      } else if (tapDownDetails.localPosition.dy < vertpillCurrentTravel!) {
        if (vertpillCurrentTravel! > _vertPillSize) {
          vertpillCurrentTravel = vertpillCurrentTravel! - _vertPillSize;
          verticalScrollController.animateTo(
              vertpillCurrentTravel! * getRatio(orientation),
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.linear);
        } else if (vertpillCurrentTravel! < _vertPillSize) {
          vertpillCurrentTravel = 0;
          verticalScrollController.animateTo(
              vertpillCurrentTravel! * getRatio(orientation),
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.linear);
        }
      }
    }
  }

  void _keepPillInCheckWhenScreenResized(Axis orientation) {
    bool ishoriz = orientation == Axis.horizontal ? true : false;
    double pillCurrentPosition =
        ishoriz ? horizpillCurrentTravel! : vertpillCurrentTravel!;

    if (pillCurrentPosition >
        _getViewPort(orientation) - _getPillSize(orientation)) {
      pillCurrentPosition =
          _getViewPort(orientation) - _getPillSize(orientation);
      _getController(orientation)
          .jumpTo(pillCurrentPosition * getRatio(orientation));
    }
  }

  void _initializeController(Axis orientation) {
    bool ishoriz = orientation == Axis.horizontal ? true : false;
    ScrollController controller = _getController(orientation);
    if (ishoriz) {
      horizCompleteSize = controller.position.maxScrollExtent;
      _horizMaxExt = (controller.position.viewportDimension +
          controller.position.maxScrollExtent);
      _horizVP = controller.position.viewportDimension;
      _horizPillSize = _getPillSize(orientation);
    } else {
      vertCompleteSize = controller.position.maxScrollExtent;
      _vertMaxExt = (controller.position.viewportDimension +
          controller.position.maxScrollExtent);
      _vertVP = controller.position.viewportDimension;
      _vertPillSize = _getPillSize(orientation);
    }
  }

  ScrollController _getController(Axis orientation) =>
      orientation == Axis.vertical
          ? verticalScrollController
          : horizontalScrollController;

  BorderRadiusGeometry _getPillEndsRadius({required ScrollBar scrollbar}) =>
      BorderRadius.all(scrollbar.roundedEndsRadius);

  Color _getPillColor({
    required ScrollBar scrollbar,
    required bool isHovering,
    required Axis orientation,
  }) {
    Color normalColor = widget.pillColor ?? const Color(0xE41A1A1A);
    Color dimColor = widget.dimmedPillColor ?? const Color(0x9F181818);

    if (scrollbar.scrollPillVisible == VisibilityOption.onHover ||
        scrollbar.scrollTrackVisible == VisibilityOption.onHover) {
      return isHovering ? widget.hoverColor ?? normalColor : dimColor;
    } else if (scrollbar.scrollPillVisible == VisibilityOption.onHover) {
      return dimColor;
    } else if (scrollbar.scrollPillVisible == VisibilityOption.always) {
      return normalColor;
    } else {
      return normalColor;
    }
  }

  Widget _getScrollBarTrack({
    required Axis orientation,
    Color? trackColor,
    Color? dimmedColor,
    Color? borderColor,
  }) {
    ScrollBar scrollbar = getScrollBar(orientation);
    bool? ishoriz = Axis.horizontal == orientation ? true : false;

    Color internalTrackColor = trackColor ?? Colors.black.withOpacity(0.03);
    Color internalBorderColor = borderColor ?? Colors.black.withOpacity(0.083);
    dimmedColor = dimmedColor ?? Colors.black.withOpacity(0.02);

    Widget getScrollTrackWidget({
      bool isOnTapScroll = true,
      required Color color,
      required Color borderColor,
      double padding = 2,
    }) =>
        GestureDetector(
          onTapDown: (tapDown) => isOnTapScroll
              ? _onTapTrack(tapDown, orientation: orientation)
              : null,
          child: InkWell(
            onHover: (hover) => setState(() => ishoriz
                ? isHorizontalHovering = hover
                : isVerticalHovering = hover),
            onTap: () {},
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                  vertical: ishoriz ? padding : 0,
                  horizontal: !ishoriz ? padding : 0),
              decoration: BoxDecoration(
                  color: color,
                  border: Border(
                      left: !ishoriz
                          ? BorderSide(width: 0.8, color: borderColor)
                          : const BorderSide(
                              width: 0, color: Colors.transparent),
                      top: ishoriz
                          ? BorderSide(width: 0.8, color: borderColor)
                          : const BorderSide(
                              width: 0, color: Colors.transparent))),
              key: ishoriz ? _horizTrackKey : _vertTrackKey,
              width: !ishoriz
                  ? isVerticalHovering
                      ? scrollbar.hoverThickness! + padding * 1.4
                      : scrollbar.thickness! + padding * 1.4
                  : null,
              height: ishoriz
                  ? isHorizontalHovering
                      ? scrollbar.hoverThickness! + padding * 1.4
                      : scrollbar.thickness! + padding * 1.4
                  : null,
            ),
          ),
        );

    switch (orientation) {
      case Axis.vertical:
        switch (scrollbar.scrollTrackVisible) {
          case VisibilityOption.onHover:
            return getScrollTrackWidget(
              color: isVerticalHovering ? internalTrackColor : dimmedColor,
              borderColor:
                  isVerticalHovering ? internalBorderColor : dimmedColor,
            );

          case VisibilityOption.always:
            return getScrollTrackWidget(
              color: internalTrackColor,
              borderColor: internalBorderColor,
            );
        }

      case Axis.horizontal:
        switch (scrollbar.scrollTrackVisible) {
          case VisibilityOption.onHover:
            return getScrollTrackWidget(
              color: isHorizontalHovering ? internalTrackColor : dimmedColor,
              borderColor:
                  isHorizontalHovering ? internalBorderColor : dimmedColor,
            );

          case VisibilityOption.always:
            return getScrollTrackWidget(
              color: internalTrackColor,
              borderColor: internalBorderColor,
            );
        }
    }
  }

  Widget _getScrollablePill({
    required Axis orientation,
  }) {
    ScrollBar scrollbar = getScrollBar(orientation);
    bool ishoriz = orientation == Axis.horizontal ? true : false;
    bool trackHover = ishoriz ? isHorizontalHovering : isVerticalHovering;
    double? _pillThickness() =>
        trackHover ? scrollbar.hoverThickness : scrollbar.thickness;

    Widget position = Positioned(
      top: ishoriz ? null : vertpillCurrentTravel,
      bottom: ishoriz ? 1 : null,
      left: !ishoriz ? null : horizpillCurrentTravel,
      right: !ishoriz ? 1 : null,
      child: SizedBox(
          height: ishoriz
              ? _pillThickness()
              : _vertPillSize < 60
                  ? 60
                  : _vertPillSize,
          width: !ishoriz
              ? _pillThickness()
              : _horizPillSize < 60
                  ? 60
                  : _horizPillSize,
          child: GestureDetector(
            onPanUpdate: (drag) =>
                _onDragUpdate(drag, orientation: orientation),
            child: InkWell(
              onHover: (hover) {
                setState(() {
                  ishoriz
                      ? isHorizontalHovering = hover
                      : isVerticalHovering = hover;
                });
              },
              autofocus: true,
              enableFeedback: true,
              excludeFromSemantics: true,
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: _getPillEndsRadius(scrollbar: scrollbar),
                  color: _getPillColor(
                    scrollbar: scrollbar,
                    isHovering:
                        ishoriz ? isHorizontalHovering : isVerticalHovering,
                    orientation: orientation,
                  ),
                ),
              ),
            ),
          )),
    );

    return position;
  }
}

class _MobileDualScrollState extends State<DualScroll> {
  @override
  Widget build(BuildContext context) {
    return PannableScrollViewMobile(child: widget.child);
  }
}
