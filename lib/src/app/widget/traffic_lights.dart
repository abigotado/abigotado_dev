import 'package:abigotado_dev/src/app/theme/app_colors.dart';
import 'package:flutter/widgets.dart';

/// The three macOS-style window-control dots (red / amber / green).
///
/// Extracted from the terminal frame so both the terminal and the editor title
/// bar can share the same widget without duplicating the palette look-up.
class TrafficLights extends StatelessWidget {
  /// Creates the traffic-light dots.
  ///
  /// [dotSize] defaults to 12 px, matching the terminal frame's original size.
  const TrafficLights({this.dotSize = 12, super.key});

  /// Diameter of each dot in logical pixels.
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        _Dot(size: dotSize, color: AppColors.accentRed),
        _Dot(size: dotSize, color: AppColors.accentAmber),
        _Dot(size: dotSize, color: AppColors.accentGreen),
      ],
    );
  }
}

/// A single traffic-light dot.
class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
