import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PannableScrollViewMobile extends StatefulWidget {
  final Widget child;
  final ScrollPhysics physics;

  const PannableScrollViewMobile(
      {Key? key,
      this.physics = const BouncingScrollPhysics(),
      required this.child})
      : super(key: key);

  @override
  State<PannableScrollViewMobile> createState() =>
      _PannableScrollViewMobileState();
}

class _PannableScrollViewMobileState extends State<PannableScrollViewMobile> {
  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();
  final Map<Type, GestureRecognizerFactory> gestureRecognizersMap =
      <Type, GestureRecognizerFactory>{};

  @override
  void initState() {
    super.initState();
    gestureRecognizersMap[PanGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(),
            (instance) => instance
              ..onDown = _onDragDown
              ..onStart = _onDragStart
              ..onUpdate = _onDragUpdate
              ..onEnd = _onDragEnd
              ..onCancel = _onDragCancel
              ..minFlingDistance = widget.physics.minFlingDistance
              ..minFlingVelocity = widget.physics.minFlingVelocity
              ..maxFlingVelocity = widget.physics.maxFlingVelocity
              ..velocityTrackerBuilder = ScrollConfiguration.of(context)
                  .velocityTrackerBuilder(context)
              ..dragStartBehavior = DragStartBehavior.start);
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: horizontalController,
            physics: widget.physics,
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: verticalController,
                physics: widget.physics,
                child: widget.child),
          ),
        ),
        Positioned.fill(
            child: RawGestureDetector(
          gestures: gestureRecognizersMap,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
        )),
      ]);

  Drag? _horizontalDrag;
  Drag? _verticalDrag;
  ScrollHoldController? _horizontalScrollHold;
  ScrollHoldController? _verticalScrollHold;

  void _onDragDown(DragDownDetails details) {
    _horizontalScrollHold =
        horizontalController.position.hold(() => _horizontalScrollHold = null);
    _verticalScrollHold =
        verticalController.position.hold(() => _verticalScrollHold = null);
  }

  void _onDragStart(DragStartDetails details) {
    _horizontalDrag = horizontalController.position
        .drag(details, () => _horizontalDrag = null);
    _verticalDrag =
        verticalController.position.drag(details, () => _verticalDrag = null);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _horizontalDrag?.update(
      DragUpdateDetails(
          sourceTimeStamp: details.sourceTimeStamp,
          delta: Offset(details.delta.dx, 0),
          primaryDelta: details.delta.dx,
          globalPosition: details.globalPosition),
    );
    _verticalDrag?.update(DragUpdateDetails(
        sourceTimeStamp: details.sourceTimeStamp,
        delta: Offset(0, details.delta.dy),
        primaryDelta: details.delta.dy,
        globalPosition: details.globalPosition));
  }

  void _onDragEnd(DragEndDetails details) {
    _horizontalDrag?.end(DragEndDetails(
        velocity: details.velocity,
        primaryVelocity: details.velocity.pixelsPerSecond.dx));
    _verticalDrag?.end(DragEndDetails(
        velocity: details.velocity,
        primaryVelocity: details.velocity.pixelsPerSecond.dy));
  }

  void _onDragCancel() {
    _horizontalScrollHold?.cancel();
    _horizontalDrag?.cancel();
    _verticalScrollHold?.cancel();
    _verticalDrag?.cancel();
  }
}
