import 'package:flutter/foundation.dart';

import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

enum TrackerStatus { initial, loading, idle, active, failure }

@immutable
class TrackerState {
  static const _unset = Object();

  const TrackerState({
    this.status = TrackerStatus.initial,
    this.activeSession,
    this.elapsedSeconds = 0,
    this.errorMessage,
  });

  final TrackerStatus status;
  final WorkSessionModel? activeSession;
  final int elapsedSeconds;
  final String? errorMessage;

  TrackerState copyWith({
    TrackerStatus? status,
    Object? activeSession = _unset,
    int? elapsedSeconds,
    Object? errorMessage = _unset,
  }) {
    return TrackerState(
      status: status ?? this.status,
      activeSession: activeSession == _unset
          ? this.activeSession
          : activeSession as WorkSessionModel?,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
