class RoundedTimes {
  const RoundedTimes({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

DateTime roundToNearestMinutes(DateTime input, int intervalMinutes) {
  if (intervalMinutes <= 0) {
    return input;
  }

  final intervalMs = intervalMinutes * Duration.millisecondsPerMinute;
  final halfInterval = intervalMs ~/ 2;
  final roundedMs =
      ((input.millisecondsSinceEpoch + halfInterval) ~/ intervalMs) *
      intervalMs;
  return DateTime.fromMillisecondsSinceEpoch(roundedMs, isUtc: input.isUtc);
}

RoundedTimes roundSessionTimes(
  DateTime start,
  DateTime end,
  int intervalMinutes,
) {
  final roundedStart = roundToNearestMinutes(start, intervalMinutes);
  final roundedEnd = roundToNearestMinutes(end, intervalMinutes);

  if (!roundedEnd.isAfter(roundedStart)) {
    return RoundedTimes(
      start: roundedStart,
      end: roundedStart.add(Duration(minutes: intervalMinutes)),
    );
  }

  return RoundedTimes(start: roundedStart, end: roundedEnd);
}
