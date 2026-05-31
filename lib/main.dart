import 'package:flutter/material.dart';
import 'package:time_tracker/core/hive/hive_initializer.dart';
import 'package:time_tracker/core/settings/app_settings.dart';
import 'package:time_tracker/core/theme/app_theme.dart';
import 'package:time_tracker/features/app/presentation/pages/home_page.dart';
import 'package:time_tracker/features/companies/data/datasources/company_local_data_source.dart';
import 'package:time_tracker/features/companies/data/repositories/company_repository_impl.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/work_sessions/data/datasources/work_session_local_data_source.dart';
import 'package:time_tracker/features/work_sessions/data/repositories/work_session_repository_impl.dart';
import 'package:time_tracker/features/work_sessions/domain/repositories/work_session_repository.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInitializer.initialize();
  
  final companyRepository = CompanyRepositoryImpl(
    CompanyLocalDataSourceHive.fromHive(),
  );
  
  final workSessionRepository = WorkSessionRepositoryImpl(
    WorkSessionLocalDataSourceHive.fromHive(),
  );
  
  final settings = AppSettingsHive.fromHive();
  final themeModeNotifier = ValueNotifier<ThemeMode>(
    await settings.getThemeMode(),
  );
  runApp(
    MyApp(
      companyRepository: companyRepository,
      workSessionRepository: workSessionRepository,
      themeModeNotifier: themeModeNotifier,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.companyRepository,
    required this.workSessionRepository,
    required this.themeModeNotifier,
  });


  
  final CompanyRepository companyRepository;
  final WorkSessionRepository workSessionRepository;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Work Log',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: HomePage(
            companyRepository: companyRepository,
            workSessionRepository: workSessionRepository,
            themeModeNotifier: themeModeNotifier,
          ),
        );
      },
    );
  }
}
