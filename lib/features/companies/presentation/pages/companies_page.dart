import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_tracker/features/companies/data/models/company_model.dart';
import 'package:time_tracker/features/companies/domain/repositories/company_repository.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_bloc.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_event.dart';
import 'package:time_tracker/features/companies/presentation/bloc/companies_state.dart';

class CompaniesPage extends StatelessWidget {
  const CompaniesPage({super.key, required this.repository});

  final CompanyRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CompaniesBloc(repository)..add(const CompaniesWatchRequested()),
      child: const CompaniesView(),
    );
  }
}

class CompaniesView extends StatelessWidget {
  const CompaniesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companies')),
      body: BlocConsumer<CompaniesBloc, CompaniesState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == CompaniesStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == CompaniesStatus.loading &&
              state.companies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.companies.isEmpty) {
            return const Center(child: Text('No companies yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.companies.length,
            itemBuilder: (context, index) {
              final company = state.companies[index];
              final isDefault = company.id == state.selectedCompanyId;
              final rateText = company.hourlyRate == null
                  ? null
                  : 'Rate: ${company.hourlyRate!.toStringAsFixed(2)}';
              final subtitleParts = <String>[];
              if (rateText != null) {
                subtitleParts.add(rateText);
              }
              if (isDefault) {
                subtitleParts.add('Default');
              }
              final subtitle = subtitleParts.isEmpty
                  ? null
                  : subtitleParts.join(' | ');
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(company.colorCode),
                  ),
                  title: Text(company.name),
                  subtitle: subtitle == null ? null : Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isDefault ? Icons.star : Icons.star_border),
                        tooltip: isDefault ? 'Default company' : 'Set default',
                        onPressed: isDefault
                            ? null
                            : () => context.read<CompaniesBloc>().add(
                                CompanySelected(company.id),
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCompany(context, company),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _confirmDelete(context, company, isDefault),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editCompany(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _editCompany(BuildContext context, CompanyModel? company) async {
    final result = await showDialog<CompanyModel>(
      context: context,
      builder: (context) => _CompanyEditorDialog(company: company),
    );

    if (result == null) {
      return;
    }

    context.read<CompaniesBloc>().add(CompanyUpsertRequested(result));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CompanyModel company,
    bool isDefault,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDefault ? 'Delete default company?' : 'Delete company?'),
        content: Text(
          isDefault
              ? 'Delete ${company.name}? This will clear the default selection.'
              : 'Delete ${company.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      context.read<CompaniesBloc>().add(CompanyDeleteRequested(company.id));
    }
  }
}

class _CompanyEditorDialog extends StatefulWidget {
  const _CompanyEditorDialog({this.company});

  final CompanyModel? company;

  @override
  State<_CompanyEditorDialog> createState() => _CompanyEditorDialogState();
}

class _CompanyEditorDialogState extends State<_CompanyEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  late Color _selectedColor;
  String? _error;

  final List<Color> _colors = const [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    final company = widget.company;
    _nameController = TextEditingController(text: company?.name ?? '');
    _rateController = TextEditingController(
      text: company?.hourlyRate?.toString() ?? '',
    );
    _selectedColor = company == null ? _colors.first : Color(company.colorCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.company == null ? 'Add company' : 'Edit company'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hourly rate'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((color) {
                final selected = color.value == _selectedColor.value;
                return ChoiceChip(
                  label: const Text(''),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedColor = color),
                  selectedColor: color,
                  backgroundColor: color.withOpacity(0.4),
                  avatar: selected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }

    double? hourlyRate;
    final rateText = _rateController.text.trim();
    if (rateText.isNotEmpty) {
      hourlyRate = double.tryParse(rateText);
      if (hourlyRate == null) {
        setState(() => _error = 'Hourly rate must be a number.');
        return;
      }
    }

    final id = widget.company?.id ?? _generateId();
    final company = CompanyModel(
      id: id,
      name: name,
      colorCode: _selectedColor.value,
      hourlyRate: hourlyRate,
    );

    Navigator.of(context).pop(company);
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
