import 'package:flutter/foundation.dart';

import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

enum WorkSessionsStatus { initial, loading, loaded, failure }

@immutable
class WorkSessionsState {
  const WorkSessionsState({
    this.status = WorkSessionsStatus.initial,
    this.sessions = const <WorkSessionModel>[],
    this.activeSession,
    this.errorMessage,
  });

  final WorkSessionsStatus status;
  final List<WorkSessionModel> sessions;
  final WorkSessionModel? activeSession;
  final String? errorMessage;

  WorkSessionsState copyWith({
    WorkSessionsStatus? status,
    List<WorkSessionModel>? sessions,
    WorkSessionModel? activeSession,
    String? errorMessage,
  }) {
    return WorkSessionsState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      activeSession: activeSession ?? this.activeSession,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
