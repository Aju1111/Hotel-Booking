import 'package:flutter/material.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/utils/formatters.dart';
import 'package:intl/intl.dart';

/// Opens a small centered calendar dialog — tap a day to confirm.
Future<DateTime?> showCompactDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? title,
}) {
  final safeInitial = _clampDate(initialDate, firstDate, lastDate);
  final first = _dateOnly(firstDate);
  final last = _dateOnly(lastDate);

  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      var selected = safeInitial;
      var month = DateTime(safeInitial.year, safeInitial.month);

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              void pick(DateTime date) {
                Navigator.pop(dialogContext, _dateOnly(date));
              }

              void setMonth(DateTime nextMonth) {
                setDialogState(() => month = nextMonth);
              }

              final shortcuts = _shortcuts(first, last);

              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title ?? 'Select date',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                    if (shortcuts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: shortcuts.map((shortcut) {
                          return _QuickDateChip(
                            label: shortcut.label,
                            selected: _isSameDay(selected, shortcut.date),
                            onTap: () => pick(shortcut.date),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _MiniMonthCalendar(
                      month: month,
                      selected: selected,
                      firstDate: first,
                      lastDate: last,
                      onMonthChanged: setMonth,
                      onDaySelected: pick,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surfaceAlt,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMonthCalendar extends StatelessWidget {
  const _MiniMonthCalendar({
    required this.month,
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _cellSize = 34.0;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final canGoPrev = DateTime(month.year, month.month, 0).isAfter(firstDate);
    final canGoNext =
        DateTime(month.year, month.month + 1, 1).isBefore(lastDate) ||
        _isSameDay(DateTime(month.year, month.month + 1, 1), lastDate);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              enabled: canGoPrev,
              onTap: () => onMonthChanged(
                DateTime(month.year, month.month - 1),
              ),
            ),
            Expanded(
              child: Text(
                monthLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              enabled: canGoNext,
              onTap: () => onMonthChanged(
                DateTime(month.year, month.month + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: _weekdays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        ..._buildWeeks(context),
      ],
    );
  }

  List<Widget> _buildWeeks(BuildContext context) {
    final weeks = <Widget>[];
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = (firstOfMonth.weekday + 6) % 7;
    final today = _dateOnly(DateTime.now());

    var day = 1;
    for (var week = 0; week < 6; week++) {
      if (day > daysInMonth && week > 0) break;

      final cells = <Widget>[];
      for (var col = 0; col < 7; col++) {
        final index = week * 7 + col;
        if (index < leading || day > daysInMonth) {
          cells.add(const SizedBox(width: _cellSize, height: _cellSize));
          continue;
        }

        final date = DateTime(month.year, month.month, day);
        final enabled = !_dateOnly(date).isBefore(firstDate) &&
            !_dateOnly(date).isAfter(lastDate);
        final isSelected = _isSameDay(date, selected);
        final isToday = _isSameDay(date, today);

        cells.add(
          _DayCell(
            label: '$day',
            enabled: enabled,
            selected: isSelected,
            isToday: isToday,
            onTap: enabled ? () => onDaySelected(date) : null,
          ),
        );
        day++;
      }

      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: cells,
        ),
      );
      if (day > daysInMonth) break;
    }

    return weeks;
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: enabled ? onTap : null,
      icon: Icon(
        icon,
        size: 20,
        color: enabled ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.enabled,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool selected;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background = Colors.transparent;
    Color foreground = AppColors.textPrimary;
    var borderSide = BorderSide.none;

    if (!enabled) {
      foreground = AppColors.textSecondary.withValues(alpha: 0.35);
    } else if (selected) {
      background = AppColors.primary;
      foreground = Colors.white;
    } else if (isToday) {
      background = AppColors.primary.withValues(alpha: 0.1);
      foreground = AppColors.primary;
      borderSide = BorderSide(color: AppColors.primary.withValues(alpha: 0.35));
    }

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _MiniMonthCalendar._cellSize,
          height: _MiniMonthCalendar._cellSize,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateShortcut {
  const _DateShortcut(this.label, this.date);

  final String label;
  final DateTime date;
}

List<_DateShortcut> _shortcuts(DateTime first, DateTime last) {
  final today = _dateOnly(DateTime.now());
  final options = <_DateShortcut>[
    _DateShortcut('Today', today),
    _DateShortcut('Tomorrow', today.add(const Duration(days: 1))),
    _DateShortcut('+3 days', today.add(const Duration(days: 3))),
    _DateShortcut('+1 week', today.add(const Duration(days: 7))),
  ];

  return options
      .where(
        (option) =>
            !_dateOnly(option.date).isBefore(first) &&
            !_dateOnly(option.date).isAfter(last),
      )
      .take(3)
      .toList();
}

DateTime _clampDate(DateTime date, DateTime first, DateTime last) {
  final normalized = _dateOnly(date);
  final min = _dateOnly(first);
  final max = _dateOnly(last);
  if (normalized.isBefore(min)) return min;
  if (normalized.isAfter(max)) return max;
  return normalized;
}

DateTime _dateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Small tap target for picking a date — used on booking and check-in forms.
class CompactDateField extends StatelessWidget {
  const CompactDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
    this.enabled = true,
    this.placeholder = 'Pick',
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final bool enabled;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;

    final now = DateTime.now();
    final first = firstDate ?? now;
    final last = lastDate ?? now.add(const Duration(days: 365));

    final picked = await showCompactDatePicker(
      context,
      title: label,
      initialDate: value ?? first,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: AppColors.surfaceAlt.withValues(alpha: 0.65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          side: BorderSide(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => _openPicker(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 13,
                  color: hasValue ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: '$label · '),
                        TextSpan(
                          text: hasValue
                              ? Formatters.relativeDay(value!)
                              : placeholder,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 12.5,
                            color: hasValue
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
