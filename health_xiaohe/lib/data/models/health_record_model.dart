enum HealthRecordType {
  bloodPressure('blood_pressure'),
  bloodSugar('blood_sugar'),
  weight('weight'),
  temperature('temperature'),
  heartRate('heart_rate');

  final String value;
  const HealthRecordType(this.value);

  static HealthRecordType fromString(String value) {
    return HealthRecordType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HealthRecordType.bloodPressure,
    );
  }

  String get displayName {
    switch (this) {
      case HealthRecordType.bloodPressure:
        return '血压';
      case HealthRecordType.bloodSugar:
        return '血糖';
      case HealthRecordType.weight:
        return '体重';
      case HealthRecordType.temperature:
        return '体温';
      case HealthRecordType.heartRate:
        return '心率';
    }
  }

  String get unit {
    switch (this) {
      case HealthRecordType.bloodPressure:
        return 'mmHg';
      case HealthRecordType.bloodSugar:
        return 'mmol/L';
      case HealthRecordType.weight:
        return 'kg';
      case HealthRecordType.temperature:
        return '°C';
      case HealthRecordType.heartRate:
        return 'bpm';
    }
  }
}

enum HealthRecordStatus {
  normal,
  warning,
  danger,
}

class HealthRecordModel {
  final String id;
  final String userId;
  final HealthRecordType type;
  final Map<String, dynamic> value;
  final DateTime recordedAt;
  final String? note;
  final DateTime createdAt;

  HealthRecordModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.recordedAt,
    this.note,
    required this.createdAt,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: HealthRecordType.fromString(json['type'] as String),
      value: json['value'] as Map<String, dynamic>,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'value': value,
      'recorded_at': recordedAt.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayValue {
    switch (type) {
      case HealthRecordType.bloodPressure:
        final systolic = value['systolic'] ?? value['systolic'];
        final diastolic = value['diastolic'] ?? value['diastolic'];
        return '$systolic/$diastolic';
      case HealthRecordType.bloodSugar:
      case HealthRecordType.weight:
      case HealthRecordType.temperature:
      case HealthRecordType.heartRate:
        return value['value'].toString();
    }
  }

  HealthRecordStatus get status {
    switch (type) {
      case HealthRecordType.bloodPressure:
        final systolic = (value['systolic'] ?? value['systolic'] ?? 0) as num;
        final diastolic = (value['diastolic'] ?? value['diastolic'] ?? 0) as num;
        if (systolic >= 140 || diastolic >= 90) return HealthRecordStatus.danger;
        if (systolic >= 130 || diastolic >= 85) return HealthRecordStatus.warning;
        return HealthRecordStatus.normal;
      case HealthRecordType.bloodSugar:
        final val = (value['value'] ?? 0) as num;
        if (val >= 7.0) return HealthRecordStatus.danger;
        if (val >= 6.1) return HealthRecordStatus.warning;
        return HealthRecordStatus.normal;
      case HealthRecordType.heartRate:
        final val = (value['value'] ?? 0) as num;
        if (val >= 100 || val < 60) return HealthRecordStatus.warning;
        return HealthRecordStatus.normal;
      case HealthRecordType.weight:
      case HealthRecordType.temperature:
        return HealthRecordStatus.normal;
    }
  }
}

class LatestRecordsModel {
  final HealthRecordModel? bloodPressure;
  final HealthRecordModel? bloodSugar;
  final HealthRecordModel? weight;
  final HealthRecordModel? temperature;
  final HealthRecordModel? heartRate;

  LatestRecordsModel({
    this.bloodPressure,
    this.bloodSugar,
    this.weight,
    this.temperature,
    this.heartRate,
  });

  factory LatestRecordsModel.fromJson(Map<String, dynamic> json) {
    return LatestRecordsModel(
      bloodPressure: json['blood_pressure'] != null
          ? HealthRecordModel.fromJson(json['blood_pressure'])
          : null,
      bloodSugar: json['blood_sugar'] != null
          ? HealthRecordModel.fromJson(json['blood_sugar'])
          : null,
      weight: json['weight'] != null
          ? HealthRecordModel.fromJson(json['weight'])
          : null,
      temperature: json['temperature'] != null
          ? HealthRecordModel.fromJson(json['temperature'])
          : null,
      heartRate: json['heart_rate'] != null
          ? HealthRecordModel.fromJson(json['heart_rate'])
          : null,
    );
  }
}
