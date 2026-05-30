import 'package:time_tracker/features/companies/data/models/company_model.dart';

abstract class CompanyRepository {
  Future<List<CompanyModel>> getAllCompanies();
  Stream<List<CompanyModel>> watchCompanies();
  Future<CompanyModel?> getCompanyById(String id);
  Future<void> upsertCompany(CompanyModel company);
  Future<void> deleteCompany(String id);
}
