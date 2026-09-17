import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/app/navigation_destinations.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/data/sample_data.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

/// Search bar shown below the date on the main dashboard.
class DashboardSearchBar extends StatefulWidget {
  const DashboardSearchBar({super.key});

  @override
  State<DashboardSearchBar> createState() => _DashboardSearchBarState();
}

class _DashboardSearchBarState extends State<DashboardSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_SearchHit> get _hits {
    if (_query.trim().isEmpty) return const [];

    final query = _query.toLowerCase();
    final hits = <_SearchHit>[
      for (final guest in SampleData.guestRecords)
        _SearchHit(
          title: guest.guestName,
          subtitle: 'Room ${guest.roomNumber} · ${guest.bookingId}',
          icon: Icons.person_outline_rounded,
          color: AppColors.infoDark,
          path: AppDestinations.checkIn.path,
        ),
      for (final room in FrontDeskSession.instance.rooms)
        _SearchHit(
          title: 'Room ${room.roomNumber}',
          subtitle: '${room.roomType} · ${roomStatusLabel(room.status)}',
          icon: Icons.meeting_room_outlined,
          color: roomStatusColor(room.status),
          path: AppDestinations.rooms.path,
        ),
      for (final booking in SampleData.existingBookings)
        _SearchHit(
          title: booking.guestName,
          subtitle: 'Reservation · ${booking.roomCode}',
          icon: Icons.calendar_month_outlined,
          color: AppColors.primary,
          path: AppDestinations.booking.path,
        ),
    ];

    return hits
        .where(
          (hit) =>
              hit.title.toLowerCase().contains(query) ||
              hit.subtitle.toLowerCase().contains(query),
        )
        .take(5)
        .toList();
  }

  void _selectHit(_SearchHit hit) {
    _controller.clear();
    setState(() => _query = '');
    _focusNode.unfocus();
    context.go(hit.path);
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search guests, rooms, bookings…',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        if (hits.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 2,
            shadowColor: Colors.black12,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: AppColors.surface,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: hits.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final hit = hits[index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectHit(hit),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: hit.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(hit.icon, size: 16, color: hit.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hit.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  hit.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchHit {
  const _SearchHit({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.path,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String path;
}
