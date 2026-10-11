import 'package:flutter/material.dart';

/// Rounded box border that keeps the floating label *inside* the box
/// (as in the Figma design) instead of cutting a gap into the border line
/// like [OutlineInputBorder] does.
class BoxInputBorder extends OutlineInputBorder {
  const BoxInputBorder({super.borderSide, super.borderRadius});

  // Reporting "not outline" makes InputDecorator place the label inside.
  @override
  bool get isOutline => false;

  @override
  BoxInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    return BoxInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  BoxInputBorder scale(double t) => BoxInputBorder(
    borderSide: borderSide.scale(t),
    borderRadius: borderRadius * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is BoxInputBorder) {
      return BoxInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is BoxInputBorder) {
      return BoxInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    // Always paint the full border, never a label gap.
    super.paint(canvas, rect, textDirection: textDirection);
  }
}
