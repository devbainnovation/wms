part of 'dashboard_tab_view.dart';

String _formatTimeOnly(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value.toLowerCase() == 'null') {
    return '-';
  }
  final timeParts = _parseTimeParts(value);
  if (timeParts != null) {
    return 'Today ${_formatClockTime(hour: timeParts.hour, minute: timeParts.minute)}';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  final now = DateTime.now();
  final timeText = _formatClockTime(hour: local.hour, minute: local.minute);
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;

  if (isToday) {
    return 'Today $timeText';
  }

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString().padLeft(4, '0');
  return '$day/$month/$year $timeText';
}

String _formatDateTimeRange(String from, String to) {
  final fromDate = DateTime.tryParse(from)?.toLocal();
  final toDate = DateTime.tryParse(to)?.toLocal();

  if (fromDate == null || toDate == null) {
    return '${_formatTimeOnly(from)} to ${_formatTimeOnly(to)}';
  }

  final sameDate =
      fromDate.year == toDate.year &&
      fromDate.month == toDate.month &&
      fromDate.day == toDate.day;

  final fromTime = _formatClockTime(
    hour: fromDate.hour,
    minute: fromDate.minute,
  );

  final toTime = _formatClockTime(hour: toDate.hour, minute: toDate.minute);

  final now = DateTime.now();

  final isToday =
      fromDate.year == now.year &&
      fromDate.month == now.month &&
      fromDate.day == now.day;

  if (sameDate) {
    if (isToday) {
      return 'Today, $fromTime to $toTime';
    }

    final day = fromDate.day.toString().padLeft(2, '0');
    final month = fromDate.month.toString().padLeft(2, '0');
    final year = fromDate.year.toString();

    return '$day/$month/$year, $fromTime to $toTime';
  }

  return '${_formatTimeOnly(from)} to ${_formatTimeOnly(to)}';
}

Duration? _remainingValveTime({
  required String onTime,
  required String offTime,
  required DateTime now,
}) {
  final start = _resolveTimerDateTime(onTime, now);
  var end = _resolveTimerDateTime(offTime, now);
  if (start == null || end == null) {
    return null;
  }

  if (!end.isAfter(start)) {
    end = end.add(const Duration(days: 1));
  }

  if (now.isBefore(start)) {
    final previousStart = start.subtract(const Duration(days: 1));
    final previousEnd = end.subtract(const Duration(days: 1));
    if (!now.isBefore(previousStart) && now.isBefore(previousEnd)) {
      return previousEnd.difference(now);
    }
  }

  if (now.isBefore(start) || !now.isBefore(end)) {
    return null;
  }

  return end.difference(now);
}

DateTime? _resolveTimerDateTime(String raw, DateTime now) {
  final value = raw.trim();
  if (value.isEmpty || value.toLowerCase() == 'null') {
    return null;
  }

  final timeParts = _parseTimeParts(value);
  if (timeParts != null) {
    return DateTime(
      now.year,
      now.month,
      now.day,
      timeParts.hour,
      timeParts.minute,
      timeParts.second,
    );
  }

  return DateTime.tryParse(value)?.toLocal();
}

_ClockTimeParts? _parseTimeParts(String value) {
  final match = RegExp(
    r'^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?\s*$',
  ).firstMatch(value);
  if (match == null) {
    return null;
  }

  var hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  final second = int.tryParse(match.group(3) ?? '0') ?? 0;
  final period = match.group(4)?.toUpperCase();
  if (hour == null ||
      minute == null ||
      minute < 0 ||
      minute > 59 ||
      second < 0 ||
      second > 59) {
    return null;
  }

  if (period != null) {
    if (hour < 1 || hour > 12) {
      return null;
    }
    if (period == 'AM') {
      hour = hour == 12 ? 0 : hour;
    } else {
      hour = hour == 12 ? 12 : hour + 12;
    }
  }

  if (hour < 0 || hour > 23) {
    return null;
  }

  return _ClockTimeParts(hour: hour, minute: minute, second: second);
}

String _formatClockTime({required int hour, required int minute}) {
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final minuteText = minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  return '${hour12.toString().padLeft(2, '0')}:$minuteText $period';
}

String _formatDurationClock(Duration duration) {
  final totalSeconds = duration.inSeconds <= 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return [
    hours.toString().padLeft(2, '0'),
    minutes.toString().padLeft(2, '0'),
    seconds.toString().padLeft(2, '0'),
  ].join(':');
}

class _ClockTimeParts {
  const _ClockTimeParts({
    required this.hour,
    required this.minute,
    required this.second,
  });

  final int hour;
  final int minute;
  final int second;
}

String? _buildExpiryAlertMessage(List<CustomerDeviceSummary> devices) {
  int? minRechargeDays;
  int? minAmcDays;

  for (final device in devices) {
    final rechargeDays = _daysUntilExpiry(device.rechargeExpiry);
    if (rechargeDays != null &&
        (minRechargeDays == null || rechargeDays < minRechargeDays)) {
      minRechargeDays = rechargeDays;
    }

    final amcDays = _daysUntilExpiry(device.amcExpiry);
    if (amcDays != null && (minAmcDays == null || amcDays < minAmcDays)) {
      minAmcDays = amcDays;
    }
  }

  final parts = <String>[];
  if (minRechargeDays != null) {
    parts.add(_formatExpiryText(label: 'Recharge', days: minRechargeDays));
  }
  if (minAmcDays != null) {
    parts.add(_formatExpiryText(label: 'AMC', days: minAmcDays));
  }

  if (parts.isEmpty) {
    return null;
  }

  if (parts.length == 2 && minRechargeDays != null && minAmcDays != null) {
    if (minRechargeDays != minAmcDays) {
      return '${parts[0]}. ${parts[1]}.';
    }
    return '${parts[0]}   •   ${parts[1]}';
  }

  return parts.first;
}

int? _daysUntilExpiry(String rawDate) {
  final value = rawDate.trim();
  if (value.isEmpty || value.toLowerCase() == 'null') {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return null;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiryDay = DateTime(parsed.year, parsed.month, parsed.day);
  final days = expiryDay.difference(today).inDays;

  if (days > 30) {
    return null;
  }
  return days;
}

String _formatExpiryText({required String label, required int days}) {
  if (days < 0) {
    final absDays = days.abs();
    return '$label expired $absDays day${absDays == 1 ? '' : 's'} ago';
  }
  if (days == 0) {
    return '$label expires today';
  }
  return '$label expires in $days day${days == 1 ? '' : 's'}';
}
