import 'package:dio/dio.dart';
import 'package:health_xiaohe/core/network/api_client.dart';
import 'package:health_xiaohe/data/models/health_record_model.dart';
import 'package:health_xiaohe/domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  final ApiClient _apiClient;

  HealthRepositoryImpl(this._apiClient);

  @override
  Future<HealthResult<List<HealthRecordModel>>> getRecords({
    HealthRecordType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.getHealthRecords(
        recordType: type?.value,
        limit: limit,
        offset: offset,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final records = data.map((json) => HealthRecordModel.fromJson(json)).toList();
      return HealthResult.success(records);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? '获取健康记录失败';
      return HealthResult.failure(message.toString());
    } catch (e) {
      return HealthResult.failure('获取健康记录失败: $e');
    }
  }

  @override
  Future<HealthResult<LatestRecordsModel>> getLatestRecords() async {
    try {
      final response = await _apiClient.getLatestRecords();
      final latestRecords = LatestRecordsModel.fromJson(response.data);
      return HealthResult.success(latestRecords);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? '获取最新记录失败';
      return HealthResult.failure(message.toString());
    } catch (e) {
      return HealthResult.failure('获取最新记录失败: $e');
    }
  }

  @override
  Future<HealthResult<HealthRecordModel>> createRecord({
    required HealthRecordType type,
    required Map<String, dynamic> value,
    DateTime? recordedAt,
    String? note,
  }) async {
    try {
      final response = await _apiClient.createHealthRecord({
        'type': type.value,
        'value': value,
        'recorded_at': (recordedAt ?? DateTime.now()).toIso8601String(),
        if (note != null) 'note': note,
      });

      final record = HealthRecordModel.fromJson(response.data);
      return HealthResult.success(record);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? '创建健康记录失败';
      return HealthResult.failure(message.toString());
    } catch (e) {
      return HealthResult.failure('创建健康记录失败: $e');
    }
  }

  @override
  Future<HealthResult<void>> deleteRecord(String recordId) async {
    try {
      await _apiClient.deleteHealthRecord(recordId);
      return HealthResult.success(null);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? '删除健康记录失败';
      return HealthResult.failure(message.toString());
    } catch (e) {
      return HealthResult.failure('删除健康记录失败: $e');
    }
  }
}
