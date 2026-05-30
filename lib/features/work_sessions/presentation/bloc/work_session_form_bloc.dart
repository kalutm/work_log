import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/core/settings/app_settings.dart';
import 'package:time_tracker/core/time/time_rounding.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_session_form_event.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_session_form_state.dart';

class WorkSessionFormBloc
    extends Bloc<WorkSessionFormEvent, WorkSessionFormState> {
  WorkSessionFormBloc(this._repository, {AppSettings? settings})
    : _settings = settings ?? AppSettingsHive.fromHive(),
      super(const WorkSessionFormState()) {
    on<WorkSessionFormInitialized>(_onInitialized);
    on<WorkSessionCompanyChanged>(_onCompanyChanged);
    on<WorkSessionStartTimeChanged>(_onStartTimeChanged);
    on<WorkSessionEndTimeChanged>(_onEndTimeChanged);
    on<WorkSessionNotesChanged>(_onNotesChanged);
    on<WorkSessionFormSubmitted>(_onSubmitted);
    on<WorkSessionFormDeleteRequested>(_onDeleteRequested);
  }

  final WorkSessionRepository _repository;
  final AppSettings _settings;

  void _onInitialized(
    WorkSessionFormInitialized event,
    Emitter<WorkSessionFormState> emit,
  ) {
    final session = event.session;
    if (session == null) {
      emit(const WorkSessionFormState(status: WorkSessionFormStatus.editing));
      return;
    }

    emit(
      WorkSessionFormState(
        status: WorkSessionFormStatus.editing,
        sessionId: session.id,
        companyId: session.companyId,
        startTime: session.startTime,
        endTime: session.endTime,
        notes: session.notes,
        errorMessage: null,
      ),
    );
  }

  void _onCompanyChanged(
    WorkSessionCompanyChanged event,
    Emitter<WorkSessionFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: WorkSessionFormStatus.editing,
        companyId: event.companyId,
        errorMessage: null,
      ),
    );
  }

  void _onStartTimeChanged(
    WorkSessionStartTimeChanged event,
    Emitter<WorkSessionFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: WorkSessionFormStatus.editing,
        startTime: event.startTime,
        errorMessage: null,
      ),
    );
  }

  void _onEndTimeChanged(
    WorkSessionEndTimeChanged event,
    Emitter<WorkSessionFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: WorkSessionFormStatus.editing,
        endTime: event.endTime,
        errorMessage: null,
      ),
    );
  }

  void _onNotesChanged(
    WorkSessionNotesChanged event,
    Emitter<WorkSessionFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: WorkSessionFormStatus.editing,
        notes: event.notes,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onSubmitted(
    WorkSessionFormSubmitted event,
    Emitter<WorkSessionFormState> emit,
  ) async {
    final validationError = _validate(state);
    if (validationError != null) {
      emit(
        state.copyWith(
          status: WorkSessionFormStatus.failure,
          errorMessage: validationError,
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: WorkSessionFormStatus.saving, errorMessage: null),
    );

    final rawStartTime = state.startTime!;
    final rawEndTime = state.endTime!;
    final roundingMinutes = await _settings.getTimeRoundingMinutes() ?? 0;
    final roundedTimes = roundingMinutes > 0
        ? roundSessionTimes(rawStartTime, rawEndTime, roundingMinutes)
        : RoundedTimes(start: rawStartTime, end: rawEndTime);
    final startTime = roundedTimes.start;
    final endTime = roundedTimes.end;
    final durationInSeconds = endTime.difference(startTime).inSeconds;
    final notes = _normalizeNotes(state.notes);
    final overlapMessage = await _findOverlapMessage(
      startTime: startTime,
      endTime: endTime,
      sessionId: state.sessionId,
    );
    if (overlapMessage != null) {
      emit(
        state.copyWith(
          status: WorkSessionFormStatus.failure,
          errorMessage: overlapMessage,
        ),
      );
      return;
    }
    final session = WorkSessionModel(
      id: state.sessionId ?? _generateId(),
      companyId: state.companyId!,
      startTime: startTime,
      endTime: endTime,
      durationInSeconds: durationInSeconds,
      notes: notes,
    );

    try {
      await _repository.upsertSession(session);
      emit(
        state.copyWith(
          status: WorkSessionFormStatus.success,
          sessionId: session.id,
          notes: notes,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: WorkSessionFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    WorkSessionFormDeleteRequested event,
    Emitter<WorkSessionFormState> emit,
  ) async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      emit(
        state.copyWith(
          status: WorkSessionFormStatus.failure,
          errorMessage: 'No session to delete.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: WorkSessionFormStatus.saving, errorMessage: null),
    );

    try {
      await _repository.deleteSession(sessionId);
      emit(const WorkSessionFormState(status: WorkSessionFormStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: WorkSessionFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  String? _validate(WorkSessionFormState state) {
    final companyId = state.companyId;
    final startTime = state.startTime;
    final endTime = state.endTime;

    if (companyId == null || companyId.isEmpty) {
      return 'Company is required.';
    }
    if (startTime == null) {
      return 'Start time is required.';
    }
    if (endTime == null) {
      return 'End time is required.';
    }
    if (endTime.isBefore(startTime)) {
      return 'End time must be after start time.';
    }

    return null;
  }

  String? _normalizeNotes(String? notes) {
    if (notes == null) {
      return null;
    }
    final trimmed = notes.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<String?> _findOverlapMessage({
    required DateTime startTime,
    required DateTime endTime,
    required String? sessionId,
  }) async {
    final sessions = await _repository.getAllSessions();
    for (final existing in sessions) {
      if (sessionId != null && existing.id == sessionId) {
        continue;
      }
      final existingStart = existing.startTime;
      final existingEnd = existing.endTime ?? DateTime.now();
      if (_rangesOverlap(startTime, endTime, existingStart, existingEnd)) {
        return 'Session overlaps with another logged session.';
      }
    }
    return null;
  }

  bool _rangesOverlap(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    return startA.isBefore(endB) && endA.isAfter(startB);
  }
}
