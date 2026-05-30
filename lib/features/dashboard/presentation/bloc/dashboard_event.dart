import 'package:flutter/foundation.dart';

import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

@immutable
sealed class DashboardEvent {
  const DashboardEvent();
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

class DashboardWatchRequested extends DashboardEvent {
  const DashboardWatchRequested();
}

class DashboardSessionsUpdated extends DashboardEvent {
  const DashboardSessionsUpdated(this.sessions);

  final List<WorkSessionModel> sessions;
}

class DashboardWatchFailed extends DashboardEvent {
  const DashboardWatchFailed(this.message);

  final String message;
}
