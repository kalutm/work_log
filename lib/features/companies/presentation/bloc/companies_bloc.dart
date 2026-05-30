import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_event.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_state.dart';

class CompaniesBloc extends Bloc<CompaniesEvent, CompaniesState> {
  CompaniesBloc(this._repository) : super(const CompaniesState()) {
    on<CompaniesLoadRequested>(_onLoadRequested);
    on<CompaniesWatchRequested>(_onWatchRequested);
    on<CompaniesUpdated>(_onCompaniesUpdated);
    on<CompaniesWatchFailed>(_onWatchFailed);
    on<CompanyUpsertRequested>(_onCompanyUpsert);
    on<CompanyDeleteRequested>(_onCompanyDelete);
    on<CompanySelected>(_onCompanySelected);
  }

  final CompanyRepository _repository;
  StreamSubscription<List<CompanyModel>>? _companiesSubscription;

  Future<void> _onLoadRequested(
    CompaniesLoadRequested event,
    Emitter<CompaniesState> emit,
  ) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _onWatchRequested(
    CompaniesWatchRequested event,
    Emitter<CompaniesState> emit,
  ) async {
    emit(state.copyWith(status: CompaniesStatus.loading, errorMessage: null));
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
    emit(
      state.copyWith(
        status: CompaniesStatus.loaded,
        companies: event.companies,
        errorMessage: null,
      ),
    );
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
      await _repository.deleteCompany(event.companyId);
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
    emit(state.copyWith(selectedCompanyId: event.companyId));
  }

  Future<void> _fetchAndEmit(Emitter<CompaniesState> emit) async {
    emit(state.copyWith(status: CompaniesStatus.loading, errorMessage: null));
    try {
      final companies = await _repository.getAllCompanies();
      emit(
        state.copyWith(
          status: CompaniesStatus.loaded,
          companies: companies,
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

  @override
  Future<void> close() {
    _companiesSubscription?.cancel();
    return super.close();
  }
}
