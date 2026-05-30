import 'package:flutter/foundation.dart';

@immutable
sealed class TrackerEvent {
  const TrackerEvent();
}

class TrackerStarted extends TrackerEvent {
  const TrackerStarted();
}

class TrackerCheckInRequested extends TrackerEvent {
  const TrackerCheckInRequested({required this.companyId, this.notes});

  final String companyId;
  final String? notes;
}

class TrackerCheckOutRequested extends TrackerEvent {
  const TrackerCheckOutRequested({this.notes});

  final String? notes;
}

class TrackerTicked extends TrackerEvent {
  const TrackerTicked();
}
