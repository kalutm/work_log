import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:time_tracker/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardWatchRequested>(_onWatchRequested);
    on<DashboardSessionsUpdated>(_onSessionsUpdated);
    on<DashboardWatchFailed>(_onWatchFailed);
  }

  final WorkSessionRepository _repository;
  StreamSubscription<List<WorkSessionModel>>? _sessionsSubscription;

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _onWatchRequested(
    DashboardWatchRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading, errorMessage: null));
    await _sessionsSubscription?.cancel();
    _sessionsSubscription = _repository.watchSessions().listen(
      (sessions) => add(DashboardSessionsUpdated(sessions)),
      onError: (Object error, StackTrace _) {
        add(DashboardWatchFailed(error.toString()));
      },
    );
  }

  void _onSessionsUpdated(
    DashboardSessionsUpdated event,
    Emitter<DashboardState> emit,
  ) {
    emit(_buildStateFromSessions(event.sessions));
  }

  void _onWatchFailed(
    DashboardWatchFailed event,
    Emitter<DashboardState> emit,
  ) {
    emit(
      state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _fetchAndEmit(Emitter<DashboardState> emit) async {
    emit(state.copyWith(status: DashboardStatus.loading, errorMessage: null));
    try {
      final sessions = await _repository.getAllSessions();
      emit(_buildStateFromSessions(sessions));
    } catch (error) {
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  DashboardState _buildStateFromSessions(List<WorkSessionModel> sessions) {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final dailyTotals = _buildDailyTotals(sessions, now);
    final dailyTotalSeconds = dailyTotals[todayKey] ?? 0;

    var monthlyTotalSeconds = 0;
    for (final entry in dailyTotals.entries) {
      if (!entry.key.isBefore(monthStart) && entry.key.isBefore(nextMonth)) {
        monthlyTotalSeconds += entry.value;
      }
    }

    final last7Days = _buildDaySeries(dailyTotals, now, 7);
    final last30Days = _buildDaySeries(dailyTotals, now, 30);
    final thisMonthDays = _buildMonthSeries(dailyTotals, now);

    return DashboardState(
      status: DashboardStatus.loaded,
      dailyTotalSeconds: dailyTotalSeconds,
      monthlyTotalSeconds: monthlyTotalSeconds,
      last7Days: last7Days,
      last30Days: last30Days,
      thisMonthDays: thisMonthDays,
      daysWithSessions: dailyTotals.keys.toSet(),
      errorMessage: null,
    );
  }

  Map<DateTime, int> _buildDailyTotals(
    List<WorkSessionModel> sessions,
    DateTime now,
  ) {
    final totals = <DateTime, int>{};
    for (final session in sessions) {
      final start = session.startTime;
      final end = session.endTime ?? now;
      if (!end.isAfter(start)) {
        continue;
      }
      _accumulateDailyTotals(totals, start, end);
    }
    return totals;
  }

  void _accumulateDailyTotals(
    Map<DateTime, int> totals,
    DateTime start,
    DateTime end,
  ) {
    var current = start;
    while (current.isBefore(end)) {
      final dayStart = _dayKey(current);
      final nextDay = dayStart.add(const Duration(days: 1));
      final segmentEnd = end.isBefore(nextDay) ? end : nextDay;
      final seconds = segmentEnd.difference(current).inSeconds;
      totals[dayStart] = (totals[dayStart] ?? 0) + seconds;
      current = segmentEnd;
    }
  }

  List<DayWorkSummary> _buildDaySeries(
    Map<DateTime, int> totals,
    DateTime now,
    int days,
  ) {
    final start = _dayKey(now).subtract(Duration(days: days - 1));
    return List<DayWorkSummary>.generate(days, (index) {
      final day = start.add(Duration(days: index));
      return DayWorkSummary(date: day, totalSeconds: totals[day] ?? 0);
    }, growable: false);
  }

  List<DayWorkSummary> _buildMonthSeries(
    Map<DateTime, int> totals,
    DateTime now,
  ) {
    final start = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return List<DayWorkSummary>.generate(daysInMonth, (index) {
      final day = start.add(Duration(days: index));
      return DayWorkSummary(date: day, totalSeconds: totals[day] ?? 0);
    }, growable: false);
  }

  DateTime _dayKey(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  @override
  Future<void> close() {
    _sessionsSubscription?.cancel();
    return super.close();
  }
}
