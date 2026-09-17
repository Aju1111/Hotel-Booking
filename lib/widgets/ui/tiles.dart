import 'package:flutter/material.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';

Color roomStatusColor(RoomStatus status) => switch (status) {
  RoomStatus.available => AppColors.roomAvailable,
  RoomStatus.occupied => AppColors.roomOccupied,
  RoomStatus.dirty => AppColors.roomDirty,
  RoomStatus.maintenance => AppColors.roomMaintenance,
  RoomStatus.blocked => AppColors.roomBlocked,
};

String roomStatusLabel(RoomStatus status) => switch (status) {
  RoomStatus.available => 'Available',
  RoomStatus.occupied => 'Occupied',
  RoomStatus.dirty => 'Dirty',
  RoomStatus.maintenance => 'Maintenance',
  RoomStatus.blocked => 'Blocked',
};

/// Coloured room chip used in the interactive floor view.
class RoomStatusTile extends StatelessWidget {
  const RoomStatusTile({
    super.key,
    required this.roomNumber,
    required this.status,
    required this.selected,
    required this.onTap,
    this.size = 46,
    this.fillWidth = false,
  });

  final int roomNumber;
  final RoomStatus status;
  final bool selected;
  final VoidCallback onTap;
  final double size;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final color = roomStatusColor(status);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Room $roomNumber, ${roomStatusLabel(status)}',
      child: AnimatedScale(
        scale: selected ? 1.06 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: fillWidth ? double.infinity : size,
              height: size * 0.78,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: selected
                    ? Border.all(color: Colors.white, width: 2)
                    : Border.all(color: Colors.white.withValues(alpha: 0.18)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                '$roomNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size < 34 ? 10 : 11.5,
                  letterSpacing: -0.2,
                  shadows: const [
                    Shadow(color: Color(0x33000000), blurRadius: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + label tile for the dashboard module launcher.
class ModuleTile extends StatefulWidget {
  static const gridHeight = 96.0;

  const ModuleTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  State<ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<ModuleTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, size: 22, color: widget.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (widget.badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        widget.badge!,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold room-number badge used in lists and headers.
class RoomNumberBadge extends StatelessWidget {
  const RoomNumberBadge({
    super.key,
    required this.roomNumber,
    this.dense = false,
  });

  final int roomNumber;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentLight.withValues(alpha: 0.75),
            AppColors.accent.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bed_outlined,
            size: dense ? 13 : 15,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 5),
          Text(
            '$roomNumber',
            style: TextStyle(
              fontSize: dense ? 12 : 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
