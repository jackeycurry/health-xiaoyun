import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/core/constants/app_spacing.dart';
import 'package:health_xiaohe/core/constants/app_strings.dart';
import 'package:health_xiaohe/data/models/health_record_model.dart';
import 'package:health_xiaohe/presentation/blocs/health/health_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/health/health_event.dart';
import 'package:health_xiaohe/presentation/blocs/health/health_state.dart';
import 'package:health_xiaohe/presentation/widgets/health/health_record_card.dart';

class HealthRecordsPage extends StatefulWidget {
  const HealthRecordsPage({super.key});

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage> {
  @override
  void initState() {
    super.initState();
    context.read<HealthBloc>().add(const HealthLoadRecords());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          AppStrings.healthRecords,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<HealthBloc, HealthState>(
        listener: (context, state) {
          if (state is HealthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          } else if (state is HealthRecordCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('记录创建成功'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is HealthRecordDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('记录已删除'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HealthLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is HealthLoaded) {
            final records = state.records;

            if (records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '📋',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      AppStrings.noRecords,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRecordDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.addRecord),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HealthBloc>().add(const HealthLoadRecords(refresh: true));
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return HealthRecordCard(
                    record: record,
                    onDelete: () => _confirmDelete(context, record.id),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHealthRecordSheet(),
    );
  }

  void _confirmDelete(BuildContext context, String recordId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条健康记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<HealthBloc>().add(HealthDeleteRecord(recordId));
            },
            child: const Text(
              '删除',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class AddHealthRecordSheet extends StatefulWidget {
  const AddHealthRecordSheet({super.key});

  @override
  State<AddHealthRecordSheet> createState() => _AddHealthRecordSheetState();
}

class _AddHealthRecordSheetState extends State<AddHealthRecordSheet> {
  HealthRecordType _selectedType = HealthRecordType.bloodPressure;
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              AppStrings.addRecord,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Record type selector
            Wrap(
              spacing: 8,
              children: HealthRecordType.values.map((type) {
                final isSelected = type == _selectedType;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Value input
            if (_selectedType == HealthRecordType.bloodPressure) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _systolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '收缩压',
                        hintText: '120',
                        suffixText: 'mmHg',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _diastolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '舒张压',
                        hintText: '80',
                        suffixText: 'mmHg',
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _selectedType.displayName,
                  hintText: '请输入值',
                  suffixText: _selectedType.unit,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // Note input
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '添加一些备注...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('保存'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _submit() {
    Map<String, dynamic> value;

    if (_selectedType == HealthRecordType.bloodPressure) {
      final systolic = int.tryParse(_systolicController.text);
      final diastolic = int.tryParse(_diastolicController.text);

      if (systolic == null || diastolic == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的血压值')),
        );
        return;
      }

      value = {'systolic': systolic, 'diastolic': diastolic};
    } else {
      final val = double.tryParse(_valueController.text);
      if (val == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的数值')),
        );
        return;
      }
      value = {'value': val};
    }

    context.read<HealthBloc>().add(
          HealthCreateRecord(
            type: _selectedType,
            value: value,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          ),
        );

    Navigator.pop(context);
  }
}
