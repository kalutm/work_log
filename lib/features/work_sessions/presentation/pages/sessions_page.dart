import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/export/presentation/pages/export_preview_page.dart';
import 'package:time_tracker/features/tracker/presentation/pages/tracker_page.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_sessions_bloc.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_sessions_event.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_sessions_state.dart';
import 'package:time_tracker/features/work_sessions/presentation/pages/work_session_detail_page.dart';
import 'package:time_tracker/features/work_sessions/presentation/pages/work_session_entry_page.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({
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
          WorkSessionsBloc(workSessionRepository)
            ..add(const WorkSessionsWatchRequested()),
      child: SessionsView(
        workSessionRepository: workSessionRepository,
        companyRepository: companyRepository,
      ),
    );
  }
}

class SessionsView extends StatefulWidget {
  const SessionsView({
    super.key,
    required this.workSessionRepository,
    required this.companyRepository,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  State<SessionsView> createState() => _SessionsViewState();
}

class _SessionsViewState extends State<SessionsView> {
  String? _companyFilterId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _notesQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CompanyModel>>(
      stream: widget.companyRepository.watchCompanies(),
      initialData: const <CompanyModel>[],
      builder: (context, snapshot) {
        final companies = snapshot.data ?? const <CompanyModel>[];
        final companyById = {
          for (final company in companies) company.id: company,
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sessions'),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'Export preview',
                onPressed: () => _openExport(context),
              ),
            ],
          ),
          body: BlocConsumer<WorkSessionsBloc, WorkSessionsState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == WorkSessionsStatus.failure &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            },
            builder: (context, state) {
              if (state.status == WorkSessionsStatus.loading &&
                  state.sessions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.sessions.isEmpty) {
                return _SessionsEmptyState(
                  workSessionRepository: widget.workSessionRepository,
                  companyRepository: widget.companyRepository,
                );
              }

              final sessions = List<WorkSessionModel>.from(state.sessions)
                ..sort((a, b) => b.startTime.compareTo(a.startTime));
              final filteredSessions = _applyFilters(sessions);
              final hasFilters = _hasFilters;

              if (filteredSessions.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFilters(companies),
                    const SizedBox(height: 16),
                    Text(
                      'No sessions match your filters.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (hasFilters) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredSessions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        _buildFilters(companies),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  final session = filteredSessions[index - 1];
                  final isActive = session.endTime == null;
                  final companyName =
                      companyById[session.companyId]?.name ?? 'Unknown';
                  final range = _formatRange(context, session);
                  final durationSeconds = _sessionDurationSeconds(session);
                  final duration = _formatDuration(durationSeconds);

                  return Card(
                    child: ListTile(
                      onTap: () => _openDetail(context, session),
                      title: Text(companyName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$range | $duration'),
                          if (isActive) ...[
                            const SizedBox(height: 4),
                            Chip(
                              label: const Text('ACTIVE'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditor(context, session),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _confirmDelete(context, session),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openEditor(context, null),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildFilters(List<CompanyModel> companies) {
    final localizations = MaterialLocalizations.of(context);
    final hasFilters = _hasFilters;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String?>(
              value: _companyFilterId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All companies'),
                ),
                ...companies.map(
                  (company) => DropdownMenuItem<String?>(
                    value: company.id,
                    child: Text(company.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _companyFilterId = value),
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Last 7 days'),
                  selected: _isPresetSelected(7),
                  onSelected: (_) => _applyPreset(7),
                ),
                ChoiceChip(
                  label: const Text('Last 30 days'),
                  selected: _isPresetSelected(30),
                  onSelected: (_) => _applyPreset(30),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search notes',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _notesQuery = value.trim()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickStartDate,
                    child: Text(
                      'Start: ${_formatFilterDate(localizations, _startDate)}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickEndDate,
                    child: Text(
                      'End: ${_formatFilterDate(localizations, _endDate)}',
                    ),
                  ),
                ),
              ],
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear filters'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<WorkSessionModel> _applyFilters(List<WorkSessionModel> sessions) {
    final query = _notesQuery?.toLowerCase();
    return sessions
        .where((session) {
          if (_companyFilterId != null &&
              session.companyId != _companyFilterId) {
            return false;
          }
          final sessionDay = _dateOnly(session.startTime);
          if (_startDate != null && sessionDay.isBefore(_startDate!)) {
            return false;
          }
          if (_endDate != null && sessionDay.isAfter(_endDate!)) {
            return false;
          }
          if (query != null && query.isNotEmpty) {
            final notes = (session.notes ?? '').toLowerCase();
            if (!notes.contains(query)) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  bool get _hasFilters {
    final hasNotes = _notesQuery != null && _notesQuery!.isNotEmpty;
    return _companyFilterId != null ||
        _startDate != null ||
        _endDate != null ||
        hasNotes;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }
    final start = _dateOnly(picked);
    setState(() {
      _startDate = start;
      if (_endDate != null && _endDate!.isBefore(start)) {
        _endDate = start;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _endDate ?? _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }
    final end = _dateOnly(picked);
    setState(() {
      _endDate = end;
      if (_startDate != null && _startDate!.isAfter(end)) {
        _startDate = end;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _companyFilterId = null;
      _startDate = null;
      _endDate = null;
      _notesQuery = null;
    });
  }

  void _applyPreset(int days) {
    final end = _dateOnly(DateTime.now());
    final start = end.subtract(Duration(days: days - 1));
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  bool _isPresetSelected(int days) {
    if (_startDate == null || _endDate == null) {
      return false;
    }
    final end = _dateOnly(DateTime.now());
    final start = end.subtract(Duration(days: days - 1));
    return _startDate == start && _endDate == end;
  }

  void _openEditor(BuildContext context, WorkSessionModel? session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkSessionEntryPage(
          workSessionRepository: widget.workSessionRepository,
          companyRepository: widget.companyRepository,
          initialSession: session,
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, WorkSessionModel session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkSessionDetailPage(
          session: session,
          workSessionRepository: widget.workSessionRepository,
          companyRepository: widget.companyRepository,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WorkSessionModel session,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      context.read<WorkSessionsBloc>().add(
        WorkSessionDeleteRequested(session.id),
      );
    }
  }

  void _openExport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExportPreviewPage(
          workSessionRepository: widget.workSessionRepository,
          companyRepository: widget.companyRepository,
        ),
      ),
    );
  }
}

String _formatFilterDate(MaterialLocalizations localizations, DateTime? date) {
  if (date == null) {
    return 'Any';
  }
  return localizations.formatShortDate(date);
}

DateTime _dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

class _SessionsEmptyState extends StatelessWidget {
  const _SessionsEmptyState({
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
