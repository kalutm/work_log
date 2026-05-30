import 'package:flutter/material.dart';

import 'package:time_tracker/core/settings/app_settings.dart';
import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.companyRepository,
    required this.themeModeNotifier,
  });

  final CompanyRepository companyRepository;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettings _settings = AppSettingsHive.fromHive();
  bool _loading = true;
  String? _defaultCompanyId;
  int _roundingMinutes = 0;
  ThemeMode _themeMode = ThemeMode.system;
  late final Stream<String?> _defaultCompanyStream;

  @override
  void initState() {
    super.initState();
    _defaultCompanyStream = _settings.watchDefaultCompanyId();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final defaultCompanyId = await _settings.getDefaultCompanyId();
    final rounding = await _settings.getTimeRoundingMinutes();
    final themeMode = await _settings.getThemeMode();
    if (!mounted) {
      return;
    }
    setState(() {
      _defaultCompanyId = defaultCompanyId;
      _roundingMinutes = rounding ?? 0;
      _themeMode = themeMode;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<CompanyModel>>(
      stream: widget.companyRepository.watchCompanies(),
      initialData: const <CompanyModel>[],
      builder: (context, snapshot) {
        final companies = snapshot.data ?? const <CompanyModel>[];
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ThemeMode>(
                        value: _themeMode,
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System default'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light mode'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark mode'),
                          ),
                        ],
                        onChanged: (value) async {
                          final mode = value ?? ThemeMode.system;
                          await _settings.setThemeMode(mode);
                          widget.themeModeNotifier.value = mode;
                          if (!mounted) {
                            return;
                          }
                          setState(() => _themeMode = mode);
                        },
                        decoration: const InputDecoration(labelText: 'Theme'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<String?>(
                stream: _defaultCompanyStream,
                builder: (context, snapshot) {
                  final streamDefaultId = snapshot.data ?? _defaultCompanyId;
                  final streamHasDefault = companies.any(
                    (c) => c.id == streamDefaultId,
                  );
                  final streamDefaultValue = streamHasDefault
                      ? streamDefaultId
                      : null;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Default company',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String?>(
                            value: streamDefaultValue,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None'),
                              ),
                              ...companies.map(
                                (company) => DropdownMenuItem<String?>(
                                  value: company.id,
                                  child: Text(company.name),
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              await _settings.setDefaultCompanyId(value);
                              if (!mounted) {
                                return;
                              }
                              setState(() => _defaultCompanyId = value);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Default',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time rounding',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _roundingMinutes,
                        items: const [
                          DropdownMenuItem<int>(value: 0, child: Text('Off')),
                          DropdownMenuItem<int>(
                            value: 5,
                            child: Text('5 minutes'),
                          ),
                          DropdownMenuItem<int>(
                            value: 10,
                            child: Text('10 minutes'),
                          ),
                          DropdownMenuItem<int>(
                            value: 15,
                            child: Text('15 minutes'),
                          ),
                        ],
                        onChanged: (value) async {
                          final minutes = value ?? 0;
                          await _settings.setTimeRoundingMinutes(minutes);
                          if (!mounted) {
                            return;
                          }
                          setState(() => _roundingMinutes = minutes);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Round to',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Applies to new sessions when enabled.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
