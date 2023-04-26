import 'dart:math';
import "dart:ui" as ui;

import 'package:flutter/material.dart';

enum TooltipDirection { up, down, left, right }

enum ShowCloseButton { inside, outside, none }

enum ClipAreaShape { oval, rectangle }

typedef OutSideTapHandler = void Function();

////////////////////////////////////////////////////////////////////////////////////////////////////
/// Super flexible Tooltip class that allows you to show any content
/// inside a Tooltip in the overlay of the screen.
///
class SuperTooltip {
  /// Allows to accedd the closebutton for UI Testing
  static Key closeButtonKey = const Key("CloseButtonKey");

  /// Signals if the Tooltip is visible at the moment
  bool isOpen = false;

  ///
  /// The content of the Tooltip
  final Widget content;

  ///
  /// The direcion in which the tooltip should open
  TooltipDirection popupDirection;

  ///
  /// optional handler that gets called when the Tooltip is closed
  final OutSideTapHandler? onClose;

  ///
  /// [minWidth], [minHeight], [maxWidth], [maxHeight] optional size constraints.
  /// If a constraint is not set the size will ajust to the content
  double? minWidth, minHeight, maxWidth, maxHeight;

  ///
  /// The minium padding from the Tooltip to the screen limits
  final double minimumOutSidePadding;

  ///
  /// If [snapsFarAwayVertically== true] the bigger free space above or below the target will be
  /// covered completely by the ToolTip. All other dimension or position constraints get overwritten
  final bool snapsFarAwayVertically;

  ///
  /// If [snapsFarAwayHorizontally== true] the bigger free space left or right of the target will be
  /// covered completely by the ToolTip. All other dimension or position constraints get overwritten
  final bool snapsFarAwayHorizontally;

  /// [top], [right], [bottom], [left] position the Tooltip absolute relative to the whole screen
  double? top, right, bottom, left;

  ///
  /// A Tooltip can have none, an inside or an outside close icon
  final ShowCloseButton showCloseButton;

  ///
  /// [hasShadow] defines if the tooltip should have a shadow
  final bool hasShadow;

  ///
  /// The shadow color.
  final Color shadowColor;

  ///
  /// The shadow offset
  final Offset? shadowOffset;

  ///
  /// The shadow blur radius.
  final double shadowBlurRadius;

  ///
  /// The shadow spread radius.
  final double shadowSpreadRadius;

  ///
  /// the stroke width of the border
  final double borderWidth;

  ///
  /// The corder radii of the border
  final double borderRadius;

  ///
  /// The color of the border
  final Color borderColor;

  ///
  /// The color of the close icon
  final Color closeButtonColor;

  ///
  /// The size of the close button
  final double closeButtonSize;

  ///
  /// The icon for the close button
  final IconData closeButtonIcon;

  ///
  /// The length of the Arrow
  final double arrowLength;

  ///
  /// The width of the arrow at its base
  final double arrowBaseWidth;

  ///
  /// The distance of the tip of the arrow's tip to the center of the target
  final double arrowTipDistance;

  ///
  /// The backgroundcolor of the Tooltip
  final Color backgroundColor;

  /// The color of the rest of the overlay surrounding the Tooltip.
  /// typically a translucent color.
  final Color outsideBackgroundColor;

  ///
  /// By default touching the surrounding of the Tooltip closes the tooltip.
  /// you can define a rectangle area where the background is completely transparent
  /// and the widgets below react to touch
  final Rect? touchThrougArea;

  ///
  /// The shape of the [touchThrougArea].
  final ClipAreaShape touchThroughAreaShape;

  ///
  /// If [touchThroughAreaShape] is [ClipAreaShape.rectangle] you can define a border radius
  final double touchThroughAreaCornerRadius;

  ///
  /// Let's you pass a key to the Tooltips cotainer for UI Testing
  final Key? tooltipContainerKey;

  ///
  /// Allow the tooltip to be dismissed tapping outside
  final bool dismissOnTapOutside;

  ///
  /// Block pointer actions or pass them through background
  final bool blockOutsidePointerEvents;

  ///
  /// Enable background overlay
  final bool containsBackgroundOverlay;

  ///
  /// The parameter chooses popupDirection automatically by axis Y
  final bool automaticallyVerticalDirection;

  ///
  /// The parameter enable pop title
  final bool enableTitle;

  ///
  /// The parameter show the title in the tooltip
  final String title;

  ///
  /// arrow distance from center
  final double? arrowFromTopLeft;

  ///
  /// whether arrow should be center or not
  final bool isCenterArrow;

  ///
  /// content's padding
  final EdgeInsets contentPadding;

  Offset? _targetCenter;
  OverlayEntry? _backGroundOverlay;
  OverlayEntry? _ballonOverlay;

