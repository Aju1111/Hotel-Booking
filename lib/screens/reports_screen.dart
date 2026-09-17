import 'package:flutter/material.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/models/room.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:hotel_booking/widgets/page_content.dart';
import 'package:hotel_booking/widgets/ui/app_panel.dart';
import 'package:hotel_booking/widgets/ui/charts.dart';
import 'package:hotel_booking/widgets/ui/stat_card.dart';
import 'package:hotel_booking/widgets/ui/tiles.dart';

/// Revenue and occupancy insights.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _revenue = [4200.0, 5100.0, 4800.0, 6400.0, 7100.0, 8200.0, 6900.0];
  static const _occupancy = [52.0, 61.0, 58.0, 70.0, 76.0, 88.0, 72.0];
  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  int _rangeIndex = 0;
  bool _showOccupancy = false;

  double get _weekTotal => _revenue.reduce((a, b) => a + b);

  List<HotelRoom> get _liveRooms => FrontDeskSession.instance.rooms;

  int _countWhere(RoomStatus status) =>
      _liveRooms.where((room) => room.status == status).length;

  double get _occupancyPercent => _liveRooms.isEmpty
      ? 0
      : (_countWhere(RoomStatus.occupied) / _liveRooms.length) * 100;

  @override
  Widget build(BuildContext context) {
    return PageContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(3, (index) {
                const ranges = ['This week', 'This month', 'This year'];
                final selected = index == _rangeIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(ranges[index]),
                    selected: selected,
                    onSelected: (_) => setState(() => _rangeIndex = index),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          _statGrid(),
          const SizedBox(height: 14),
          AppPanel(
            title: _showOccupancy ? 'Occupancy trend' : 'Revenue trend',
            subtitle: 'Last 7 days',
            leadingIcon: Icons.insights_rounded,
            trailing: IconButton(
              tooltip: _showOccupancy ? 'Show revenue' : 'Show occupancy',
              onPressed: () =>
                  setState(() => _showOccupancy = !_showOccupancy),
              icon: Icon(
                _showOccupancy
                    ? Icons.currency_rupee_rounded
                    : Icons.hotel_rounded,
                size: 19,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MiniBarChart(
                  values: _showOccupancy ? _occupancy : _revenue,
                  labels: _labels,
                  highlightIndex: 5,
                  height: 128,
                  barColor: _showOccupancy
                      ? AppColors.infoDark
                      : AppColors.primary,
                ),
                const SizedBox(height: 14),
                StatRow(
                  label: _showOccupancy ? 'Peak occupancy' : 'Week total',
                  value: _showOccupancy
                      ? '88%'
                      : Formatters.currency.format(_weekTotal),
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.accent,
                  caption: 'Saturday was the strongest day',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppPanel(
            title: 'Room mix',
            subtitle: 'Current status distribution',
            leadingIcon: Icons.donut_small_rounded,
            child: Column(
              children: [
                Center(
                  child: OccupancyDonut(
                    percent: _occupancyPercent,
                    totalRooms: _liveRooms.length,
                  ),
                ),
                const SizedBox(height: 16),
                ...RoomStatus.values.map((status) {
                  final count = _countWhere(status);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: StatRow(
                      label: roomStatusLabel(status),
                      value: '$count',
                      icon: Icons.meeting_room_outlined,
                      color: roomStatusColor(status),
                      caption: _liveRooms.isEmpty
                          ? '0%'
                          : '${(count / _liveRooms.length * 100).toStringAsFixed(0)}% of inventory',
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppPanel(
            title: 'Top performing rooms',
            leadingIcon: Icons.leaderboard_outlined,
            child: Column(
              children: _liveRooms.take(3).map((room) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: StatRow(
                    label: '${room.code} · ${room.roomType}',
                    value: Formatters.currency.format(room.pricePerNight),
                    icon: Icons.king_bed_outlined,
                    color: AppColors.primary,
                    caption: 'Floor ${room.floor}',
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid() {
    final cards = [
      StatCard(
        label: 'Revenue today',
        value: Formatters.currency.format(8200),
        icon: Icons.currency_rupee_rounded,
        color: AppColors.accent,
        caption: '+12%',
      ),
      StatCard(
        label: 'Occupancy',
        value: '${_occupancyPercent.toStringAsFixed(0)}%',
        icon: Icons.hotel_rounded,
        color: AppColors.infoDark,
        caption: '+4%',
        progress: _occupancyPercent / 100,
      ),
      const StatCard(
        label: 'Check-ins',
        value: '14',
        icon: Icons.login_rounded,
        color: AppColors.successDark,
        caption: 'Today',
      ),
      const StatCard(
        label: 'Check-outs',
        value: '9',
        icon: Icons.logout_rounded,
        color: AppColors.warningDark,
        caption: 'Today',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  height: StatCard.gridHeight,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
