import 'package:flutter/material.dart';

import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/companies/presentation/pages/companies_page.dart';
import 'package:time_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:time_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:time_tracker/features/tracker/presentation/pages/tracker_page.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';
import 'package:time_tracker/features/work_sessions/presentation/pages/work_session_entry_page.dart';
import 'package:time_tracker/features/work_sessions/presentation/pages/sessions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.workSessionRepository,
    required this.companyRepository,
    required this.themeModeNotifier,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TrackerPage(
            workSessionRepository: widget.workSessionRepository,
            companyRepository: widget.companyRepository,
          ),
          DashboardPage(
            workSessionRepository: widget.workSessionRepository,
            companyRepository: widget.companyRepository,
          ),
          WorkSessionEntryPage(
            workSessionRepository: widget.workSessionRepository,
            companyRepository: widget.companyRepository,
          ),
          SessionsPage(
            workSessionRepository: widget.workSessionRepository,
            companyRepository: widget.companyRepository,
          ),
          CompaniesPage(repository: widget.companyRepository),
          SettingsPage(
            companyRepository: widget.companyRepository,
            themeModeNotifier: widget.themeModeNotifier,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (value) => setState(() => _index = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Tracker'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar),
            label: 'Manual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Sessions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Companies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
