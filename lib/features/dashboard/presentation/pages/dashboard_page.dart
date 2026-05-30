import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_tracker/features/companies/data/models/company_model.dart';

import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:time_tracker/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:time_tracker/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:time_tracker/features/dashboard/presentation/pages/calendar_page.dart';
import 'package:time_tracker/features/tracker/presentation/pages/tracker_page.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/pages/work_session_entry_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.workSessionRepository,
    required this.companyRepository,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardBloc(workSessionRepository)
            ..add(const DashboardWatchRequested()),
      child: DashboardView(
        workSessionRepository: workSessionRepository,
        companyRepository: companyRepository,
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.workSessionRepository,
    required this.companyRepository,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CalendarPage(
                  workSessionRepository: workSessionRepository,
                  companyRepository: companyRepository,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Failed to load dashboard.'),
            );
          }

          if (state.status == DashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.daysWithSessions.isEmpty) {
            return _DashboardEmptyState(
              workSessionRepository: workSessionRepository,
              companyRepository: companyRepository,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'Today',
                value: _formatDuration(state.dailyTotalSeconds),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'This month',
                value: _formatDuration(state.monthlyTotalSeconds),
              ),
              const SizedBox(height: 12),
              _InsightsSection(
                last7Days: state.last7Days,
                last30Days: state.last30Days,
                thisMonthDays: state.thisMonthDays,
              ),
              const SizedBox(height: 12),
              _CompanyTotalsSection(
                workSessionRepository: workSessionRepository,
                companyRepository: companyRepository,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Days with sessions',
                value: state.daysWithSessions.length.toString(),
              ),
              const SizedBox(height: 24),
              _SeriesSection(title: 'Last 7 days', series: state.last7Days),
              const SizedBox(height: 24),
              _SeriesSection(title: 'Last 30 days', series: state.last30Days),
              const SizedBox(height: 24),
              _SeriesSection(title: 'This month', series: state.thisMonthDays),
            ],
          );
        },
      ),
    );
  }
}

class _InsightsSection extends StatefulWidget {
  const _InsightsSection({
    required this.last7Days,
    required this.last30Days,
    required this.thisMonthDays,
  });

  final List<DayWorkSummary> last7Days;
  final List<DayWorkSummary> last30Days;
  final List<DayWorkSummary> thisMonthDays;

  @override
  State<_InsightsSection> createState() => _InsightsSectionState();
}

enum _InsightRange { last7, last30, thisMonth }

class _InsightsSectionState extends State<_InsightsSection> {
  _InsightRange _range = _InsightRange.last7;

  @override
  Widget build(BuildContext context) {
    final series = switch (_range) {
      _InsightRange.last7 => widget.last7Days,
      _InsightRange.last30 => widget.last30Days,
      _InsightRange.thisMonth => widget.thisMonthDays,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Last 7 days'),
                  selected: _range == _InsightRange.last7,
                  onSelected: (_) =>
                      setState(() => _range = _InsightRange.last7),
                ),
                ChoiceChip(
                  label: const Text('Last 30 days'),
                  selected: _range == _InsightRange.last30,
                  onSelected: (_) =>
                      setState(() => _range = _InsightRange.last30),
                ),
                ChoiceChip(
                  label: const Text('This month'),
                  selected: _range == _InsightRange.thisMonth,
                  onSelected: (_) =>
                      setState(() => _range = _InsightRange.thisMonth),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (series.isEmpty)
              const Text('No data yet.')
            else if (_range == _InsightRange.last7)
              _InsightsBarChart(series: series)
            else
              _InsightsHeatmap(series: series),
          ],
        ),
      ),
    );
  }
}

class _InsightsBarChart extends StatelessWidget {
  const _InsightsBarChart({required this.series});

