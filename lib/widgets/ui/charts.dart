import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';

/// Animated occupancy ring with the room total in the middle.
class OccupancyDonut extends StatelessWidget {
  const OccupancyDonut({
    super.key,
    required this.percent,
    required this.totalRooms,
    this.size = 132,
  });

  /// 0..100
  final double percent;
  final int totalRooms;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: percent.clamp(0, 100)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(percent: value),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalRooms',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Rooms Total',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${value.toStringAsFixed(0)}% occupied',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.percent});

  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surfaceAlt;

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.info],
      ).createShader(rect);

    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * (percent / 100),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.percent != percent;
}

/// Lightweight bar chart for weekly trends — no external chart package needed.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.highlightIndex,
    this.height = 96,
    this.barColor = AppColors.primary,
  });

  final List<double> values;
  final List<String> labels;
  final int? highlightIndex;
  final double height;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final isHighlight = index == highlightIndex;
          final ratio = maxValue == 0 ? 0.0 : values[index] / maxValue;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: ratio),
                          duration: Duration(
                            milliseconds: 500 + (index * 70),
                          ),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedRatio, _) {
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height:
                                    (constraints.maxHeight * animatedRatio)
                                        .clamp(3.0, constraints.maxHeight),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isHighlight
                                        ? [AppColors.accent, AppColors.accent]
                                        : [
                                            barColor,
                                            barColor.withValues(alpha: 0.45),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color: isHighlight
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isHighlight
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Horizontal stacked bar that summarises room status distribution.
class StatusBreakdownBar extends StatelessWidget {
  const StatusBreakdownBar({super.key, required this.segments});

  /// Ordered list of (label, count, color).
  final List<(String, int, Color)> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.$2);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: SizedBox(
            height: 10,
            child: Row(
              children: segments
                  .where((s) => s.$2 > 0)
                  .map(
                    (s) => Expanded(
                      flex: s.$2,
                      child: Container(color: s.$3),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: segments.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: s.$3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${s.$1} ${s.$2}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
