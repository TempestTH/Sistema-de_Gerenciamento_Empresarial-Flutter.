import 'package:flutter/material.dart';

/// Returns dialog bounds based on the space visible above the on-screen keyboard.
BoxConstraints responsiveDialogConstraints(
  BuildContext context, {
  required double maxWidth,
  double maxHeightFraction = 0.9,
}) {
  final media = MediaQuery.of(context);
  final availableHeight =
      media.size.height - media.viewInsets.bottom - media.padding.vertical - 32;

  return BoxConstraints(
    maxWidth: maxWidth,
    maxHeight: (availableHeight > 0 ? availableHeight : media.size.height * 0.5)
        .clamp(0.0, media.size.height * maxHeightFraction)
        .toDouble(),
  );
}
