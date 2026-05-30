import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

class ExportFormatter {
  static const List<String> header = <String>[
    'session_id',
    'company_id',
    'company_name',
    'start_time',
    'end_time',
    'duration_seconds',
    'notes',
  ];

  static List<List<String>> buildRows({
    required List<WorkSessionModel> sessions,
    required List<CompanyModel> companies,
    DateTime? now,
  }) {
    final nowValue = now ?? DateTime.now();
    final companyById = {for (final company in companies) company.id: company};

    final rows = <List<String>>[header];
    for (final session in sessions) {
      final companyName = companyById[session.companyId]?.name ?? 'Unknown';
      final endTime = session.endTime;
      final durationSeconds = endTime == null
          ? nowValue.difference(session.startTime).inSeconds
          : (session.durationInSeconds > 0
                ? session.durationInSeconds
                : endTime.difference(session.startTime).inSeconds);

      rows.add(<String>[
        session.id,
        session.companyId,
        companyName,
        session.startTime.toIso8601String(),
        endTime?.toIso8601String() ?? '',
        durationSeconds.toString(),
        session.notes ?? '',
      ]);
    }

    return rows;
  }

  static String toCsv(List<List<String>> rows) {
    return rows.map(_rowToCsv).join('\n');
  }

  static String _rowToCsv(List<String> row) {
    return row.map(_escape).join(',');
  }

  static String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    final needsQuotes =
        escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
