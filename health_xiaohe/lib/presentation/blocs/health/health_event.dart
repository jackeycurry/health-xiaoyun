import 'package:equatable/equatable.dart';
import 'package:health_xiaohe/data/models/health_record_model.dart';

abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object?> get props => [];
}

class HealthLoadRecords extends HealthEvent {
  final HealthRecordType? type;
  final bool refresh;

  const HealthLoadRecords({this.type, this.refresh = false});

  @override
  List<Object?> get props => [type, refresh];
}

class HealthLoadLatestRecords extends HealthEvent {}

class HealthCreateRecord extends HealthEvent {
  final HealthRecordType type;
  final Map<String, dynamic> value;
  final DateTime? recordedAt;
  final String? note;

  const HealthCreateRecord({
    required this.type,
    required this.value,
    this.recordedAt,
    this.note,
  });

  @override
  List<Object?> get props => [type, value, recordedAt, note];
}

class HealthDeleteRecord extends HealthEvent {
  final String recordId;

  const HealthDeleteRecord(this.recordId);

  @override
  List<Object?> get props => [recordId];
}
