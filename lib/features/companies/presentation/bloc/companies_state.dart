import 'package:flutter/foundation.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';

enum CompaniesStatus { initial, loading, loaded, failure }

@immutable
class CompaniesState {
  const CompaniesState({
    this.status = CompaniesStatus.initial,
    this.companies = const <CompanyModel>[],
    this.selectedCompanyId,
    this.errorMessage,
  });

  final CompaniesStatus status;
  final List<CompanyModel> companies;
  final String? selectedCompanyId;
  final String? errorMessage;

  CompaniesState copyWith({
    CompaniesStatus? status,
    List<CompanyModel>? companies,
    String? selectedCompanyId,
    String? errorMessage,
  }) {
    return CompaniesState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      selectedCompanyId: selectedCompanyId ?? this.selectedCompanyId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
