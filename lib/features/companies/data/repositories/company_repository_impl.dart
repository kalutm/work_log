import 'package:time_tracker/features/companies/data/datasources/company_local_data_source.dart';
import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  CompanyRepositoryImpl(this._localDataSource);

  final CompanyLocalDataSource _localDataSource;

  @override
  Future<List<CompanyModel>> getAllCompanies() {
    return _localDataSource.getAllCompanies();
  }

  @override
  Stream<List<CompanyModel>> watchCompanies() {
    return _localDataSource.watchCompanies();
  }

  @override
  Future<CompanyModel?> getCompanyById(String id) {
    return _localDataSource.getCompanyById(id);
  }

  @override
  Future<void> upsertCompany(CompanyModel company) {
    return _localDataSource.upsertCompany(company);
  }

  @override
  Future<void> deleteCompany(String id) {
    return _localDataSource.deleteCompany(id);
  }
}
