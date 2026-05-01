import 'package:equatable/equatable.dart';
import 'package:health_xiaohe/data/models/health_record_model.dart';

abstract class HealthState extends Equatable {
  const HealthState();

  @override
  List<Object?> get props => [];
}

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthLoaded extends HealthState {
  final List<HealthRecordModel> records;
  final LatestRecordsModel? latestRecords;

  const HealthLoaded({
    this.records = const [],
    this.latestRecords,
  });

  @override
  List<Object?> get props => [records, latestRecords];

  HealthLoaded copyWith({
    List<HealthRecordModel>? records,
    LatestRecordsModel? latestRecords,
  }) {
    return HealthLoaded(
      records: records ?? this.records,
      latestRecords: latestRecords ?? this.latestRecords,
    );
  }
}

class HealthError extends HealthState {
  final String message;

  const HealthError(this.message);

  @override
  List<Object?> get props => [message];
}

class HealthRecordCreating extends HealthState {}

class HealthRecordCreated extends HealthState {
  final HealthRecordModel record;

  const HealthRecordCreated(this.record);

  @override
  List<Object?> get props => [record];
}

class HealthRecordDeleted extends HealthState {}
