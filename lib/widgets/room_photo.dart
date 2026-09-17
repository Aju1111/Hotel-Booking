import 'package:flutter/material.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';

/// Fixed-height room photo — crops with [BoxFit.cover] so cards never overflow.
class RoomPhoto extends StatelessWidget {
  const RoomPhoto({
    super.key,
    required this.imageAsset,
    this.height = 120,
    this.fallbackIcon = Icons.hotel_rounded,
    this.fallbackColor = AppColors.primary,
  });

  final String imageAsset;
  final double height;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(
            color: AppColors.surfaceAlt,
            child: Center(
              child: Icon(fallbackIcon, color: fallbackColor, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
