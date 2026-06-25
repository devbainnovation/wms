import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/dashboard.dart';

class TankHistoryScreen extends ConsumerWidget {
  const TankHistoryScreen({
    super.key,
    required this.componentId,
    required this.tankName,
  });

  final String componentId;
  final String tankName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(tankHistoryProvider(componentId));
    final selectedDays = ref.watch(tankHistoryDaysProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          '$tankName History',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        actions: [
          _DaysFilterDropdown(
            currentValue: selectedDays,
            onChanged: (value) {
              if (value != null) {
                ref.read(tankHistoryDaysProvider.notifier).setDays(value);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'No history available for this period',
                style: TextStyle(color: AppColors.greyText),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: TankLevelHeatmapChart(data: data),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error is ApiException ? error.message : 'Error loading history',
                style: const TextStyle(color: AppColors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(tankHistoryProvider(componentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysFilterDropdown extends StatelessWidget {
  const _DaysFilterDropdown({
    required this.currentValue,
    required this.onChanged,
  });

  final int currentValue;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGreyText.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentValue,
          items: const [
            DropdownMenuItem(value: 7, child: Text('7 Days')),
            DropdownMenuItem(value: 15, child: Text('15 Days')),
            DropdownMenuItem(value: 30, child: Text('30 Days')),
          ],
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ),
    );
  }
}

class TankLevelHeatmapChart extends StatelessWidget {
  const TankLevelHeatmapChart({
    super.key,
    required this.data,
    this.cellWidth = 36,
    this.chartHeight = 400,
  });

  final List<TankHistoryItem> data;
  final double cellWidth;
  final double chartHeight;

  static const double dayLabelHeight = 40;

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupByDay(data);

    return SizedBox(
      height: chartHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildYAxis(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                   // reverse: true, // Show most recent days first (right side)
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: groupedData.entries.map((entry) {
                        return _buildDayColumn(
                          context,
                          entry.key,
                          entry.value,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildYAxis() {
    return SizedBox(
      // width: 55,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: List.generate(8, (index) {
                final hour = 21 - (index * 3);
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.greyText,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: dayLabelHeight),
        ],
      ),
    );
  }

  Widget _buildDayColumn(
    BuildContext context,
    DateTime day,
    List<TankHistoryItem> dayData,
  ) {
    final slots = _buildSlots(day, dayData);

    return SizedBox(
      width: cellWidth,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: List.generate(8, (index) {
                final slot = slots[7 - index];
                final firstRecord =
                    slot.records.isNotEmpty ? slot.records.first : null;

                return Expanded(
                  child: GestureDetector(
                    onTap: slot.records.isEmpty
                        ? null
                        : () => _showDetail(context, slot),
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: firstRecord == null
                            ? Colors.grey.shade200
                            : _getLevelColor(firstRecord.level),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: dayLabelHeight,
            child: Center(
              child: Text(
                DateFormat('dd\nMMM').format(day),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(double level) {
    if (level >= 70) return AppColors.blue;
    if (level >= 35) return AppColors.warning;
    return AppColors.red;
  }

  void _showDetail(BuildContext context, _TimeSlotData slot) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(DateFormat('dd-MMM-yyyy').format(slot.day)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...slot.records.map((record) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('HH:mm').format(record.timestamp)),
                      Text(
                        '${record.level.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getLevelColor(record.level),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<_TimeSlotData> _buildSlots(
    DateTime day,
    List<TankHistoryItem> dayData,
  ) {
    final slots = <_TimeSlotData>[];
    for (int startHour = 0; startHour < 24; startHour += 3) {
      final records = dayData.where((e) {
        return e.timestamp.hour >= startHour &&
            e.timestamp.hour < startHour + 3;
      }).toList();
      slots.add(_TimeSlotData(day: day, startHour: startHour, records: records));
    }
    return slots;
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _LegendItem(color: AppColors.red, label: 'Low (<35%)'),
          _LegendItem(color: AppColors.warning, label: 'Medium (35-70%)'),
          _LegendItem(color: AppColors.blue, label: 'High (>=70%)'),
          _LegendItem(color: Colors.grey.shade200, label: 'No Data'),
        ],
      ),
    );
  }

  Map<DateTime, List<TankHistoryItem>> _groupByDay(List<TankHistoryItem> data) {
    final result = <DateTime, List<TankHistoryItem>>{};
    for (final item in data) {
      final key = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );
      result.putIfAbsent(key, () => []);
      result[key]!.add(item);
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.greyText),
        ),
      ],
    );
  }
}

class _TimeSlotData {
  const _TimeSlotData({
    required this.day,
    required this.startHour,
    required this.records,
  });

  final DateTime day;
  final int startHour;
  final List<TankHistoryItem> records;
}
