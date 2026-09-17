import 'package:flutter/material.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:hotel_booking/widgets/room_photo.dart';
import 'package:hotel_booking/widgets/ui/app_panel.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

/// Horizontal room card — reads well in a single-column phone list and still
/// works in a two-column tablet grid.
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.isSelected,
    required this.isBooked,
    required this.onTap,
  });

  final HotelRoom room;
  final bool isSelected;
  final bool isBooked;
  final VoidCallback? onTap;

  IconData get _typeIcon => switch (room.roomType) {
    'Executive Suite' => Icons.king_bed_outlined,
    'Family Room' => Icons.family_restroom_outlined,
    _ => Icons.single_bed_outlined,
  };

  Color get _accent => switch (room.roomType) {
    'Executive Suite' => const Color(0xFF7E57C2),
    'Family Room' => const Color(0xFF17A2A2),
    _ => AppColors.infoDark,
  };

  @override
  Widget build(BuildContext context) {
    final enabled = !isBooked && onTap != null;

    return Opacity(
      opacity: isBooked ? 0.65 : 1,
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isBooked
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.border,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected ? AppColors.softShadow : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (room.imageAsset != null) ...[
                  RoomPhoto(
                    imageAsset: room.imageAsset!,
                    fallbackIcon: _typeIcon,
                    fallbackColor: _accent,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    if (room.imageAsset == null)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        child: Icon(_typeIcon, color: _accent, size: 23),
                      ),
                    if (room.imageAsset == null) const SizedBox(width: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                room.code,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 6),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: AppColors.successDark,
                                ),
                            ],
                          ),
                          Text(
                            room.roomType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AppTag(
                        label: isBooked
                            ? 'Booked'
                            : isSelected
                            ? 'Selected'
                            : roomStatusLabel(room.status),
                        color: isBooked
                            ? AppColors.errorDark
                            : isSelected
                            ? AppColors.successDark
                            : roomStatusColor(room.status),
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${Formatters.currency.format(room.pricePerNight)} / night',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: _accent),
                    ),
                    _MetaChip(
                      icon: Icons.people_outline_rounded,
                      label: '${room.maxGuests} guests',
                    ),
                    _MetaChip(
                      icon: Icons.layers_outlined,
                      label: 'Floor ${room.floor}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
