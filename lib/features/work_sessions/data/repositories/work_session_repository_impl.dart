import 'package:time_tracker/features/work_sessions/data/datasources/work_session_local_data_source.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';

class WorkSessionRepositoryImpl implements WorkSessionRepository {
  WorkSessionRepositoryImpl(this._localDataSource);

  final WorkSessionLocalDataSource _localDataSource;

  @override
  Future<List<WorkSessionModel>> getAllSessions() {
    return _localDataSource.getAllSessions();
  }

  @override
  Stream<List<WorkSessionModel>> watchSessions() {
    return _localDataSource.watchSessions();
  }

  @override
  Future<WorkSessionModel?> getSessionById(String id) {
    return _localDataSource.getSessionById(id);
  }

  @override
  Future<void> upsertSession(WorkSessionModel session) {
    return _localDataSource.upsertSession(session);
  }

  @override
  Future<void> deleteSession(String id) {
    return _localDataSource.deleteSession(id);
  }

  @override
  Future<WorkSessionModel?> getActiveSession() {
    return _localDataSource.getActiveSession();
  }

  @override
  Future<List<WorkSessionModel>> getSessionsForCompany(String companyId) {
    return _localDataSource.getSessionsForCompany(companyId);
  }

  @override
  Future<List<WorkSessionModel>> getSessionsForMonth(DateTime month) {
    return _localDataSource.getSessionsForMonth(month);
  }
}
