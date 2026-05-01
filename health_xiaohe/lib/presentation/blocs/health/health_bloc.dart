import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_xiaohe/domain/repositories/health_repository.dart';
import 'health_event.dart';
import 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final HealthRepository _healthRepository;

  HealthBloc(this._healthRepository) : super(HealthInitial()) {
    on<HealthLoadRecords>(_onLoadRecords);
    on<HealthLoadLatestRecords>(_onLoadLatestRecords);
    on<HealthCreateRecord>(_onCreateRecord);
    on<HealthDeleteRecord>(_onDeleteRecord);
  }

  Future<void> _onLoadRecords(
    HealthLoadRecords event,
    Emitter<HealthState> emit,
  ) async {
    if (!event.refresh) {
      emit(HealthLoading());
    }

    final result = await _healthRepository.getRecords(type: event.type);

    if (result.success) {
      final currentState = state;
      if (currentState is HealthLoaded && !event.refresh) {
        emit(currentState.copyWith(records: result.data));
      } else {
        emit(HealthLoaded(records: result.data ?? []));
      }
    } else {
      emit(HealthError(result.error ?? '获取记录失败'));
    }
  }

  Future<void> _onLoadLatestRecords(
    HealthLoadLatestRecords event,
    Emitter<HealthState> emit,
  ) async {
    final result = await _healthRepository.getLatestRecords();

    if (result.success) {
      final currentState = state;
      if (currentState is HealthLoaded) {
        emit(currentState.copyWith(latestRecords: result.data));
      } else {
        emit(HealthLoaded(latestRecords: result.data));
      }
    } else {
      emit(HealthError(result.error ?? '获取最新记录失败'));
    }
  }

  Future<void> _onCreateRecord(
    HealthCreateRecord event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthRecordCreating());

    final result = await _healthRepository.createRecord(
      type: event.type,
      value: event.value,
      recordedAt: event.recordedAt,
      note: event.note,
    );

    if (result.success) {
      emit(HealthRecordCreated(result.data!));
      add(const HealthLoadRecords(refresh: true));
    } else {
      emit(HealthError(result.error ?? '创建记录失败'));
    }
  }

  Future<void> _onDeleteRecord(
    HealthDeleteRecord event,
    Emitter<HealthState> emit,
  ) async {
    final result = await _healthRepository.deleteRecord(event.recordId);

    if (result.success) {
      emit(HealthRecordDeleted());
      add(const HealthLoadRecords(refresh: true));
    } else {
      emit(HealthError(result.error ?? '删除记录失败'));
    }
  }
}
