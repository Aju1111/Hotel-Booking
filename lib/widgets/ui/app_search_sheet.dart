import 'package:flutter/material.dart';
import 'package:hotel_booking/app/navigation_destinations.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/data/sample_data.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/widgets/ui/state_views.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

/// Opens the global search as a bottom sheet — the mobile equivalent of the
/// desktop search bar in the top navigation.
Future<void> showAppSearchSheet(
  BuildContext context, {
  required ValueChanged<String> onNavigate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _SearchSheet(onNavigate: onNavigate),
  );
}

class _SearchResult {
  const _SearchResult({
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

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SearchResult> get _allResults {
    return [
      for (final guest in SampleData.guestRecords)
        _SearchResult(
          title: guest.guestName,
          subtitle: 'Room ${guest.roomNumber} · ${guest.bookingId}',
          icon: Icons.person_outline_rounded,
          color: AppColors.infoDark,
          path: AppDestinations.checkIn.path,
        ),
      for (final room in FrontDeskSession.instance.rooms)
        _SearchResult(
          title: 'Room ${room.roomNumber}',
          subtitle: '${room.roomType} · ${roomStatusLabel(room.status)}',
          icon: Icons.meeting_room_outlined,
          color: roomStatusColor(room.status),
          path: AppDestinations.rooms.path,
        ),
      for (final booking in SampleData.existingBookings)
        _SearchResult(
          title: booking.guestName,
          subtitle: 'Reservation · ${booking.roomCode}',
          icon: Icons.calendar_month_outlined,
          color: AppColors.primary,
          path: AppDestinations.booking.path,
        ),
    ];
  }

  List<_SearchResult> get _results {
    if (_query.trim().isEmpty) return const [];
    final query = _query.toLowerCase();
    return _allResults
        .where(
          (r) =>
              r.title.toLowerCase().contains(query) ||
              r.subtitle.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search guests, rooms, reservations…',
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
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              if (_query.trim().isEmpty)
                const _SearchSuggestions()
              else if (results.isEmpty)
                const EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No matches found',
                  message: 'Try a guest name, room number or booking ID.',
                  compact: true,
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final result = results[index];

                      return Material(
                        color: AppColors.surfaceAlt.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMd,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onNavigate(result.path);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: result.color.withValues(
                                      alpha: 0.16,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    result.icon,
                                    size: 17,
                                    color: result.color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        result.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      Text(
                                        result.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: AppColors.textSecondary,
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
          ),
        ),
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions();

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'Mathew Hyden',
      'Room 101',
      'Sarah Thompson',
      'BK-1021',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent searches', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map((s) => Chip(label: Text(s), avatar: const Icon(
                Icons.history_rounded,
                size: 14,
              )))
              .toList(),
        ),
      ],
    );
  }
}
