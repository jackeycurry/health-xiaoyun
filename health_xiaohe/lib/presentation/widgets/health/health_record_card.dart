import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/data/models/health_record_model.dart';

class HealthRecordCard extends StatelessWidget {
  final HealthRecordModel record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const HealthRecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildIcon(),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.type.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(record.recordedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    record.displayValue,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.type.unit,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color backgroundColor;
    Color iconColor;

    switch (record.type) {
      case HealthRecordType.bloodPressure:
        icon = Icons.favorite;
        backgroundColor = const Color(0xFFFFF1F0);
        iconColor = AppColors.danger;
        break;
      case HealthRecordType.bloodSugar:
        icon = Icons.water_drop;
        backgroundColor = const Color(0xFFF6FFED);
        iconColor = AppColors.success;
        break;
      case HealthRecordType.weight:
        icon = Icons.monitor_weight;
        backgroundColor = const Color(0xFFF0F5FF);
        iconColor = AppColors.secondary;
        break;
      case HealthRecordType.temperature:
        icon = Icons.thermostat;
        backgroundColor = const Color(0xFFFFF1F0);
        iconColor = AppColors.danger;
        break;
      case HealthRecordType.heartRate:
        icon = Icons.show_chart;
        backgroundColor = const Color(0xFFFFF7E6);
        iconColor = AppColors.warning;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;

    // Determine status based on record type and value
    final status = record.status;
    switch (status) {
      case HealthRecordStatus.normal:
        backgroundColor = const Color(0xFFF6FFED);
        textColor = AppColors.success;
        text = '正常';
        break;
      case HealthRecordStatus.warning:
        backgroundColor = const Color(0xFFFFF7E6);
        textColor = AppColors.warning;
        text = '偏高';
        break;
      case HealthRecordStatus.danger:
        backgroundColor = const Color(0xFFFFF1F0);
        textColor = AppColors.danger;
        text = '异常';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
}
