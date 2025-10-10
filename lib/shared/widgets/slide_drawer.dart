import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../shared/theme/theme_extensions.dart';

class SlideDrawer extends StatefulWidget {
  final Widget child;
  final Widget drawer;
  final double maxFraction; // 0..1 of screen width
  final double edgeFraction; // 0..1 active edge width for open gesture
  final double settleFraction; // threshold to settle open on release
  final Duration duration;
  final Curve curve;
  final Color? scrimColor;
  // When true, opening the drawer pushes the content to the right
  // instead of overlaying above it.
  final bool pushContent;
  // Max scale reduction for pushed content at full open (e.g., 0.02 => 98%).
  final double contentScaleDelta;
  // Max blur sigma applied to pushed content at full open.
  final double contentBlurSigma;

  const SlideDrawer({
    super.key,
    required this.child,
    required this.drawer,
    this.maxFraction = 0.84,
    this.edgeFraction = 0.5,
    this.settleFraction = 0.12,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.fastOutSlowIn,
    this.scrimColor,
    this.pushContent = true,
    this.contentScaleDelta = 0.02,
    this.contentBlurSigma = 2.0,
  });

  static SlideDrawerState? of(BuildContext context) =>
      context.findAncestorStateOfType<SlideDrawerState>();

  @override
  State<SlideDrawer> createState() => SlideDrawerState();
}

class SlideDrawerState extends State<SlideDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 0.0,
  );

  double get _panelWidth =>
      (MediaQuery.of(context).size.width * widget.maxFraction).clamp(
        280.0,
        520.0,
      );

  double get _edgeWidth =>
      MediaQuery.of(context).size.width * widget.edgeFraction;

  bool get isOpen => _controller.value == 1.0;

  Future<void> _animateTo(double target, {double velocity = 0.0}) async {
    final current = _controller.value;
    final distance = (current - target).abs().clamp(0.0, 1.0);
    // Smooth, distance-based duration so snaps don't feel abrupt.
    final baseMs = widget.duration.inMilliseconds;
    final normSpeed = (velocity.abs() / (_panelWidth + 0.001)).clamp(0.0, 4.0);
    // Higher velocity => shorter duration.
    final ms = (baseMs * distance / (1.0 + 1.5 * normSpeed))
        .clamp(90, baseMs)
        .round();
    final curve = target > current
        ? (normSpeed > 0.5 ? Curves.linearToEaseOut : Curves.easeOutCubic)
        : (normSpeed > 0.5 ? Curves.easeInToLinear : Curves.easeInCubic);
    await _controller.animateTo(
      target,
      duration: Duration(milliseconds: ms),
      curve: curve,
    );
  }

  void open({double velocity = 0.0}) => _animateTo(1.0, velocity: velocity);
  void close({double velocity = 0.0}) => _animateTo(0.0, velocity: velocity);
  void toggle() => isOpen ? close() : open();

  double _startValue = 0.0;

  void _onDragStart(DragStartDetails d) {
    _startValue = _controller.value;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.primaryDelta ?? 0.0;
    final next = (_startValue + delta / _panelWidth).clamp(0.0, 1.0);
    _controller.value = next;
    _startValue = next;
  }

  void _onDragEnd(DragEndDetails d) {
    final vx = d.primaryVelocity ?? 0.0;
    final vMag = vx.abs();
    // Fling assistance first.
    if (vMag > 300.0) {
      if (vx > 0) {
        open(velocity: vMag);
      } else {
        close(velocity: vMag);
      }
      return;
    }
    // Gentle settle threshold (less aggressive snap-back).
    if (_controller.value >= widget.settleFraction) {
      open(velocity: vMag);
    } else {
      close(velocity: vMag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final scrim = widget.scrimColor ?? context.colorTokens.overlayStrong;

    return Stack(
      children: [
        // Content (optionally pushed by the drawer)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final dx = (widget.pushContent ? _panelWidth * t : 0.0)
                  .roundToDouble(); // snap to pixel to avoid jitter
              final scale =
                  1.0 -
                  (widget.pushContent
                      ? (widget.contentScaleDelta.clamp(0.0, 0.2) * t)
                      : 0.0);
              final blurSigma =
                  (widget.pushContent
                          ? (widget.contentBlurSigma.clamp(0.0, 8.0) * t)
                          : 0.0)
                      .toDouble();
              Widget content = widget.child;
              if (blurSigma > 0.0) {
                content = ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: content,
                );
              }
              content = Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: content,
              );
              content = Transform.translate(
                offset: Offset(dx, 0),
                child: content,
              );
              return content;
            },
          ),
        ),

        // Edge gesture region to open
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
          ),
        ),

        // Scrim + panel when animating or open
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final ignoring = t == 0.0;
            return IgnorePointer(
              ignoring: ignoring,
              child: Stack(
                children: [
                  // Scrim
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: close,
                      onHorizontalDragStart: _onDragStart,
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: _onDragEnd,
                      child: ColoredBox(
                        color: scrim.withValues(alpha: 0.6 * t),
                      ),
                    ),
                  ),
                  // Panel (capture horizontal drags to close)
                  Positioned(
                    left: -_panelWidth * (1.0 - t),
                    top: 0,
                    bottom: 0,
                    width: _panelWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: _onDragStart,
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: _onDragEnd,
                      child: RepaintBoundary(
                        child: Material(
                          color: theme.surfaceBackground,
                          elevation: 8,
                          child: widget.drawer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