  final List<DayWorkSummary> series;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final maxSeconds = series.fold<int>(
      0,
      (max, entry) => entry.totalSeconds > max ? entry.totalSeconds : max,
    );
    const maxHeight = 80.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: series
          .map((entry) {
            final ratio = maxSeconds == 0
                ? 0.0
                : entry.totalSeconds / maxSeconds;
            final height = (maxHeight * ratio).clamp(0, maxHeight);
            final label = localizations.formatShortDate(entry.date);
            final duration = _formatDuration(entry.totalSeconds);
            return Expanded(
              child: Tooltip(
                message: '$label • $duration',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      height: height.toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.date.day.toString(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _InsightsHeatmap extends StatelessWidget {
  const _InsightsHeatmap({required this.series});

  final List<DayWorkSummary> series;

  @override
  Widget build(BuildContext context) {
    final maxSeconds = series.fold<int>(
      0,
      (max, entry) => entry.totalSeconds > max ? entry.totalSeconds : max,
    );
    final base = Theme.of(context).colorScheme.surfaceVariant;
    final active = Theme.of(context).colorScheme.primary;
    final localizations = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: series.length,
          itemBuilder: (context, index) {
            final entry = series[index];
            final ratio = maxSeconds == 0
                ? 0.0
                : entry.totalSeconds / maxSeconds;
            final color = Color.lerp(base, active, ratio.clamp(0.0, 1.0))!;
            final label = localizations.formatShortDate(entry.date);
            final duration = _formatDuration(entry.totalSeconds);
            return Tooltip(
              message: '$label • $duration',
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    entry.date.day.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Less', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              final ratio = index / 4;
              final color = Color.lerp(base, active, ratio)!;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text('More', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _CompanyTotalsSection extends StatelessWidget {
  const _CompanyTotalsSection({
    required this.workSessionRepository,
    required this.companyRepository,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: workSessionRepository.watchSessions(),
      initialData: const <WorkSessionModel>[],
      builder: (context, sessionSnapshot) {
        final sessions = sessionSnapshot.data ?? const <WorkSessionModel>[];
        return StreamBuilder(
          stream: companyRepository.watchCompanies(),
          initialData: const <CompanyModel>[],
          builder: (context, companySnapshot) {
            final companies = companySnapshot.data ?? const <CompanyModel>[];
            final totals = _buildCompanyTotals(sessions);
            if (totals.isEmpty) {
              return const SizedBox.shrink();
            }

            final companyById = {
              for (final company in companies) company.id: company,
            };

            final items =
                totals.entries
                    .map(
                      (entry) => _CompanyTotal(
                        companyId: entry.key,
                        seconds: entry.value,
                      ),
                    )
                    .toList(growable: false)
                  ..sort((a, b) => b.seconds.compareTo(a.seconds));

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This month by company',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final company = companyById[item.companyId];
                      final color = company == null
                          ? Theme.of(context).colorScheme.primary
                          : Color(company.colorCode);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 8, backgroundColor: color),
                                const SizedBox(width: 8),
                                Text(company?.name ?? 'Unknown'),
                              ],
                            ),
                            Text(_formatDuration(item.seconds)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, int> _buildCompanyTotals(List<WorkSessionModel> sessions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final totals = <String, int>{};
    for (final session in sessions) {
      final start = session.startTime;
      if (start.isBefore(monthStart) || !start.isBefore(nextMonth)) {
        continue;
      }
      final durationSeconds = _sessionDurationSeconds(session);
      totals[session.companyId] =
          (totals[session.companyId] ?? 0) + durationSeconds;
    }
    return totals;
  }
}

class _CompanyTotal {
  const _CompanyTotal({required this.companyId, required this.seconds});

  final String companyId;
  final int seconds;
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({
    required this.workSessionRepository,
    required this.companyRepository,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No sessions yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Start tracking or add one manually.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrackerPage(
                    workSessionRepository: workSessionRepository,
                    companyRepository: companyRepository,
                  ),
                ),
              ),
              child: const Text('Start tracker'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkSessionEntryPage(
                    workSessionRepository: workSessionRepository,
                    companyRepository: companyRepository,
                  ),
                ),
              ),
              child: const Text('Add manual session'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _SeriesSection extends StatelessWidget {
  const _SeriesSection({required this.title, required this.series});

  final String title;
  final List<DayWorkSummary> series;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (series.isEmpty)
          const Text('No data yet.')
        else
          ...series.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(localizations.formatShortDate(entry.date)),
                  Text(_formatDuration(entry.totalSeconds)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours <= 0) {
    return '${minutes}m';
  }
  return '${hours}h ${minutes}m';
}

int _sessionDurationSeconds(WorkSessionModel session) {
  final endTime = session.endTime ?? DateTime.now();
  return endTime.difference(session.startTime).inSeconds;
}
