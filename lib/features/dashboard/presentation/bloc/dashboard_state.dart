import 'package:flutter/foundation.dart';

enum DashboardStatus { initial, loading, loaded, failure }

@immutable
class DayWorkSummary {
  const DayWorkSummary({required this.date, required this.totalSeconds});

  final DateTime date;
  final int totalSeconds;
}

@immutable
class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.dailyTotalSeconds = 0,
    this.monthlyTotalSeconds = 0,
    this.last7Days = const <DayWorkSummary>[],
    this.last30Days = const <DayWorkSummary>[],
    this.thisMonthDays = const <DayWorkSummary>[],
    this.daysWithSessions = const <DateTime>{},
    this.errorMessage,
  });

  final DashboardStatus status;
  final int dailyTotalSeconds;
  final int monthlyTotalSeconds;
  final List<DayWorkSummary> last7Days;
  final List<DayWorkSummary> last30Days;
  final List<DayWorkSummary> thisMonthDays;
  final Set<DateTime> daysWithSessions;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    int? dailyTotalSeconds,
    int? monthlyTotalSeconds,
    List<DayWorkSummary>? last7Days,
    List<DayWorkSummary>? last30Days,
    List<DayWorkSummary>? thisMonthDays,
    Set<DateTime>? daysWithSessions,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      dailyTotalSeconds: dailyTotalSeconds ?? this.dailyTotalSeconds,
      monthlyTotalSeconds: monthlyTotalSeconds ?? this.monthlyTotalSeconds,
      last7Days: last7Days ?? this.last7Days,
      last30Days: last30Days ?? this.last30Days,
      thisMonthDays: thisMonthDays ?? this.thisMonthDays,
      daysWithSessions: daysWithSessions ?? this.daysWithSessions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