  SuperTooltip({
    this.tooltipContainerKey,
    required this.content, // The contents of the tooltip.
    required this.popupDirection,
    this.enableTitle = false,
    this.title = "",
    this.onClose,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.minimumOutSidePadding = 20.0,
    this.showCloseButton = ShowCloseButton.none,
    this.snapsFarAwayVertically = false,
    this.snapsFarAwayHorizontally = false,
    this.hasShadow = true,
    this.shadowColor = Colors.black54,
    this.shadowBlurRadius = 10.0,
    this.shadowSpreadRadius = 5.0,
    this.shadowOffset = Offset.zero,
    this.borderWidth = 2.0,
    this.borderRadius = 10.0,
    this.borderColor = Colors.black,
    this.closeButtonIcon = Icons.close,
    this.closeButtonColor = Colors.black,
    this.closeButtonSize = 30.0,
    this.arrowLength = 20.0,
    this.arrowBaseWidth = 20.0,
    this.arrowTipDistance = 2.0,
    this.backgroundColor = Colors.white,
    this.outsideBackgroundColor = const Color.fromARGB(50, 255, 255, 255),
    this.touchThroughAreaShape = ClipAreaShape.oval,
    this.touchThroughAreaCornerRadius = 5.0,
    this.touchThrougArea,
    this.dismissOnTapOutside = true,
    this.blockOutsidePointerEvents = true,
    this.containsBackgroundOverlay = true,
    this.automaticallyVerticalDirection = false,
    this.arrowFromTopLeft,
    this.isCenterArrow = true,
    this.contentPadding = const EdgeInsets.all(10),
  })  : assert((maxWidth ?? double.infinity) >= (minWidth ?? 0.0)),
        assert((maxHeight ?? double.infinity) >= (minHeight ?? 0.0)),
        assert((isCenterArrow && arrowFromTopLeft == null) ||
            (!isCenterArrow && arrowFromTopLeft != null));

  ///
  /// Removes the Tooltip from the overlay
  void close() {
    if (onClose != null) {
      onClose!();
    }

    _ballonOverlay!.remove();
    _backGroundOverlay?.remove();
    isOpen = false;
  }

  ///
  /// Displays the tooltip
  /// The center of [targetContext] is used as target of the arrow
  ///
  /// Uses [overlay] to show tooltip or [targetContext]'s overlay if [overlay] is null
  void show(BuildContext targetContext, {OverlayState? overlay}) {
    final renderBox = targetContext.findRenderObject() as RenderBox;
    overlay ??= Overlay.of(targetContext);
    final overlayRenderBox = overlay.context.findRenderObject() as RenderBox?;

    _targetCenter = renderBox.localToGlobal(renderBox.size.center(Offset.zero),
        ancestor: overlayRenderBox);

    // Create the background below the popup including the clipArea.
    if (containsBackgroundOverlay) {
      late Widget background;

      var shapeOverlay = _ShapeOverlay(touchThrougArea, touchThroughAreaShape,
          touchThroughAreaCornerRadius, outsideBackgroundColor);
      final backgroundDecoration =
          DecoratedBox(decoration: ShapeDecoration(shape: shapeOverlay));

      if (dismissOnTapOutside && blockOutsidePointerEvents) {
        background = GestureDetector(
          onTap: () => close(),
          child: backgroundDecoration,
        );
      } else if (dismissOnTapOutside && !blockOutsidePointerEvents) {
        background = Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (!(shapeOverlay._getExclusion()?.contains(event.localPosition) ??
                false)) {
              close();
            }
          },
          child: IgnorePointer(child: backgroundDecoration),
        );
      } else if (!dismissOnTapOutside && blockOutsidePointerEvents) {
        background = backgroundDecoration;
      } else if (!dismissOnTapOutside && !blockOutsidePointerEvents) {
        background = IgnorePointer(child: backgroundDecoration);
      } else {
        background = backgroundDecoration;
      }

