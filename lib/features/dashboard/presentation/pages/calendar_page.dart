import 'package:flutter/material.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/pages/work_session_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.workSessionRepository,
    required this.companyRepository,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = _dateOnly(now);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkSessionModel>>(
      stream: widget.workSessionRepository.watchSessions(),
      initialData: const <WorkSessionModel>[],
      builder: (context, sessionSnapshot) {
        final sessions = sessionSnapshot.data ?? const <WorkSessionModel>[];
        return StreamBuilder<List<CompanyModel>>(
          stream: widget.companyRepository.watchCompanies(),
          initialData: const <CompanyModel>[],
          builder: (context, companySnapshot) {
            final companies = companySnapshot.data ?? const <CompanyModel>[];
            final companyById = {
              for (final company in companies) company.id: company,
            };

            final sessionCounts = _buildSessionCounts(sessions);
            final selectedDay = _selectedDay ?? _dateOnly(DateTime.now());
            final sessionsForDay =
                sessions
                    .where(
                      (session) => _dateOnly(session.startTime) == selectedDay,
                    )
                    .toList(growable: false)
                  ..sort((a, b) => b.startTime.compareTo(a.startTime));
            final dayTotalSeconds = sessionsForDay.fold<int>(
              0,
              (sum, session) => sum + _sessionDurationSeconds(session),
            );
            final sessionsForMonth = sessions
                .where(
                  (session) =>
                      session.startTime.year == _focusedMonth.year &&
                      session.startTime.month == _focusedMonth.month,
                )
                .toList(growable: false);
            final monthTotalSeconds = sessionsForMonth.fold<int>(
              0,
              (sum, session) => sum + _sessionDurationSeconds(session),
            );

            return Scaffold(
              appBar: AppBar(title: const Text('Calendar')),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SummaryStat(
                            label: 'Month total',
                            value: _formatDuration(monthTotalSeconds),
                          ),
                          _SummaryStat(
                            label: 'Sessions',
                            value: sessionsForMonth.length.toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeekdayHeader(context),
                  const SizedBox(height: 8),
                  _buildCalendarGrid(sessionCounts),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sessions on ${_formatDay(context, selectedDay)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (sessionsForDay.isNotEmpty)
                        Text(
                          _formatDuration(dayTotalSeconds),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                    ],
                  ),
                  if (sessionsForDay.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${sessionsForDay.length} sessions',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (sessionsForDay.isEmpty)
                    const Text('No sessions for this day.')
                  else
                    ...sessionsForDay.map((session) {
                      final company = companyById[session.companyId];
                      final isActive = session.endTime == null;
                      final duration = _formatDuration(
                        _sessionDurationSeconds(session),
                      );
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: company == null
                                ? Theme.of(context).colorScheme.primary
                                : Color(company.colorCode),
                          ),
                          title: Text(company?.name ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_formatRange(context, session)} | $duration',
                              ),
                              if (isActive) ...[
                                const SizedBox(height: 4),
                                Chip(
                                  label: const Text('ACTIVE'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ],
                          ),
                          onTap: () => _openDetail(context, session, company),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openDetail(
    BuildContext context,
    WorkSessionModel session,
    CompanyModel? company,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkSessionDetailPage(
          session: session,
          company: company,
          workSessionRepository: widget.workSessionRepository,
          companyRepository: widget.companyRepository,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          localizations.formatMonthYear(_focusedMonth),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final weekDays = localizations.narrowWeekdays;
    final firstDayIndex = localizations.firstDayOfWeekIndex;
    final ordered = List<String>.generate(
      7,
      (index) => weekDays[(firstDayIndex + index) % 7],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ordered
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, int> sessionCounts) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final localizations = MaterialLocalizations.of(context);
    final firstDayIndex = localizations.firstDayOfWeekIndex;
    final weekdayIndex = firstDay.weekday % 7;
    final leading = (weekdayIndex - firstDayIndex + 7) % 7;
    final totalCells = leading + daysInMonth;
    final rowCount = ((totalCells + 6) / 7).floor();
    final totalSlots = rowCount * 7;

    final cells = List<DateTime?>.generate(totalSlots, (index) {
      final dayNumber = index - leading + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return null;
      }
      return DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final day = cells[index];
        if (day == null) {
          return const SizedBox.shrink();
        }

        final dayKey = _dateOnly(day);
        final isSelected =
            _selectedDay != null && _dateOnly(_selectedDay!) == dayKey;
        final isToday = _dateOnly(DateTime.now()) == dayKey;
        final count = sessionCounts[dayKey] ?? 0;
        final hasSessions = count > 0;
        final scheme = Theme.of(context).colorScheme;
        final background = isSelected
            ? scheme.primaryContainer
            : isToday
            ? scheme.secondaryContainer.withOpacity(0.6)
            : null;
        final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? scheme.onPrimaryContainer : null,
        );

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = dayKey),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(
                color: isToday ? scheme.primary : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(day.day.toString(), style: textStyle),
                const SizedBox(height: 4),
                if (hasSessions)
                  count > 1
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.onSecondary),
                          ),
                        )
                      : Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _previousMonth() {
    final previous = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    _setFocusedMonth(previous);
  }

  void _nextMonth() {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    _setFocusedMonth(next);
  }

  void _setFocusedMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    setState(() {
      _focusedMonth = normalized;
      if (_selectedDay == null ||
          _selectedDay!.year != normalized.year ||
          _selectedDay!.month != normalized.month) {
        _selectedDay = DateTime(normalized.year, normalized.month, 1);
      }
    });
  }

  Map<DateTime, int> _buildSessionCounts(List<WorkSessionModel> sessions) {
    final counts = <DateTime, int>{};
    for (final session in sessions) {
      final day = _dateOnly(session.startTime);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

String _formatDay(BuildContext context, DateTime dateTime) {
  final localizations = MaterialLocalizations.of(context);
  return localizations.formatFullDate(dateTime);
}

String _formatRange(BuildContext context, WorkSessionModel session) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatShortDate(session.startTime);
  final startTime = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(session.startTime),
  );
  final endTime = session.endTime == null
      ? 'Active'
      : localizations.formatTimeOfDay(TimeOfDay.fromDateTime(session.endTime!));
  return '$date $startTime - $endTime';
}

int _sessionDurationSeconds(WorkSessionModel session) {
  final endTime = session.endTime ?? DateTime.now();
  return endTime.difference(session.startTime).inSeconds;
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

DateTime _dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}
