import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/core/settings/app_settings.dart';
import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_event.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_state.dart';

class CompaniesBloc extends Bloc<CompaniesEvent, CompaniesState> {
  CompaniesBloc(this._repository, {AppSettings? settings})
    : _settings = settings ?? AppSettingsHive.fromHive(),
      super(const CompaniesState()) {
    on<CompaniesLoadRequested>(_onLoadRequested);
    on<CompaniesWatchRequested>(_onWatchRequested);
    on<CompaniesUpdated>(_onCompaniesUpdated);
    on<CompaniesWatchFailed>(_onWatchFailed);
    on<CompaniesDefaultChanged>(_onDefaultChanged);
    on<CompanyUpsertRequested>(_onCompanyUpsert);
    on<CompanyDeleteRequested>(_onCompanyDelete);
    on<CompanySelected>(_onCompanySelected);

    _defaultCompanySubscription = _settings.watchDefaultCompanyId().listen(
      (companyId) => add(CompaniesDefaultChanged(companyId)),
    );
  }

  final CompanyRepository _repository;
  final AppSettings _settings;
  StreamSubscription<List<CompanyModel>>? _companiesSubscription;
  StreamSubscription<String?>? _defaultCompanySubscription;
  String? _persistedDefaultCompanyId;

  Future<void> _onLoadRequested(
    CompaniesLoadRequested event,
    Emitter<CompaniesState> emit,
  ) async {
    await _ensurePersistedDefault();
    await _fetchAndEmit(emit);
  }

  Future<void> _onWatchRequested(
    CompaniesWatchRequested event,
    Emitter<CompaniesState> emit,
  ) async {
    emit(state.copyWith(status: CompaniesStatus.loading, errorMessage: null));
    await _ensurePersistedDefault();
    await _companiesSubscription?.cancel();
    _companiesSubscription = _repository.watchCompanies().listen(
      (companies) => add(CompaniesUpdated(companies)),
      onError: (Object error, StackTrace _) {
        add(CompaniesWatchFailed(error.toString()));
      },
    );
  }

  void _onCompaniesUpdated(
    CompaniesUpdated event,
    Emitter<CompaniesState> emit,
  ) {
    final selectedCompanyId = _resolveSelectedCompanyId(event.companies);
    emit(
      state.copyWith(
        status: CompaniesStatus.loaded,
        companies: event.companies,
        selectedCompanyId: selectedCompanyId,
        errorMessage: null,
      ),
    );
  }

  void _onDefaultChanged(
    CompaniesDefaultChanged event,
    Emitter<CompaniesState> emit,
  ) {
    _persistedDefaultCompanyId = event.companyId;
    final selectedCompanyId = _resolveSelectedCompanyId(state.companies);
    if (selectedCompanyId == state.selectedCompanyId) {
      return;
    }
    emit(state.copyWith(selectedCompanyId: selectedCompanyId));
  }

  void _onWatchFailed(
    CompaniesWatchFailed event,
    Emitter<CompaniesState> emit,
  ) {
    emit(
      state.copyWith(
        status: CompaniesStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onCompanyUpsert(
    CompanyUpsertRequested event,
    Emitter<CompaniesState> emit,
  ) async {
    try {
      await _repository.upsertCompany(event.company);
      if (_companiesSubscription == null) {
        await _fetchAndEmit(emit);
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: CompaniesStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCompanyDelete(
    CompanyDeleteRequested event,
    Emitter<CompaniesState> emit,
  ) async {
    try {
      final wasDefault =
          _persistedDefaultCompanyId == event.companyId ||
          state.selectedCompanyId == event.companyId;
      await _repository.deleteCompany(event.companyId);
      if (wasDefault) {
        _persistedDefaultCompanyId = null;
        await _settings.setDefaultCompanyId(null);
      }
      if (_companiesSubscription == null) {
        await _fetchAndEmit(emit);
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: CompaniesStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onCompanySelected(CompanySelected event, Emitter<CompaniesState> emit) {
    _persistedDefaultCompanyId = event.companyId;
    _settings.setDefaultCompanyId(event.companyId);
    emit(state.copyWith(selectedCompanyId: event.companyId));
  }

  Future<void> _fetchAndEmit(Emitter<CompaniesState> emit) async {
    emit(state.copyWith(status: CompaniesStatus.loading, errorMessage: null));
    try {
      final companies = await _repository.getAllCompanies();
      final selectedCompanyId = _resolveSelectedCompanyId(companies);
      emit(
        state.copyWith(
          status: CompaniesStatus.loaded,
          companies: companies,
          selectedCompanyId: selectedCompanyId,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CompaniesStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _ensurePersistedDefault() async {
    if (_persistedDefaultCompanyId != null) {
      return;
    }
    _persistedDefaultCompanyId = await _settings.getDefaultCompanyId();
  }

  String? _resolveSelectedCompanyId(List<CompanyModel> companies) {
    final persistedDefault = _persistedDefaultCompanyId;
    if (persistedDefault != null &&
        companies.any((company) => company.id == persistedDefault)) {
      return persistedDefault;
    }
    return null;
  }

  @override
  Future<void> close() {
    _companiesSubscription?.cancel();
    _defaultCompanySubscription?.cancel();
    return super.close();
  }
}
