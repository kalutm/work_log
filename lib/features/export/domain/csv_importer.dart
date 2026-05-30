import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/export/domain/export_formatter.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

class CsvImportResult {
  const CsvImportResult({
    required this.companies,
    required this.sessions,
    required this.skippedRows,
  });

  final List<CompanyModel> companies;
  final List<WorkSessionModel> sessions;
  final int skippedRows;
}

class CsvImporter {
  static const List<int> _colorPalette = <int>[
    0xFF2196F3,
    0xFF4CAF50,
    0xFFFF9800,
    0xFF9C27B0,
    0xFFF44336,
    0xFF009688,
  ];

  static CsvImportResult parse(String csv) {
    final rows = _parseCsv(csv);
    if (rows.isEmpty) {
      throw const FormatException('CSV is empty.');
    }

    final header = rows.first
        .map((cell) => cell.trim())
        .toList(growable: false);
    if (header.isEmpty) {
      throw const FormatException('CSV header is missing.');
    }
    header[0] = header[0].replaceFirst('\uFEFF', '');

    final columnIndex = <String, int>{
      for (var i = 0; i < header.length; i++) header[i]: i,
    };

    final missing = ExportFormatter.header
        .where((name) => !columnIndex.containsKey(name))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw FormatException('Missing columns: ${missing.join(', ')}');
    }

    final companiesByKey = <String, CompanyModel>{};
    final sessions = <WorkSessionModel>[];
    var skipped = 0;

    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      final sessionIdRaw = _cell(row, columnIndex['session_id']!);
      final companyIdRaw = _cell(row, columnIndex['company_id']!);
      final companyNameRaw = _cell(row, columnIndex['company_name']!);
      final startRaw = _cell(row, columnIndex['start_time']!);
      final endRaw = _cell(row, columnIndex['end_time']!);
      final durationRaw = _cell(row, columnIndex['duration_seconds']!);
      final notesRaw = _cell(row, columnIndex['notes']!);

      final startTime = _tryParseDate(startRaw);
      if (startTime == null) {
        skipped += 1;
        continue;
      }

      final endTime = _tryParseDate(endRaw);
      final durationSeconds = _resolveDuration(durationRaw, startTime, endTime);

      final companyName = companyNameRaw.trim();
      final companyId = companyIdRaw.trim();
      if (companyId.isEmpty && companyName.isEmpty) {
        skipped += 1;
        continue;
      }

      final companyKey = companyId.isNotEmpty
          ? 'id:$companyId'
          : 'name:${companyName.toLowerCase()}';
      final company = companiesByKey.putIfAbsent(companyKey, () {
        final index = companiesByKey.length;
        return CompanyModel(
          id: companyId.isNotEmpty
              ? companyId
              : _generateCompanyId(companyName, index),
          name: companyName.isNotEmpty
              ? companyName
              : 'Imported Company ${index + 1}',
          colorCode: _colorPalette[index % _colorPalette.length],
          hourlyRate: null,
        );
      });

      sessions.add(
        WorkSessionModel(
          id: sessionIdRaw.trim().isEmpty
              ? _generateSessionId(rowIndex)
              : sessionIdRaw.trim(),
          companyId: company.id,
          startTime: startTime,
          endTime: endTime,
          durationInSeconds: durationSeconds,
          notes: notesRaw.trim().isEmpty ? null : notesRaw,
        ),
      );
    }

    return CsvImportResult(
      companies: companiesByKey.values.toList(growable: false),
      sessions: sessions,
      skippedRows: skipped,
    );
  }

  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final row = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          buffer.write('"');
          i += 1;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && (char == ',')) {
        row.add(buffer.toString());
        buffer.clear();
        continue;
      }

      if (!inQuotes && (char == '\n' || char == '\r')) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i += 1;
        }
        row.add(buffer.toString());
        buffer.clear();
        rows.add(List<String>.from(row));
        row.clear();
        continue;
      }

      buffer.write(char);
    }

    row.add(buffer.toString());
    if (row.any((cell) => cell.isNotEmpty)) {
      rows.add(row);
    }

    return rows;
  }

  static String _cell(List<String> row, int index) {
    if (index < 0 || index >= row.length) {
      return '';
    }
    return row[index];
  }

  static DateTime? _tryParseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  static int _resolveDuration(
    String raw,
    DateTime startTime,
    DateTime? endTime,
  ) {
    final parsed = int.tryParse(raw.trim());
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    if (endTime == null) {
      return 0;
    }
    final seconds = endTime.difference(startTime).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  static String _generateCompanyId(String name, int index) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safeBase = base.isEmpty ? 'company' : base;
    return '${safeBase}_${DateTime.now().millisecondsSinceEpoch}_$index';
  }

  static String _generateSessionId(int index) {
    return '${DateTime.now().microsecondsSinceEpoch}_$index';
  }
}
