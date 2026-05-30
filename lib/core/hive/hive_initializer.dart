import 'package:hive_flutter/hive_flutter.dart';

import 'package:time_tracker/core/hive/hive_box_names.dart';
import 'package:time_tracker/core/hive/hive_type_ids.dart';
import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/work_sessions/data/models/work_session_model.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTypeIds.company)) {
      Hive.registerAdapter(CompanyModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.workSession)) {
      Hive.registerAdapter(WorkSessionModelAdapter());
    }
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<CompanyModel>(HiveBoxNames.companies);
    await Hive.openBox<WorkSessionModel>(HiveBoxNames.workSessions);
  }
}
