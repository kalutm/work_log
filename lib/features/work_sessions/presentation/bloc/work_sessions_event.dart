import 'package:flutter/foundation.dart';

import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

@immutable
sealed class WorkSessionsEvent {
  const WorkSessionsEvent();
}

class WorkSessionsLoadRequested extends WorkSessionsEvent {
  const WorkSessionsLoadRequested();
}

class WorkSessionsWatchRequested extends WorkSessionsEvent {
  const WorkSessionsWatchRequested();
}

class WorkSessionsUpdated extends WorkSessionsEvent {
  const WorkSessionsUpdated(this.sessions);

  final List<WorkSessionModel> sessions;
}

class WorkSessionsWatchFailed extends WorkSessionsEvent {
  const WorkSessionsWatchFailed(this.message);

  final String message;
}

class WorkSessionUpsertRequested extends WorkSessionsEvent {
  const WorkSessionUpsertRequested(this.session);

  final WorkSessionModel session;
}

class WorkSessionDeleteRequested extends WorkSessionsEvent {
  const WorkSessionDeleteRequested(this.sessionId);

  final String sessionId;
}

class ActiveSessionRequested extends WorkSessionsEvent {
  const ActiveSessionRequested();
}
