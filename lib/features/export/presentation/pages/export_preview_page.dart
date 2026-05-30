import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:time_tracker/core/settings/app_settings.dart';
import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/export/domain/csv_importer.dart';
import 'package:time_tracker/features/export/domain/export_formatter.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';

class ExportPreviewPage extends StatefulWidget {
  const ExportPreviewPage({
    super.key,
    required this.workSessionRepository,
    required this.companyRepository,
  });

  final WorkSessionRepository workSessionRepository;
  final CompanyRepository companyRepository;

  @override
  State<ExportPreviewPage> createState() => _ExportPreviewPageState();
}

class _ExportPreviewPageState extends State<ExportPreviewPage> {
  late DateTime _selectedMonth;
  late Future<_ExportData> _dataFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _dataFuture = _loadData();
  }

  Future<_ExportData> _loadData() async {
    final sessions = await widget.workSessionRepository.getSessionsForMonth(
      _selectedMonth,
    );
    final companies = await widget.companyRepository.getAllCompanies();
    return _ExportData(sessions: sessions, companies: companies);
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Export preview - ${localizations.formatMonthYear(_selectedMonth)}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Pick month',
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: FutureBuilder<_ExportData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load export preview.'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No export data.'));
          }

          final companyById = {
            for (final company in data.companies) company.id: company,
          };
          final sessions = List<WorkSessionModel>.from(data.sessions)
            ..sort((a, b) => b.startTime.compareTo(a.startTime));
          final totalSeconds = sessions.fold<int>(
            0,
            (sum, session) => sum + _sessionDurationSeconds(session),
          );
          final csvRows = ExportFormatter.buildRows(
            sessions: sessions,
            companies: data.companies,
            now: DateTime.now(),
          );
          final fullCsv = ExportFormatter.toCsv(csvRows);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'Total time',
                value: _formatDuration(totalSeconds),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Sessions',
                value: sessions.length.toString(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _importCsv(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: sessions.isEmpty
                      ? null
                      : () => _shareCsv(context, fullCsv, _selectedMonth),
                  icon: const Icon(Icons.share),
                  label: const Text('Share CSV'),
                ),
              ),
              const SizedBox(height: 16),
              if (sessions.isEmpty)
                const Text('No sessions for this month.')
              else
                ...sessions.map((session) {
                  final companyName =
                      companyById[session.companyId]?.name ?? 'Unknown';
                  final range = _formatRange(context, session);
                  final duration = _formatDuration(
                    _sessionDurationSeconds(session),
                  );
                  return Card(
                    child: ListTile(
                      title: Text(companyName),
                      subtitle: Text('$range | $duration'),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ExportData {
  const _ExportData({required this.sessions, required this.companies});

  final List<WorkSessionModel> sessions;
  final List<CompanyModel> companies;
}

Future<void> _importCsv(BuildContext context) async {
  final shouldImport = await _confirmImport(context);
  if (!shouldImport) {
    return;
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return;
  }

  final file = result.files.single;
  final csvText = file.bytes != null
      ? utf8.decode(file.bytes!, allowMalformed: true)
      : (file.path == null ? null : await File(file.path!).readAsString());
  if (csvText == null || csvText.trim().isEmpty) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV file is empty.')));
    return;
  }

  if (!context.mounted) {
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final parsed = CsvImporter.parse(csvText);
    await _replaceAllData(context, parsed);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    final message = parsed.skippedRows > 0
        ? 'Imported ${parsed.sessions.length} sessions and ${parsed.companies.length} companies. Skipped ${parsed.skippedRows} rows.'
        : 'Imported ${parsed.sessions.length} sessions and ${parsed.companies.length} companies.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Import failed: $error')));
  }
}

Future<bool> _confirmImport(BuildContext context) async {
  final workSessionRepository = _findWorkSessionRepository(context);
  final companyRepository = _findCompanyRepository(context);
  if (workSessionRepository == null || companyRepository == null) {
    return false;
  }
  final sessions = await workSessionRepository.getAllSessions();
  final companies = await companyRepository.getAllCompanies();
  if (sessions.isEmpty && companies.isEmpty) {
    return true;
  }

  if (!context.mounted) {
    return false;
  }

  final sessionCount = sessions.length;
  final companyCount = companies.length;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Replace current data?'),
      content: Text(
        'Importing will overwrite your existing $sessionCount sessions and $companyCount companies. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Import'),
        ),
      ],
    ),
  );

  return result ?? false;
}

Future<void> _replaceAllData(
  BuildContext context,
  CsvImportResult parsed,
) async {
  final workSessionRepository = _findWorkSessionRepository(context);
  final companyRepository = _findCompanyRepository(context);
  if (workSessionRepository == null || companyRepository == null) {
    return;
  }

  final existingSessions = await workSessionRepository.getAllSessions();
  for (final session in existingSessions) {
    await workSessionRepository.deleteSession(session.id);
  }

  final existingCompanies = await companyRepository.getAllCompanies();
  for (final company in existingCompanies) {
    await companyRepository.deleteCompany(company.id);
  }

  for (final company in parsed.companies) {
    await companyRepository.upsertCompany(company);
  }

  for (final session in parsed.sessions) {
    await workSessionRepository.upsertSession(session);
  }

  final settings = AppSettingsHive.fromHive();
  final defaultId = await settings.getDefaultCompanyId();
  final hasDefault = parsed.companies.any((company) => company.id == defaultId);
  if (defaultId != null && !hasDefault) {
    await settings.setDefaultCompanyId(null);
  }
}

WorkSessionRepository? _findWorkSessionRepository(BuildContext context) {
  final widget = context.findAncestorWidgetOfExactType<ExportPreviewPage>();
  return widget?.workSessionRepository;
}

CompanyRepository? _findCompanyRepository(BuildContext context) {
  final widget = context.findAncestorWidgetOfExactType<ExportPreviewPage>();
  return widget?.companyRepository;
}

Future<File> _writeCsvFile(String csv, DateTime selectedMonth) async {
  final directory = await getApplicationDocumentsDirectory();
  final month = selectedMonth.month.toString().padLeft(2, '0');
  final filename = 'work_log_${selectedMonth.year}_$month.csv';
  final file = File('${directory.path}/$filename');
  await file.writeAsString(csv);
  return file;
}

Future<void> _shareCsv(
  BuildContext context,
  String csv,
  DateTime selectedMonth,
) async {
  try {
    final file = await _writeCsvFile(csv, selectedMonth);
    await Share.shareXFiles([XFile(file.path)], text: 'Time Tracker export');
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Share failed: $error')));
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
