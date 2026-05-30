import 'package:flutter/foundation.dart';

enum WorkSessionFormStatus { initial, editing, saving, success, failure }

@immutable
class WorkSessionFormState {
  const WorkSessionFormState({
    this.status = WorkSessionFormStatus.initial,
    this.sessionId,
    this.companyId,
    this.startTime,
    this.endTime,
    this.notes,
    this.errorMessage,
  });

  final WorkSessionFormStatus status;
  final String? sessionId;
  final String? companyId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;
  final String? errorMessage;

  WorkSessionFormState copyWith({
    WorkSessionFormStatus? status,
    String? sessionId,
    String? companyId,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    String? errorMessage,
  }) {
    return WorkSessionFormState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
