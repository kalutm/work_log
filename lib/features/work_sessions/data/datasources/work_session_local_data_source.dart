import 'package:hive/hive.dart';
import 'package:time_tracker/core/hive/hive_box_names.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';


abstract class WorkSessionLocalDataSource {
  Future<List<WorkSessionModel>> getAllSessions();
  Stream<List<WorkSessionModel>> watchSessions();
  Future<WorkSessionModel?> getSessionById(String id);
  Future<void> upsertSession(WorkSessionModel session);
  Future<void> deleteSession(String id);
  Future<WorkSessionModel?> getActiveSession();
  Future<List<WorkSessionModel>> getSessionsForCompany(String companyId);
  Future<List<WorkSessionModel>> getSessionsForMonth(DateTime month);
}



class WorkSessionLocalDataSourceHive implements WorkSessionLocalDataSource {
  WorkSessionLocalDataSourceHive(this._box);

  final Box<WorkSessionModel> _box;

  factory WorkSessionLocalDataSourceHive.fromHive() {
    return WorkSessionLocalDataSourceHive(
      Hive.box<WorkSessionModel>(HiveBoxNames.workSessions),
    );
  }

  @override
  Future<List<WorkSessionModel>> getAllSessions() async {
    return _box.values.toList(growable: false);
  }

  @override
  Stream<List<WorkSessionModel>> watchSessions() async* {
    yield _box.values.toList(growable: false);
    await for (final _ in _box.watch()) {
      yield _box.values.toList(growable: false);
    }
  }

  

  @override
  Future<WorkSessionModel?> getSessionById(String id) async => _box.get(id);

  @override
  Future<void> upsertSession(WorkSessionModel session) async {
    await _box.put(session.id, session);
  }

  @override
  Future<void> deleteSession(String id) async {
    await _box.delete(id);
  }

  @override
  Future<WorkSessionModel?> getActiveSession() async {
    for (final session in _box.values) {
      if (session.endTime == null) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<List<WorkSessionModel>> getSessionsForCompany(String companyId) async {
    return _box.values
        .where((session) => session.companyId == companyId)
        .toList(growable: false);
  }

  @override
  Future<List<WorkSessionModel>> getSessionsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _box.values
        .where((session) {
          final sessionStart = session.startTime;
          return !sessionStart.isBefore(start) && sessionStart.isBefore(end);
        })
        .toList(growable: false);
  }
}
