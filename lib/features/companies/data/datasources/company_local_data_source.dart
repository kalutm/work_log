import 'package:hive/hive.dart';

import 'package:time_tracker/core/hive/hive_box_names.dart';
import 'package:time_tracker/features/companies/data/models/company_model.dart';

abstract class CompanyLocalDataSource {
  Future<List<CompanyModel>> getAllCompanies();
  Stream<List<CompanyModel>> watchCompanies();
  Future<CompanyModel?> getCompanyById(String id);
  Future<void> upsertCompany(CompanyModel company);
  Future<void> deleteCompany(String id);
}

class CompanyLocalDataSourceHive implements CompanyLocalDataSource {
  CompanyLocalDataSourceHive(this._box);

  final Box<CompanyModel> _box;

  factory CompanyLocalDataSourceHive.fromHive() {
    return CompanyLocalDataSourceHive(
      Hive.box<CompanyModel>(HiveBoxNames.companies),
    );
  }

  @override
  Future<List<CompanyModel>> getAllCompanies() async {
    return _box.values.toList(growable: false);
  }

  @override
  Stream<List<CompanyModel>> watchCompanies() async* {
    yield _box.values.toList(growable: false);
    await for (final _ in _box.watch()) {
      yield _box.values.toList(growable: false);
    }
  }

  @override
  Future<CompanyModel?> getCompanyById(String id) async => _box.get(id);

  @override
  Future<void> upsertCompany(CompanyModel company) async {
    await _box.put(company.id, company);
  }

  @override
  Future<void> deleteCompany(String id) async {
    await _box.delete(id);
  }
}
