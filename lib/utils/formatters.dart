import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract final class Formatters {
  static final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final date = DateFormat('dd/MM/yyyy');
  static final compactDate = DateFormat('d MMM yyyy');
  static final miniDate = DateFormat('d MMM');
  static final dateTime = DateFormat('EEE, MMM d, yyyy | h:mm a');
  static final shortDate = DateFormat('dd/MM/yyyy');
  static final _time = DateFormat('hh:mm a');
  static final _weekday = DateFormat('EEEE');

  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Friendly day label: Today, Tomorrow, Yesterday, then weekday or date.
  static String relativeDay(DateTime date, {DateTime? from}) {
    final base = dateOnly(from ?? DateTime.now());
    final target = dateOnly(date);
    final diff = target.difference(base).inDays;

    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      2 => 'Day after tomorrow',
      -2 => '2 days ago',
      >= 3 && <= 6 => _weekday.format(target),
      <= -3 && >= -6 => _weekday.format(target),
      _ => miniDate.format(target),
    };
  }

  static String formatTime(TimeOfDay time) =>
      _time.format(DateTime(2000, 1, 1, time.hour, time.minute));
}
