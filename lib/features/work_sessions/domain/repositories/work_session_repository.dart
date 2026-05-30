import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

abstract class WorkSessionRepository {
  Future<List<WorkSessionModel>> getAllSessions();
  Stream<List<WorkSessionModel>> watchSessions();
  Future<WorkSessionModel?> getSessionById(String id);
  Future<void> upsertSession(WorkSessionModel session);
  Future<void> deleteSession(String id);
  Future<WorkSessionModel?> getActiveSession();
  Future<List<WorkSessionModel>> getSessionsForCompany(String companyId);
  Future<List<WorkSessionModel>> getSessionsForMonth(DateTime month);
}
