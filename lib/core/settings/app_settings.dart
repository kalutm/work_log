import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:time_tracker/core/hive/hive_box_names.dart';

abstract class AppSettings {
  Future<String?> getDefaultCompanyId();
  Future<void> setDefaultCompanyId(String? companyId);
  Stream<String?> watchDefaultCompanyId();
  Future<int?> getTimeRoundingMinutes();
  Future<void> setTimeRoundingMinutes(int? minutes);
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}

class AppSettingsHive implements AppSettings {
  AppSettingsHive(this._box);

  static const String _defaultCompanyIdKey = 'default_company_id';
  static const String _timeRoundingMinutesKey = 'time_rounding_minutes';
  static const String _themeModeKey = 'theme_mode';

  final Box<dynamic> _box;

  factory AppSettingsHive.fromHive() {
    return AppSettingsHive(Hive.box<dynamic>(HiveBoxNames.settings));
  }

  @override
  Future<String?> getDefaultCompanyId() async {
    final value = _box.get(_defaultCompanyIdKey);
    return value is String ? value : null;
  }

  @override
  Future<void> setDefaultCompanyId(String? companyId) async {
    if (companyId == null || companyId.isEmpty) {
      await _box.delete(_defaultCompanyIdKey);
      return;
    }
    await _box.put(_defaultCompanyIdKey, companyId);
  }

  @override
  Stream<String?> watchDefaultCompanyId() async* {
    yield await getDefaultCompanyId();
    await for (final _ in _box.watch(key: _defaultCompanyIdKey)) {
      final value = _box.get(_defaultCompanyIdKey);
      yield value is String ? value : null;
    }
  }

  @override
  Future<int?> getTimeRoundingMinutes() async {
    final value = _box.get(_timeRoundingMinutesKey);
    return value is int ? value : null;
  }

  @override
  Future<void> setTimeRoundingMinutes(int? minutes) async {
    if (minutes == null || minutes <= 0) {
      await _box.delete(_timeRoundingMinutesKey);
      return;
    }
    await _box.put(_timeRoundingMinutesKey, minutes);
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final value = _box.get(_themeModeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _box.put(_themeModeKey, value);
  }
}
