import 'package:flutter/material.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';
import 'package:hotel_booking/utils/formatters.dart';

/// Small dialog with quick times and an optional custom time picker.
Future<TimeOfDay?> showCompactTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String? title,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) {
      var selected = initialTime;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Builder(
            builder: (context) {
              Future<void> pickCustom() async {
                final custom = await showTimePicker(
                  context: context,
                  initialTime: selected,
                  initialEntryMode: TimePickerEntryMode.input,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        timePickerTheme: TimePickerThemeData(
                          backgroundColor: AppColors.surface,
                          hourMinuteTextStyle: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w600,
                          ),
                          dialHandColor: AppColors.primary,
                          dialBackgroundColor: AppColors.surfaceAlt,
                          entryModeIconColor: AppColors.primary,
                        ),
                      ),
                      child: MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(alwaysUse24HourFormat: false),
                        child: child!,
                      ),
                    );
                  },
                );
                if (custom != null && dialogContext.mounted) {
                  Navigator.pop(dialogContext, custom);
                }
              }

              void pick(TimeOfDay time) {
                Navigator.pop(dialogContext, time);
              }

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
                            title ?? 'Select time',
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
                    Text(
                      Formatters.formatTime(selected),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _shortcuts.map((shortcut) {
                        final isSelected =
                            selected.hour == shortcut.time.hour &&
                            selected.minute == shortcut.time.minute;
                        return _QuickTimeChip(
                          label: shortcut.label,
                          selected: isSelected,
                          onTap: () => pick(shortcut.time),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: pickCustom,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.schedule_rounded, size: 16),
                      label: const Text('Custom time'),
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

class _TimeShortcut {
  const _TimeShortcut(this.label, this.time);

  final String label;
  final TimeOfDay time;
}

const _shortcuts = [
  _TimeShortcut('10:00 AM', TimeOfDay(hour: 10, minute: 0)),
  _TimeShortcut('02:00 PM', TimeOfDay(hour: 14, minute: 0)),
  _TimeShortcut('07:00 PM', TimeOfDay(hour: 19, minute: 0)),
  _TimeShortcut('09:00 PM', TimeOfDay(hour: 21, minute: 0)),
];

class _QuickTimeChip extends StatelessWidget {
  const _QuickTimeChip({
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

/// Small tap target for picking a time — matches [CompactDateField] styling.
class CompactTimeField extends StatelessWidget {
  const CompactTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
    this.enabled = true,
    this.placeholder = 'Pick',
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onPick;
  final bool enabled;
  final String placeholder;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;

    final picked = await showCompactTimePicker(
      context,
      title: label,
      initialTime: value ?? TimeOfDay.now(),
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
                  Icons.schedule_rounded,
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
                              ? Formatters.formatTime(value!)
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
                  Icons.expand_more_rounded,
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
