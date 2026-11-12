import '../values/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

final serviceLocator = GetIt.instance;

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
}

extension DateTimeExtension on DateTime {
  String format([String pattern = "dd/MM/yyyy HH:mm"]) {
    return DateFormat(pattern).format(this);
  }

  /// Returns a human-friendly relative time string for this [DateTime], e.g. "1 year ago",
  /// "3 hours ago", "just now" or "in 2 days".
  String timeAgo({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final diff = now.difference(this);
    final isPast = diff.inMilliseconds >= 0;
    final seconds = diff.inSeconds.abs();

    if (seconds < 5) return isPast ? 'just now' : 'in a few seconds';

    int value;
    String unit;

    if (seconds < 60) {
      value = seconds;
      unit = 'second';
    } else if (seconds < 3600) {
      value = diff.inMinutes.abs();
      unit = 'minute';
    } else if (seconds < 86400) {
      value = diff.inHours.abs();
      unit = 'hour';
    } else if (seconds < 604800) {
      value = diff.inDays.abs();
      unit = 'day';
    } else if (seconds < 2592000) {
      // ~30 days
      value = (diff.inDays.abs() / 7).floor();
      if (value == 0) value = 1;
      unit = 'week';
    } else if (seconds < 31557600) {
      // ~365.25 days
      value = (diff.inDays.abs() / 30).floor();
      if (value == 0) value = 1;
      unit = 'month';
    } else {
      value = (diff.inDays.abs() / 365).floor();
      if (value == 0) value = 1;
      unit = 'year';
    }

    final phrase = '$value $unit${value == 1 ? '' : 's'}';
    return isPast ? '$phrase ago' : 'in $phrase';
  }
}

extension AppPaletteExtension on BuildContext {
  /// Dedupe design tokens (glass panels, tints, status colours).
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
