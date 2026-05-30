import 'package:flutter/foundation.dart';

import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

@immutable
sealed class WorkSessionFormEvent {
  const WorkSessionFormEvent();
}

class WorkSessionFormInitialized extends WorkSessionFormEvent {
  const WorkSessionFormInitialized({this.session});

  final WorkSessionModel? session;
}

class WorkSessionCompanyChanged extends WorkSessionFormEvent {
  const WorkSessionCompanyChanged(this.companyId);

  final String? companyId;
}

class WorkSessionStartTimeChanged extends WorkSessionFormEvent {
  const WorkSessionStartTimeChanged(this.startTime);

  final DateTime? startTime;
}

class WorkSessionEndTimeChanged extends WorkSessionFormEvent {
  const WorkSessionEndTimeChanged(this.endTime);

  final DateTime? endTime;
}

class WorkSessionNotesChanged extends WorkSessionFormEvent {
  const WorkSessionNotesChanged(this.notes);

  final String? notes;
}

class WorkSessionFormSubmitted extends WorkSessionFormEvent {
  const WorkSessionFormSubmitted();
}

class WorkSessionFormDeleteRequested extends WorkSessionFormEvent {
  const WorkSessionFormDeleteRequested();
}
