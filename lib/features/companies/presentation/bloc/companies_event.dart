import 'package:flutter/foundation.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';

@immutable
sealed class CompaniesEvent {
  const CompaniesEvent();
}

class CompaniesLoadRequested extends CompaniesEvent {
  const CompaniesLoadRequested();
}

class CompaniesWatchRequested extends CompaniesEvent {
  const CompaniesWatchRequested();
}

class CompaniesUpdated extends CompaniesEvent {
  const CompaniesUpdated(this.companies);

  final List<CompanyModel> companies;
}

class CompaniesWatchFailed extends CompaniesEvent {
  const CompaniesWatchFailed(this.message);

  final String message;
}

class CompanyUpsertRequested extends CompaniesEvent {
  const CompanyUpsertRequested(this.company);

  final CompanyModel company;
}

class CompanyDeleteRequested extends CompaniesEvent {
  const CompanyDeleteRequested(this.companyId);

  final String companyId;
}

class CompanySelected extends CompaniesEvent {
  const CompanySelected(this.companyId);

  final String? companyId;
}
