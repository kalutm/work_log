import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_session_form_bloc.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_session_form_event.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_session_form_state.dart';

class WorkSessionFormPage extends StatelessWidget {
  const WorkSessionFormPage({
    super.key,
    required this.repository,
    required this.companies,
    this.initialSession,
  });

  final WorkSessionRepository repository;
  final List<CompanyModel> companies;
  final WorkSessionModel? initialSession;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WorkSessionFormBloc(repository)
            ..add(WorkSessionFormInitialized(session: initialSession)),
      child: WorkSessionFormView(companies: companies),
    );
  }
}

class WorkSessionFormView extends StatelessWidget {
  const WorkSessionFormView({super.key, required this.companies});

  final List<CompanyModel> companies;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Session')),
      body: BlocConsumer<WorkSessionFormBloc, WorkSessionFormState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == WorkSessionFormStatus.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Session saved.')));
          } else if (state.status == WorkSessionFormStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final bloc = context.read<WorkSessionFormBloc>();
          final isSaving = state.status == WorkSessionFormStatus.saving;
          final hasRequired =
              (state.companyId != null && state.companyId!.isNotEmpty) &&
              state.startTime != null &&
              state.endTime != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: state.companyId,
                  items: companies
                      .map(
                        (company) => DropdownMenuItem<String>(
                          value: company.id,
                          child: Text(company.name),
                        ),
                      )
                      .toList(),
                  onChanged: companies.isEmpty
                      ? null
                      : (value) => bloc.add(WorkSessionCompanyChanged(value)),
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                const SizedBox(height: 16),
                _DateTimeField(
                  label: 'Start time',
                  value: state.startTime,
                  onChanged: (value) =>
                      bloc.add(WorkSessionStartTimeChanged(value)),
                ),
                const SizedBox(height: 16),
                _DateTimeField(
                  label: 'End time',
                  value: state.endTime,
                  onChanged: (value) =>
                      bloc.add(WorkSessionEndTimeChanged(value)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(state.sessionId ?? 'new-session'),
                  initialValue: state.notes ?? '',
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  onChanged: (value) =>
                      bloc.add(WorkSessionNotesChanged(value)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSaving || !hasRequired
                      ? null
                      : () => bloc.add(const WorkSessionFormSubmitted()),
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
                if (!hasRequired) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Select a company and time range to save.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (state.sessionId != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () =>
                              bloc.add(const WorkSessionFormDeleteRequested()),
                    child: const Text('Delete'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? 'Select'
        : _formatDateTime(context, value!);

    return OutlinedButton(
      onPressed: () async {
        final picked = await _pickDateTime(context, value);
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(formatted)],
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(dateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );
    return '$date $time';
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime? initialDateTime,
  ) async {
    final now = DateTime.now();
    final initial = initialDateTime ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
