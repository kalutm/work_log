import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/companies/presentation/pages/companies_page.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_session_form_bloc.dart';
import 'package:time_tracker/features/work_sessions/presentation/bloc/work_session_form_event.dart';
import 'package:time_tracker/features/work_sessions/presentation/pages/work_session_form_page.dart';

class WorkSessionEntryPage extends StatefulWidget {
  const WorkSessionEntryPage({
    super.key,
    required this.workSessionRepository,
    required this.companyRepository,
    this.initialSession,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;
  final WorkSessionModel? initialSession;

  @override
  State<WorkSessionEntryPage> createState() => _WorkSessionEntryPageState();
}

class _WorkSessionEntryPageState extends State<WorkSessionEntryPage> {
  late final WorkSessionFormBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = WorkSessionFormBloc(widget.workSessionRepository)
      ..add(WorkSessionFormInitialized(session: widget.initialSession));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CompanyModel>>(
      stream: widget.companyRepository.watchCompanies(),
      initialData: const <CompanyModel>[],
      builder: (context, snapshot) {
        final companies = snapshot.data ?? const <CompanyModel>[];
        if (companies.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manual entry')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add a company before logging a session.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
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
                ),
              ),
            ),
          );
        }
        return BlocProvider.value(
          value: _bloc,
          child: WorkSessionFormView(companies: companies),
        );
      },
    );
  }
}
