import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_sessions_event.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_sessions_state.dart';

class WorkSessionsBloc extends Bloc<WorkSessionsEvent, WorkSessionsState> {
  WorkSessionsBloc(this._repository) : super(const WorkSessionsState()) {
    on<WorkSessionsLoadRequested>(_onLoadRequested);
    on<WorkSessionsWatchRequested>(_onWatchRequested);
    on<WorkSessionsUpdated>(_onSessionsUpdated);
    on<WorkSessionsWatchFailed>(_onWatchFailed);
    on<WorkSessionUpsertRequested>(_onSessionUpsert);
    on<WorkSessionDeleteRequested>(_onSessionDelete);
    on<ActiveSessionRequested>(_onActiveSessionRequested);
  }

  final WorkSessionRepository _repository;
  StreamSubscription<List<WorkSessionModel>>? _sessionsSubscription;

  Future<void> _onLoadRequested(
    WorkSessionsLoadRequested event,
    Emitter<WorkSessionsState> emit,
  ) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _onWatchRequested(
    WorkSessionsWatchRequested event,
    Emitter<WorkSessionsState> emit,
  ) async {
    emit(
      state.copyWith(status: WorkSessionsStatus.loading, errorMessage: null),
    );
    await _sessionsSubscription?.cancel();
    _sessionsSubscription = _repository.watchSessions().listen(
      (sessions) => add(WorkSessionsUpdated(sessions)),
      onError: (Object error, StackTrace _) {
        add(WorkSessionsWatchFailed(error.toString()));
      },
    );
  }

  void _onSessionsUpdated(
    WorkSessionsUpdated event,
    Emitter<WorkSessionsState> emit,
  ) {
    emit(
      state.copyWith(
        status: WorkSessionsStatus.loaded,
        sessions: event.sessions,
        activeSession: _findActiveSession(event.sessions),
        errorMessage: null,
      ),
    );
  }

  void _onWatchFailed(
    WorkSessionsWatchFailed event,
    Emitter<WorkSessionsState> emit,
  ) {
    emit(
      state.copyWith(
        status: WorkSessionsStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onSessionUpsert(
    WorkSessionUpsertRequested event,
    Emitter<WorkSessionsState> emit,
  ) async {
    try {
      await _repository.upsertSession(event.session);
      if (_sessionsSubscription == null) {
        await _fetchAndEmit(emit);
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: WorkSessionsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSessionDelete(
    WorkSessionDeleteRequested event,
    Emitter<WorkSessionsState> emit,
  ) async {
    final previous = state;
    final updatedSessions = state.sessions
        .where((session) => session.id != event.sessionId)
        .toList(growable: false);
    emit(
      state.copyWith(
        sessions: updatedSessions,
        activeSession: _findActiveSession(updatedSessions),
        errorMessage: null,
      ),
    );
    try {
      await _repository.deleteSession(event.sessionId);
      if (_sessionsSubscription == null) {
        await _fetchAndEmit(emit);
      }
    } catch (error) {
      emit(
        previous.copyWith(
          status: WorkSessionsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      if (_sessionsSubscription == null) {
        await _fetchAndEmit(emit);
      }
    }
  }

  Future<void> _onActiveSessionRequested(
    ActiveSessionRequested event,
    Emitter<WorkSessionsState> emit,
  ) async {
    try {
      final activeSession = await _repository.getActiveSession();
      emit(state.copyWith(activeSession: activeSession));
    } catch (error) {
      emit(
        state.copyWith(
          status: WorkSessionsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _fetchAndEmit(Emitter<WorkSessionsState> emit) async {
    emit(
      state.copyWith(status: WorkSessionsStatus.loading, errorMessage: null),
    );
    try {
      final sessions = await _repository.getAllSessions();
      emit(
        state.copyWith(
          status: WorkSessionsStatus.loaded,
          sessions: sessions,
          activeSession: _findActiveSession(sessions),
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: WorkSessionsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  WorkSessionModel? _findActiveSession(List<WorkSessionModel> sessions) {
    for (final session in sessions) {
      if (session.endTime == null) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<void> close() {
    _sessionsSubscription?.cancel();
    return super.close();
  }
}
