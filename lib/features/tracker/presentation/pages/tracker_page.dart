import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/core/settings/app_settings.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_bloc.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_event.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_state.dart';
import 'package:time_tracker/features/companies/presentation/pages/companies_page.dart';
import 'package:time_tracker/features/tracker/presentation/bloc/tracker_bloc.dart';
import 'package:time_tracker/features/tracker/presentation/bloc/tracker_event.dart';
import 'package:time_tracker/features/tracker/presentation/bloc/tracker_state.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';

class TrackerPage extends StatelessWidget {
  const TrackerPage({
    super.key,
    required this.workSessionRepository,
    required this.companyRepository,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              CompaniesBloc(companyRepository)
                ..add(const CompaniesWatchRequested()),
        ),
        BlocProvider(
          create: (_) =>
              TrackerBloc(workSessionRepository)..add(const TrackerStarted()),
        ),
      ],
      child: TrackerView(companyRepository: companyRepository),
    );
  }
}

class TrackerView extends StatefulWidget {
  const TrackerView({super.key, required this.companyRepository});

  final CompanyRepository companyRepository;

  @override
  State<TrackerView> createState() => _TrackerViewState();
}

class _TrackerViewState extends State<TrackerView> {
  final TextEditingController _notesController = TextEditingController();
  final AppSettings _settings = AppSettingsHive.fromHive();
  StreamSubscription<String?>? _defaultCompanySubscription;

  @override
  void initState() {
    super.initState();
    _defaultCompanySubscription = _settings.watchDefaultCompanyId().listen(
      _handleDefaultCompanyChange,
    );
  }

  @override
  void dispose() {
    _defaultCompanySubscription?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TrackerBloc, TrackerState>(
          listenWhen: (previous, current) =>
              previous.activeSession?.id != current.activeSession?.id,
          listener: (context, state) {
            _notesController.text = state.activeSession?.notes ?? '';
          },
        ),
        BlocListener<TrackerBloc, TrackerState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == TrackerStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Tracker')),
        body: BlocBuilder<TrackerBloc, TrackerState>(
          builder: (context, trackerState) {
            final isActive = trackerState.activeSession != null;
            final elapsed = _formatElapsed(trackerState.elapsedSeconds);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    elapsed,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<CompaniesBloc, CompaniesState>(
                    builder: (context, companiesState) {
                      if (companiesState.companies.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Add a company to start tracking.',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CompaniesPage(
                                    repository: widget.companyRepository,
                                  ),
                                ),
                              ),
                              child: const Text('Add company'),
                            ),
                          ],
                        );
                      }
                      final selection = isActive
                          ? trackerState.activeSession?.companyId
                          : companiesState.selectedCompanyId;
                      return DropdownButtonFormField<String>(
                        value: selection,
                        items: companiesState.companies
                            .map(
                              (company) => DropdownMenuItem<String>(
                                value: company.id,
                                child: Text(company.name),
                              ),
                            )
                            .toList(),
                        onChanged: isActive
                            ? null
                            : (value) => context.read<CompaniesBloc>().add(
                                CompanySelected(value),
                              ),
                        decoration: const InputDecoration(labelText: 'Company'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: trackerState.status == TrackerStatus.loading
                        ? null
                        : () => _handlePrimaryAction(context, trackerState),
                    child: Text(isActive ? 'Check Out' : 'Check In'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handlePrimaryAction(BuildContext context, TrackerState trackerState) {
    final trackerBloc = context.read<TrackerBloc>();
    if (trackerState.activeSession != null) {
      trackerBloc.add(TrackerCheckOutRequested(notes: _notesController.text));
      return;
    }

    final companiesState = context.read<CompaniesBloc>().state;
    final selectedCompanyId = companiesState.selectedCompanyId;
    if (selectedCompanyId == null || selectedCompanyId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a company first.')));
      return;
    }

    trackerBloc.add(
      TrackerCheckInRequested(
        companyId: selectedCompanyId,
        notes: _notesController.text,
      ),
    );
  }

  void _handleDefaultCompanyChange(String? companyId) {
    if (!mounted || companyId == null || companyId.isEmpty) {
      return;
    }

    final trackerState = context.read<TrackerBloc>().state;
    if (trackerState.activeSession != null) {
      return;
    }

    final companiesBloc = context.read<CompaniesBloc>();
    if (companiesBloc.state.selectedCompanyId == companyId) {
      return;
    }

    companiesBloc.add(CompanySelected(companyId));
  }
}

String _formatElapsed(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$secs';
}