      _backGroundOverlay = OverlayEntry(
          builder: (context) => _AnimationWrapper(
                builder: (context, opacity) => AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 600),
                  child: background,
                ),
              ));
    }

    if (automaticallyVerticalDirection) {
      if (true) {
        popupDirection = TooltipDirection.up;
      }

      if (_targetCenter!.dy > overlayRenderBox!.size.center(Offset.zero).dy) {
        popupDirection = TooltipDirection.up;
      } else {
        popupDirection = TooltipDirection.down;
      }
    }

    /// Handling snap far away feature.
    if (snapsFarAwayVertically) {
      maxHeight = null;
      left = 0.0;
      right = 0.0;
      if (_targetCenter!.dy > overlayRenderBox!.size.center(Offset.zero).dy) {
        popupDirection = TooltipDirection.up;
        top = 0.0;
      } else {
        popupDirection = TooltipDirection.down;
        bottom = 0.0;
      }
    } // Only one of of them is possible, and vertical has higher priority.
    else if (snapsFarAwayHorizontally) {
      maxWidth = null;
      top = 0.0;
      bottom = 0.0;
      if (_targetCenter!.dx < overlayRenderBox!.size.center(Offset.zero).dx) {
        popupDirection = TooltipDirection.right;
        right = 0.0;
      } else {
        popupDirection = TooltipDirection.left;
        left = 0.0;
      }
    }

    _ballonOverlay = OverlayEntry(
        builder: (context) => _AnimationWrapper(
              builder: (context, opacity) => AnimatedOpacity(
                duration: Duration(
                  milliseconds: 300,
                ),
                opacity: opacity,
                child: Center(
                    child: CustomSingleChildLayout(
                        delegate: _PopupBallonLayoutDelegate(
                            popupDirection: popupDirection,
                            targetCenter: _targetCenter,
                            minWidth: minWidth,
                            maxWidth: maxWidth,
                            minHeight: minHeight,
                            maxHeight: maxHeight,
                            outSidePadding: minimumOutSidePadding,
                            top: top,
                            bottom: bottom,
                            left: left,
                            right: right,
                            arrowFromTopLeft: arrowFromTopLeft,
                            borderRadius: borderRadius,
                            arrowWidth: arrowBaseWidth,
                            isCenterArrow: isCenterArrow),
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            _buildPopUp(),
                            _buildCloseButton(),
                          ],
                        ))),
              ),
            ));

    var overlays = <OverlayEntry>[];

    if (containsBackgroundOverlay) {
      overlays.add(_backGroundOverlay!);
    }
    overlays.add(_ballonOverlay!);

    overlay.insertAll(overlays);
    isOpen = true;
  }

  Widget _buildPopUp() {
    return Positioned(
      child: Container(
        key: tooltipContainerKey,
        decoration: ShapeDecoration(
            color: backgroundColor,
            shadows: hasShadow
                ? [
                    BoxShadow(
                      color: shadowColor,
                      offset: shadowOffset ?? Offset.zero,
                      blurRadius: shadowBlurRadius,
                      spreadRadius: shadowSpreadRadius,
                    )
                  ]
                : null,
            shape: _BubbleShape(
              popupDirection,
              _targetCenter,
              borderRadius,
              arrowBaseWidth,
              arrowTipDistance,
              borderColor,
              borderWidth,
              left,
              top,
              right,
              bottom,
              arrowFromTopLeft ?? 0,
              isCenterArrow,
              contentPadding,
            )),
        margin: _getBallonContainerMargin(),
        child: content,
      ),
    );
  }

  Widget _buildCloseButton() {
    const internalClickAreaPadding = 2.0;

    //
    if (showCloseButton == ShowCloseButton.none) {
      return new SizedBox();
    }

    // ---

    double right;
    double top;

    switch (popupDirection) {
      //
      // LEFT: -------------------------------------
      case TooltipDirection.left:
        right = arrowLength + arrowTipDistance + 3.0;
        if (showCloseButton == ShowCloseButton.inside) {
          top = 2.0;
        } else if (showCloseButton == ShowCloseButton.outside) {
          top = 0.0;
        } else
          throw AssertionError(showCloseButton);
        break;

      // RIGHT/UP: ---------------------------------
      case TooltipDirection.right:
      case TooltipDirection.up:
        right = 5.0;
        if (showCloseButton == ShowCloseButton.inside) {
          top = 2.0;
        } else if (showCloseButton == ShowCloseButton.outside) {
          top = 0.0;
        } else
          throw AssertionError(showCloseButton);
        break;

      // DOWN: -------------------------------------
      case TooltipDirection.down:
        // If this value gets negative the Shadow gets clipped. The problem occurs is arrowlength + arrowTipDistance
        // is smaller than _outSideCloseButtonPadding which would mean arrowLength would need to be increased if the button is ouside.
        right = 2.0;
        if (showCloseButton == ShowCloseButton.inside) {
          top = arrowLength + arrowTipDistance + 2.0;
        } else if (showCloseButton == ShowCloseButton.outside) {
          top = 0.0;
        } else
          throw AssertionError(showCloseButton);
        break;

      // ---------------------------------------------

      default:
        throw AssertionError(popupDirection);
    }

    // ---

    return Positioned(
        right: right,
        top: top,
        child: GestureDetector(
          onTap: close,
          child: Padding(
            padding: const EdgeInsets.all(internalClickAreaPadding),
            child: Icon(
              closeButtonIcon,
              size: closeButtonSize,
              color: closeButtonColor,
            ),
          ),
        ));
  }

  EdgeInsets _getBallonContainerMargin() {
    var top = (showCloseButton == ShowCloseButton.outside)
        ? closeButtonSize + 5
        : 0.0;

    switch (popupDirection) {
      //
      case TooltipDirection.down:
        return EdgeInsets.only(
          top: arrowTipDistance + arrowLength,
        );

      case TooltipDirection.up:
        return EdgeInsets.only(
            bottom: arrowTipDistance + arrowLength, top: top);

      case TooltipDirection.left:
        return EdgeInsets.only(right: arrowTipDistance + arrowLength, top: top);

      case TooltipDirection.right:
        return EdgeInsets.only(left: arrowTipDistance + arrowLength, top: top);

      default:
        throw AssertionError(popupDirection);
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

class _PopupBallonLayoutDelegate extends SingleChildLayoutDelegate {
  final TooltipDirection? _popupDirection;
  final Offset? _targetCenter;
  final double? _minWidth;
  final double? _maxWidth;
  final double? _minHeight;
  final double? _maxHeight;
  final double? _top;
  final double? _bottom;
  final double? _left;
  final double? _right;
  final double? _outSidePadding;
  final double _arrowFromTopLeft;
  final double _borderRadius;
  final double _arrowWidth;
  final bool _isCenterArrow;

  _PopupBallonLayoutDelegate({
    TooltipDirection? popupDirection,
    Offset? targetCenter,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    double? outSidePadding,
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? arrowFromTopLeft,
    double? borderRadius,
    double? arrowWidth,
    required bool isCenterArrow,
  })  : _targetCenter = targetCenter,
        _popupDirection = popupDirection,
        _minWidth = minWidth,
        _maxWidth = maxWidth,
        _minHeight = minHeight,
        _maxHeight = maxHeight,
        _top = top,
        _bottom = bottom,
        _left = left,
        _right = right,
        _outSidePadding = outSidePadding,
        _arrowFromTopLeft = arrowFromTopLeft ?? 0,
        _borderRadius = borderRadius ?? 0,
        _arrowWidth = arrowWidth ?? 0,
        _isCenterArrow = isCenterArrow;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double? calcLeftMostXtoTarget() {
      double? leftMostXtoTarget;
      if (_left != null) {
        leftMostXtoTarget = _left;
      } else if (_right != null) {
        leftMostXtoTarget = max(
            size.topLeft(Offset.zero).dx + _outSidePadding!,
            size.topRight(Offset.zero).dx -
                _outSidePadding! -
                childSize.width -
                _right!);
      } else {
        leftMostXtoTarget = max(
            _outSidePadding!,
            min(
                _targetCenter!.dx - childSize.width / 2,
                size.topRight(Offset.zero).dx -
                    _outSidePadding! -
                    childSize.width));
      }
      return leftMostXtoTarget;
    }

    double? calcTopMostYtoTarget() {
      double? topmostYtoTarget;
      if (_top != null) {
        topmostYtoTarget = _top;
      } else if (_bottom != null) {
        topmostYtoTarget = max(
            size.topLeft(Offset.zero).dy + _outSidePadding!,
            size.bottomRight(Offset.zero).dy -
                _outSidePadding! -
                childSize.height -
                _bottom!);
      } else {
        topmostYtoTarget = max(
            _outSidePadding!,
            min(
                _targetCenter!.dy - childSize.height / 2,
                size.bottomRight(Offset.zero).dy -
                    _outSidePadding! -
                    childSize.height));
      }
      return topmostYtoTarget;
    }

    switch (_popupDirection) {
      case TooltipDirection.down:
        final arrowFromTopLeft = _arrowFromTopLeft > childSize.width
            ? childSize.width
            : _arrowFromTopLeft;
        final awayFromCenter = _isCenterArrow
            ? 0
            : childSize.height / 2 -
                arrowFromTopLeft -
                _borderRadius -
                _arrowWidth / 2;
        return new Offset(
            calcLeftMostXtoTarget()! + awayFromCenter, _targetCenter!.dy);

      case TooltipDirection.up:
        var top = _top ?? _targetCenter!.dy - childSize.height;
        // 만약 센터 화살표가 아니면 이동한 만큼 툴팁의 위치를 옮겨준다.
        final arrowFromTopLeft = _arrowFromTopLeft > childSize.width
            ? childSize.width
            : _arrowFromTopLeft;
        final awayFromCenter = _isCenterArrow
            ? 0
            : childSize.height / 2 -
                arrowFromTopLeft -
                _borderRadius -
                _arrowWidth / 2;
        return new Offset(calcLeftMostXtoTarget()! + awayFromCenter, top);

      case TooltipDirection.left:
        final arrowFromTopLeft = _arrowFromTopLeft > childSize.height
            ? childSize.height
            : _arrowFromTopLeft;
        final awayFromCenter = _isCenterArrow
            ? 0
            : childSize.height / 2 -
                arrowFromTopLeft -
                _borderRadius -
                _arrowWidth / 2;
        var left = _left ?? _targetCenter!.dx - childSize.width;
        return new Offset(left, calcTopMostYtoTarget()! + awayFromCenter);

      case TooltipDirection.right:
        final arrowFromTopLeft = _arrowFromTopLeft > childSize.height
            ? childSize.height
            : _arrowFromTopLeft;
        final awayFromCenter = _isCenterArrow
            ? 0
            : childSize.height / 2 -
                arrowFromTopLeft -
                _borderRadius -
                _arrowWidth / 2;
        return new Offset(
          _targetCenter!.dx,
          calcTopMostYtoTarget()! + awayFromCenter,
        );

      default:
        throw AssertionError(_popupDirection);
    }
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // print("ParentConstraints: $constraints");

    var calcMinWidth = _minWidth ?? 0.0;
    var calcMaxWidth = _maxWidth ?? double.infinity;
    var calcMinHeight = _minHeight ?? 0.0;
    var calcMaxHeight = _maxHeight ?? double.infinity;

    void calcMinMaxWidth() {
      if (_left != null && _right != null) {
        calcMaxWidth = constraints.maxWidth - (_left! + _right!);
      } else if ((_left != null && _right == null) ||
          (_left == null && _right != null)) {
        // make sure that the sum of left, right + maxwidth isn't bigger than the screen width.
        var sideDelta = (_left ?? 0.0) + (_right ?? 0.0) + _outSidePadding!;
        if (calcMaxWidth > constraints.maxWidth - sideDelta) {
          calcMaxWidth = constraints.maxWidth - sideDelta;
        }
      } else {
        if (calcMaxWidth > constraints.maxWidth - 2 * _outSidePadding!) {
          calcMaxWidth = constraints.maxWidth - 2 * _outSidePadding!;
        }
      }
    }

    void calcMinMaxHeight() {
      if (_top != null && _bottom != null) {
        calcMaxHeight = constraints.maxHeight - (_top! + _bottom!);
      } else if ((_top != null && _bottom == null) ||
          (_top == null && _bottom != null)) {
        // make sure that the sum of top, bottom + maxHeight isn't bigger than the screen Height.
        var sideDelta = (_top ?? 0.0) + (_bottom ?? 0.0) + _outSidePadding!;
        if (calcMaxHeight > constraints.maxHeight - sideDelta) {
          calcMaxHeight = constraints.maxHeight - sideDelta;
        }
      } else {
        if (calcMaxHeight > constraints.maxHeight - 2 * _outSidePadding!) {
          calcMaxHeight = constraints.maxHeight - 2 * _outSidePadding!;
        }
      }
    }

    switch (_popupDirection) {
      //
      case TooltipDirection.down:
        calcMinMaxWidth();
        if (_bottom != null) {
          calcMinHeight = calcMaxHeight =
              constraints.maxHeight - _bottom! - _targetCenter!.dy;
        } else {
          calcMaxHeight = min((_maxHeight ?? constraints.maxHeight),
                  constraints.maxHeight - _targetCenter!.dy) -
              _outSidePadding!;
        }
        break;

      case TooltipDirection.up:
        calcMinMaxWidth();

        if (_top != null) {
          calcMinHeight = calcMaxHeight = _targetCenter!.dy - _top!;
        } else {
          calcMaxHeight =
              min((_maxHeight ?? constraints.maxHeight), _targetCenter!.dy) -
                  _outSidePadding!;
        }
        break;

      case TooltipDirection.right:
        calcMinMaxHeight();
        if (_right != null) {
          calcMinWidth =
              calcMaxWidth = constraints.maxWidth - _right! - _targetCenter!.dx;
        } else {
          calcMaxWidth = min((_maxWidth ?? constraints.maxWidth),
                  constraints.maxWidth - _targetCenter!.dx) -
              _outSidePadding!;
        }
        break;

      case TooltipDirection.left:
        calcMinMaxHeight();
        if (_left != null) {
          calcMinWidth = calcMaxWidth = _targetCenter!.dx - _left!;
        } else {
          calcMaxWidth =
              min((_maxWidth ?? constraints.maxWidth), _targetCenter!.dx) -
                  _outSidePadding!;
        }
        break;

      default:
        throw AssertionError(_popupDirection);
    }

    var childConstraints = new BoxConstraints(
        minWidth: calcMinWidth > calcMaxWidth ? calcMaxWidth : calcMinWidth,
        maxWidth: calcMaxWidth,
        minHeight:
            calcMinHeight > calcMaxHeight ? calcMaxHeight : calcMinHeight,
        maxHeight: calcMaxHeight);

    // print("Child constraints: $childConstraints");

    return childConstraints;
  }

  @override
  bool shouldRelayout(SingleChildLayoutDelegate oldDelegate) {
    return false;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

class _BubbleShape extends ShapeBorder {
  final Offset? targetCenter;
  final double arrowBaseWidth;
  final double arrowTipDistance;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final double? left, top, right, bottom;
  final TooltipDirection popupDirection;
  final double arrowFromTopLeft;
  final bool isCenterArrow;
  final EdgeInsets contentPadding;

  _BubbleShape(
    this.popupDirection,
    this.targetCenter,
    this.borderRadius,
    this.arrowBaseWidth,
    this.arrowTipDistance,
    this.borderColor,
    this.borderWidth,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.arrowFromTopLeft,
    this.isCenterArrow,
    this.contentPadding,
  );

  @override
  EdgeInsetsGeometry get dimensions => contentPadding;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return new Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    //
    late double topLeftRadius,
        topRightRadius,
        bottomLeftRadius,
        bottomRightRadius;

    // 상하좌우 맥시멈 끝값
    late double leftEnd, rightEnd, topEnd, bottomEnd;

    // [arrowFromTopLeft]가 적용된 각 상하좌우 맥시멈 끝값
    late double leftWithAFTL, rightWithAFTL, topWithAFTL, bottomWithAFTL;

    // [isCenterArrow]가 적용된 각 상하좌우 끝값
    late double leftWithAutoCenter,
        rightWithAutoCenter,
        topWithAutoCenter,
        bottomWithAutoCenter;

    Path _getLeftTopPath(Rect rect) {
      return new Path()
        ..moveTo(rect.left, rect.bottom - bottomLeftRadius)
        ..lineTo(rect.left, rect.top + topLeftRadius)
        ..arcToPoint(Offset(rect.left + topLeftRadius, rect.top),
            radius: new Radius.circular(topLeftRadius))
        ..lineTo(rect.right - topRightRadius, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + topRightRadius),
            radius: new Radius.circular(topRightRadius), clockwise: true);
    }

    Path _getBottomRightPath(Rect rect) {
      return new Path()
        ..moveTo(rect.left + bottomLeftRadius, rect.bottom)
        ..lineTo(rect.right - bottomRightRadius, rect.bottom)
        ..arcToPoint(Offset(rect.right, rect.bottom - bottomRightRadius),
            radius: new Radius.circular(bottomRightRadius), clockwise: false)
        ..lineTo(rect.right, rect.top + topRightRadius)
        ..arcToPoint(Offset(rect.right - topRightRadius, rect.top),
            radius: new Radius.circular(topRightRadius), clockwise: false);
    }

    topLeftRadius = (left == 0 || top == 0) ? 0.0 : borderRadius;
    topRightRadius = (right == 0 || top == 0) ? 0.0 : borderRadius;
    bottomLeftRadius = (left == 0 || bottom == 0) ? 0.0 : borderRadius;
    bottomRightRadius = (right == 0 || bottom == 0) ? 0.0 : borderRadius;

    // 말풍선에서 각 상하좌우의 보더를 제외한 끝값
    leftEnd = rect.left + topLeftRadius;
    rightEnd = rect.right - bottomRightRadius;
    topEnd = rect.top + topLeftRadius;
    bottomEnd = rect.bottom - bottomLeftRadius;

    // 말풍선에서 arrowFromTopLeft 포함했을때 가질 수 있는 최대 상하좌우값

    // 만약 arrowBaseWidth가 너무 커서 rightEnd - arrowBaseWidth가 왼쪽 끝값을 벗어나는 경우 왼쪽 끝값을 가지도록 한다.
    leftWithAFTL = max(
      leftEnd,
      // 왼쪽끝에서 오른쪽으로 화살표를 움직인 것과, 오른쪽 끝에서 화살표 너비만큼 오른쪽으로 움직인 것중 작은 값을 가져온다.
      // arrowFromTopLeft가 너무 커서 바깥으로 나가는 경우 오른쪽 끝 값을 가지게 하기 위함이다.
      min(
        leftEnd + arrowFromTopLeft,
        rightEnd - arrowBaseWidth,
      ),
    );
    // 왼쪽끝에서 오른쪽으로 화살표를 움직이고, 화살표의 너비만큼 오른쪽으로 움직인 값과, 오른쪽 끝값중 더 작은값을 가지도록 한다.
    // arrowFromTopLeft나 arrowBaseWidth가 너무 커서 오른쪽 끝값을 넘어서는 경우 오른쪽 끝값으로 가지게 하기 위함이다.
    rightWithAFTL = min(rightEnd, leftEnd + arrowFromTopLeft + arrowBaseWidth);
    // arrowBaseWidth가 너무 커서 위쪽 끝값을 넘어서는 경우 위쪽 끝값을 가지도록 하게 한다.
    topWithAFTL = max(
      topEnd,
      // 위쪽 끝에서 아래로 화살표를 움직인 것과, 아래쪽 끝에서 화살표 너비만큼 위로 움직인 것중 작은 값을 가져온다.
      // arrowFromTopLeft가 너무 커서 아래쪽 끝값을 넘어서는 경우 아래쪽 끝값을 가지게 한다.
      min(
        topEnd + arrowFromTopLeft,
        bottomEnd - arrowBaseWidth,
      ),
    );
    // arrowFromTopLeft나 arrowBaseWidth가 너무 큰 경우 아래쪽 끝값을 넘어서는 경우 아래쪽 끝값을 가리키도록 하게 한다.
    bottomWithAFTL = min(bottomEnd, topEnd + arrowFromTopLeft + arrowBaseWidth);

    // 화살표가 자동으로 가운데면 적용되어야 하는 상하좌우 끝값
    leftWithAutoCenter = max(
        min(targetCenter!.dx - arrowBaseWidth / 2, rightEnd - arrowBaseWidth),
        rect.left + topLeftRadius);

    rightWithAutoCenter = min(
        max(targetCenter!.dx + arrowBaseWidth / 2, leftEnd + arrowBaseWidth),
        rect.right - topRightRadius);

    topWithAutoCenter = max(
        min(targetCenter!.dy - arrowBaseWidth / 2, bottomEnd - arrowBaseWidth),
        topEnd);

    bottomWithAutoCenter =
        min(targetCenter!.dy + arrowBaseWidth / 2, bottomEnd + arrowBaseWidth);

    switch (popupDirection) {
      case TooltipDirection.down:
        return _getBottomRightPath(rect)
          ..lineTo(
              isCenterArrow ? rightWithAutoCenter : rightWithAFTL, rect.top)
          ..lineTo(
              isCenterArrow
                  ? targetCenter!.dx
                  : (leftWithAFTL + rightWithAFTL) / 2,
              targetCenter!.dy + arrowTipDistance) // up to arrow tip   \
          ..lineTo(isCenterArrow ? leftWithAutoCenter : leftWithAFTL,
              rect.top) //  down /

          ..lineTo(leftEnd, rect.top)
          ..arcToPoint(Offset(rect.left, topEnd),
              radius: new Radius.circular(topLeftRadius), clockwise: false)
          ..lineTo(rect.left, bottomEnd)
          ..arcToPoint(Offset(leftEnd, rect.bottom),
              radius: new Radius.circular(bottomLeftRadius), clockwise: false);

      case TooltipDirection.up:
        return _getLeftTopPath(rect)
          ..lineTo(rect.right, bottomEnd)
          ..arcToPoint(Offset(rightEnd, rect.bottom),
              radius: new Radius.circular(bottomRightRadius), clockwise: true)
          ..lineTo(
              isCenterArrow ? rightWithAutoCenter : rightWithAFTL, rect.bottom)

          // up to arrow tip   \
          ..lineTo(
              isCenterArrow
                  ? targetCenter!.dx
                  : (leftWithAFTL + rightWithAFTL) / 2,
              targetCenter!.dy - arrowTipDistance)

          //  down /
          ..lineTo(
              isCenterArrow ? leftWithAutoCenter : leftWithAFTL, rect.bottom)
          ..lineTo(leftEnd, rect.bottom)
          ..arcToPoint(Offset(rect.left, bottomEnd),
              radius: new Radius.circular(bottomLeftRadius), clockwise: true)
          ..lineTo(rect.left, topEnd)
          ..arcToPoint(Offset(leftEnd, rect.top),
              radius: new Radius.circular(topLeftRadius), clockwise: true);

      case TooltipDirection.left:
        return _getLeftTopPath(rect)
          ..lineTo(
              rect.right, isCenterArrow ? bottomWithAutoCenter : bottomWithAFTL)
          ..lineTo(
            targetCenter!.dx - arrowTipDistance,
            isCenterArrow
                ? targetCenter!.dy
                : (topWithAFTL + bottomWithAFTL) / 2,
          ) // right to arrow tip   \
          //  left /
          ..lineTo(
            rect.right,
            isCenterArrow ? topWithAutoCenter : topWithAFTL,
          )
          ..lineTo(rect.right, bottomEnd)
          ..arcToPoint(Offset(rightEnd, rect.bottom),
              radius: new Radius.circular(bottomRightRadius), clockwise: true)
          ..lineTo(leftEnd, rect.bottom)
          ..arcToPoint(Offset(rect.left, bottomEnd),
              radius: new Radius.circular(bottomLeftRadius), clockwise: true);

      case TooltipDirection.right:
        return _getBottomRightPath(rect)
          ..lineTo(leftEnd, rect.top)
          ..arcToPoint(Offset(rect.left, topEnd),
              radius: new Radius.circular(topLeftRadius), clockwise: false)
          ..lineTo(
            rect.left,
            isCenterArrow ? bottomWithAutoCenter : bottomWithAFTL,
          )

          //left to arrow tip   /
          ..lineTo(
            targetCenter!.dx + arrowTipDistance,
            isCenterArrow
                ? targetCenter!.dy
                : (topWithAFTL + bottomWithAFTL) / 2,
          )

          //  right \
          ..lineTo(
            rect.left,
            isCenterArrow ? topWithAutoCenter : topWithAFTL,
          )
          ..lineTo(rect.left, bottomEnd)
          ..arcToPoint(Offset(leftEnd, rect.bottom),
              radius: new Radius.circular(bottomLeftRadius), clockwise: false)
          ..moveTo(0, -100);

      default:
        throw AssertionError(popupDirection);
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    var paint = new Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(getOuterPath(rect), paint);
    paint = new Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (right == 0.0) {
      if (top == 0.0 && bottom == 0.0) {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right, rect.top)
              ..lineTo(rect.right, rect.bottom),
            paint);
      } else {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right, rect.top + borderWidth / 2)
              ..lineTo(rect.right, rect.bottom - borderWidth / 2),
            paint);
      }
    }
    if (left == 0.0) {
      if (top == 0.0 && bottom == 0.0) {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.left, rect.top)
              ..lineTo(rect.left, rect.bottom),
            paint);
      } else {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.left, rect.top + borderWidth / 2)
              ..lineTo(rect.left, rect.bottom - borderWidth / 2),
            paint);
      }
    }
    if (top == 0.0) {
      if (left == 0.0 && right == 0.0) {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right, rect.top)
              ..lineTo(rect.left, rect.top),
            paint);
      } else {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right - borderWidth / 2, rect.top)
              ..lineTo(rect.left + borderWidth / 2, rect.top),
            paint);
      }
    }
    if (bottom == 0.0) {
      if (left == 0.0 && right == 0.0) {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right, rect.bottom)
              ..lineTo(rect.left, rect.bottom),
            paint);
      } else {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right - borderWidth / 2, rect.bottom)
              ..lineTo(rect.left + borderWidth / 2, rect.bottom),
            paint);
      }
    }
  }

  @override
  ShapeBorder scale(double t) {
    return new _BubbleShape(
      popupDirection,
      targetCenter,
      borderRadius,
      arrowBaseWidth,
      arrowTipDistance,
      borderColor,
      borderWidth,
      left,
      top,
      right,
      bottom,
      arrowFromTopLeft,
      isCenterArrow,
      contentPadding,
    );
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

class _ShapeOverlay extends ShapeBorder {
  final Rect? clipRect;
  final Color outsideBackgroundColor;
  final ClipAreaShape clipAreaShape;
  final double clipAreaCornerRadius;

  _ShapeOverlay(
    this.clipRect,
    this.clipAreaShape,
    this.clipAreaCornerRadius,
    this.outsideBackgroundColor,
  );

  @override
  EdgeInsetsGeometry get dimensions => new EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return new Path()..addOval(clipRect!);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    var outer = new Path()..addRect(rect);

    final exclusion = _getExclusion();
    if (exclusion == null) {
      return outer;
    } else {
      return Path.combine(ui.PathOperation.difference, outer, exclusion);
    }
  }

  Path? _getExclusion() {
    Path exclusion;
    if (clipRect == null) {
      return null;
    } else if (clipAreaShape == ClipAreaShape.oval) {
      exclusion = new Path()..addOval(clipRect!);
    } else {
      exclusion = new Path()
        ..moveTo(clipRect!.left + clipAreaCornerRadius, clipRect!.top)
        ..lineTo(clipRect!.right - clipAreaCornerRadius, clipRect!.top)
        ..arcToPoint(
            Offset(clipRect!.right, clipRect!.top + clipAreaCornerRadius),
            radius: new Radius.circular(clipAreaCornerRadius))
        ..lineTo(clipRect!.right, clipRect!.bottom - clipAreaCornerRadius)
        ..arcToPoint(
            Offset(clipRect!.right - clipAreaCornerRadius, clipRect!.bottom),
            radius: new Radius.circular(clipAreaCornerRadius))
        ..lineTo(clipRect!.left + clipAreaCornerRadius, clipRect!.bottom)
        ..arcToPoint(
            Offset(clipRect!.left, clipRect!.bottom - clipAreaCornerRadius),
            radius: new Radius.circular(clipAreaCornerRadius))
        ..lineTo(clipRect!.left, clipRect!.top + clipAreaCornerRadius)
        ..arcToPoint(
            Offset(clipRect!.left + clipAreaCornerRadius, clipRect!.top),
            radius: new Radius.circular(clipAreaCornerRadius))
        ..close();
    }
    return exclusion;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
        getOuterPath(rect), new Paint()..color = outsideBackgroundColor);
  }

  @override
  ShapeBorder scale(double t) {
    return new _ShapeOverlay(
        clipRect, clipAreaShape, clipAreaCornerRadius, outsideBackgroundColor);
  }
}

typedef FadeBuilder = Widget Function(BuildContext, double);

////////////////////////////////////////////////////////////////////////////////////////////////////

class _AnimationWrapper extends StatefulWidget {
  final FadeBuilder? builder;

  _AnimationWrapper({this.builder});

  @override
  _AnimationWrapperState createState() => new _AnimationWrapperState();
}

////////////////////////////////////////////////////////////////////////////////////////////////////

class _AnimationWrapperState extends State<_AnimationWrapper> {
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder!(context, opacity);
  }
}

enum SuperTooltipDismissBehaviour { none, onTap, onPointerDown }
