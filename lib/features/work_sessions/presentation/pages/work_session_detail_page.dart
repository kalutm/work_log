import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_sessions_bloc.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_sessions_event.dart';
import 'package:time_tracker/features/work_sessions/presentation/pages/work_session_entry_page.dart';

class WorkSessionDetailPage extends StatelessWidget {
  const WorkSessionDetailPage({
    super.key,
    required this.session,
    required this.workSessionRepository,
    required this.companyRepository,
    this.company,
  });

  final WorkSessionModel session;
  final CompanyModel? company;
  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  Widget build(BuildContext context) {
    final endTime = session.endTime;
    final durationSeconds = endTime == null
        ? DateTime.now().difference(session.startTime).inSeconds
        : (session.durationInSeconds > 0
              ? session.durationInSeconds
              : endTime.difference(session.startTime).inSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit session',
            onPressed: () => _openEditor(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete session',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            title: 'Company',
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: company == null
                      ? Theme.of(context).colorScheme.primary
                      : Color(company!.colorCode),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(company?.name ?? 'Unknown')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Time',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start: ${_formatDateTime(context, session.startTime)}'),
                const SizedBox(height: 4),
                Text(
                  'End: ${endTime == null ? 'Active' : _formatDateTime(context, endTime)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Duration',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDuration(durationSeconds)),
                const SizedBox(height: 4),
                Text('$durationSeconds seconds'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Notes',
            child: Text(
              session.notes?.trim().isNotEmpty == true
                  ? session.notes!
                  : 'No notes.',
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkSessionEntryPage(
          workSessionRepository: workSessionRepository,
          companyRepository: companyRepository,
          initialSession: session,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
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

    if (shouldDelete != true) {
      return;
    }

    try {
      WorkSessionsBloc? bloc;
      try {
        bloc = BlocProvider.of<WorkSessionsBloc>(context, listen: false);
      } catch (_) {
        bloc = null;
      }
      if (bloc != null) {
        bloc.add(WorkSessionDeleteRequested(session.id));
      } else {
        await workSessionRepository.deleteSession(session.id);
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session deleted.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
            child,
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(BuildContext context, DateTime dateTime) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatShortDate(dateTime);
  final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(dateTime));
  return '$date $time';
}

String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final secs = duration.inSeconds.remainder(60);
  if (hours <= 0 && minutes <= 0) {
    return '${secs}s';
  }
  if (hours <= 0) {
    return '${minutes}m ${secs}s';
  }
  return '${hours}h ${minutes}m';
}
