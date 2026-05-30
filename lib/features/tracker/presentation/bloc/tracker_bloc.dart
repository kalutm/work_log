import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/core/settings/app_settings.dart';
import 'package:time_tracker/core/time/time_rounding.dart';
import 'package:time_tracker/features/tracker/presentation/bloc/tracker_event.dart';
import 'package:time_tracker/features/tracker/presentation/bloc/tracker_state.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';

class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  TrackerBloc(this._repository, {AppSettings? settings})
    : _settings = settings ?? AppSettingsHive.fromHive(),
      super(const TrackerState()) {
    on<TrackerStarted>(_onStarted);
    on<TrackerCheckInRequested>(_onCheckInRequested);
    on<TrackerCheckOutRequested>(_onCheckOutRequested);
    on<TrackerTicked>(_onTicked);
  }

  final WorkSessionRepository _repository;
  final AppSettings _settings;
  Timer? _ticker;

  Future<void> _onStarted(
    TrackerStarted event,
    Emitter<TrackerState> emit,
  ) async {
    emit(state.copyWith(status: TrackerStatus.loading, errorMessage: null));
    try {
      final activeSession = await _repository.getActiveSession();
      if (activeSession == null) {
        _stopTicker();
        emit(
          state.copyWith(
            status: TrackerStatus.idle,
            activeSession: null,
            elapsedSeconds: 0,
            errorMessage: null,
          ),
        );
        return;
      }
      _startTicker();
      emit(
        state.copyWith(
          status: TrackerStatus.active,
          activeSession: activeSession,
          elapsedSeconds: _calculateElapsedSeconds(activeSession),
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TrackerStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCheckInRequested(
    TrackerCheckInRequested event,
    Emitter<TrackerState> emit,
  ) async {
    if (state.activeSession != null) {
      emit(
        state.copyWith(
          status: TrackerStatus.failure,
          errorMessage: 'Active session already exists.',
        ),
      );
      return;
    }

    final now = DateTime.now();
    final session = WorkSessionModel(
      id: _generateId(),
      companyId: event.companyId,
      startTime: now,
      endTime: null,
      durationInSeconds: 0,
      notes: event.notes,
    );

    try {
      await _repository.upsertSession(session);
      _startTicker();
      emit(
        state.copyWith(
          status: TrackerStatus.active,
          activeSession: session,
          elapsedSeconds: 0,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TrackerStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCheckOutRequested(
    TrackerCheckOutRequested event,
    Emitter<TrackerState> emit,
  ) async {
    final activeSession = state.activeSession;
    if (activeSession == null) {
      emit(
        state.copyWith(
          status: TrackerStatus.failure,
          errorMessage: 'No active session to check out.',
        ),
      );
      return;
    }

    final rawStartTime = activeSession.startTime;
    final rawEndTime = DateTime.now();
    final roundingMinutes = await _settings.getTimeRoundingMinutes() ?? 0;
    final roundedTimes = roundingMinutes > 0
        ? roundSessionTimes(rawStartTime, rawEndTime, roundingMinutes)
        : RoundedTimes(start: rawStartTime, end: rawEndTime);
    final durationInSeconds = roundedTimes.end
        .difference(roundedTimes.start)
        .inSeconds;
    final updatedSession = activeSession.copyWith(
      startTime: roundedTimes.start,
      endTime: roundedTimes.end,
      durationInSeconds: durationInSeconds,
      notes: event.notes ?? activeSession.notes,
    );

    try {
      await _repository.upsertSession(updatedSession);
      _stopTicker();
      emit(
        state.copyWith(
          status: TrackerStatus.idle,
          activeSession: null,
          elapsedSeconds: 0,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TrackerStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onTicked(TrackerTicked event, Emitter<TrackerState> emit) {
    final activeSession = state.activeSession;
    if (activeSession == null) {
      _stopTicker();
      return;
    }

    emit(
      state.copyWith(elapsedSeconds: _calculateElapsedSeconds(activeSession)),
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const TrackerTicked()),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  int _calculateElapsedSeconds(WorkSessionModel session) {
    return DateTime.now().difference(session.startTime).inSeconds;
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  @override
  Future<void> close() {
    _stopTicker();
    return super.close();
  }
}
