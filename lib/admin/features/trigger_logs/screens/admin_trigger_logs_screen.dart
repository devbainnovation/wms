import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/trigger_logs/providers/trigger_log_providers.dart';
import 'package:wms/admin/features/trigger_logs/services/trigger_log_models.dart';
import 'package:wms/admin/features/devices/services/admin_device_component_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

class AdminTriggerLogsScreen extends ConsumerStatefulWidget {
  const AdminTriggerLogsScreen({super.key});

  @override
  ConsumerState<AdminTriggerLogsScreen> createState() => _AdminTriggerLogsScreenState();
}

class _AdminTriggerLogsScreenState extends ConsumerState<AdminTriggerLogsScreen> {
  final _espIdController = TextEditingController();
  final _actorIdController = TextEditingController();
  late TriggerLogQuery _pendingQuery;

  @override
  void initState() {
    super.initState();
    _pendingQuery = const TriggerLogQuery();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentQuery = ref.read(triggerLogQueryProvider);
      setState(() {
        _pendingQuery = currentQuery;
        _espIdController.text = currentQuery.espId ?? '';
        _actorIdController.text = currentQuery.actorId ?? '';
      });
    });
  }

  @override
  void dispose() {
    _espIdController.dispose();
    _actorIdController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(triggerLogQueryProvider.notifier).updateQuery(_pendingQuery.copyWith(
          espId: _espIdController.text.trim(),
          actorId: _actorIdController.text.trim(),
          page: 0,
        ));
  }

  void _resetFilters() {
    _espIdController.clear();
    _actorIdController.clear();
    setState(() {
      _pendingQuery = const TriggerLogQuery();
    });
    ref.read(triggerLogQueryProvider.notifier).resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(triggerLogListProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trigger Logs',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 20),
          _buildFilterPanel(isMobile),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightGreyText),
              ),
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
                error: (error, _) => _buildError(error),
                data: (result) => _buildLogList(result, isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildTextField('ESP ID', _espIdController, Icons.search_rounded),
          const SizedBox(height: 12),
          _buildDropdown<TriggerType>(
            'Trigger Type',
            _pendingQuery.triggerType,
            TriggerType.values,
            (e) => e.value,
            (val) => setState(() => _pendingQuery = _pendingQuery.copyWith(triggerType: val, clearTriggerType: val == null)),
          ),
          const SizedBox(height: 12),
          _buildDropdown<AdminComponentType>(
            'Component Type',
            _pendingQuery.componentType,
            AdminComponentType.values,
            (e) => e.name.toUpperCase(),
            (val) => setState(() => _pendingQuery = _pendingQuery.copyWith(componentType: val, clearComponentType: val == null)),
          ),
          const SizedBox(height: 12),
          _buildDatePicker('Start Date', _pendingQuery.startTime, (val) => setState(() => _pendingQuery = _pendingQuery.copyWith(startTime: val, clearStartTime: val == null))),
          const SizedBox(height: 12),
          _buildDatePicker('End Date', _pendingQuery.endTime, (val) => setState(() => _pendingQuery = _pendingQuery.copyWith(endTime: val, clearEndTime: val == null)), isEndDate: true),
          const SizedBox(height: 12),
          _buildTextField('Actor ID', _actorIdController, Icons.person_search_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildResetButton()),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchButton()),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTextField('ESP ID', _espIdController, Icons.search_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Actor ID', _actorIdController, Icons.person_search_rounded)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown<TriggerType>(
                'Trigger Type',
                _pendingQuery.triggerType,
                TriggerType.values,
                (e) => e.value,
                (val) => setState(() => _pendingQuery = _pendingQuery.copyWith(triggerType: val, clearTriggerType: val == null)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown<AdminComponentType>(
                'Component Type',
                _pendingQuery.componentType,
                AdminComponentType.values,
                (e) => e.name.toUpperCase(),
                (val) => setState(() => _pendingQuery = _pendingQuery.copyWith(componentType: val, clearComponentType: val == null)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _buildDatePicker('Start Date', _pendingQuery.startTime, (val) => setState(() => _pendingQuery = _pendingQuery.copyWith(startTime: val, clearStartTime: val == null)))),
            const SizedBox(width: 12),
            Expanded(child: _buildDatePicker('End Date', _pendingQuery.endTime, (val) => setState(() => _pendingQuery = _pendingQuery.copyWith(endTime: val, clearEndTime: val == null)), isEndDate: true)),
            const SizedBox(width: 16),
            _buildResetButton(),
            const SizedBox(width: 12),
            _buildSearchButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return AppTextField(
      controller: controller,
      labelText: label,
      hintText: 'Search by $label',
      prefixIcon: Icon(icon, size: 20),
    );
  }

  Widget _buildDropdown<T>(String label, T? value, List<T> items, String Function(T) itemLabel, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGreyText)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGreyText)),
          ),
          items: [
            DropdownMenuItem<T>(value: null, child: const Text('All')),
            ...items.map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e)))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, ValueChanged<DateTime?> onChanged, {bool isEndDate = false}) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initialDate = value ?? now;
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate.isAfter(now) ? now : initialDate,
          firstDate: DateTime(2020),
          lastDate: now,
        );
        if (date != null) {
          if (isEndDate) {
            onChanged(DateTime(date.year, date.month, date.day, 23, 59, 59));
          } else {
            onChanged(DateTime(date.year, date.month, date.day, 0, 0, 0));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: AppColors.lightGreyText), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? label : _formatDateOnly(value),
                style: TextStyle(color: value == null ? AppColors.greyText : AppColors.darkText, fontSize: 16),
              ),
            ),
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.greyText),
            if (value != null) ...[
              const SizedBox(width: 8),
              InkWell(onTap: () => onChanged(null), child: const Icon(Icons.clear_rounded, size: 18, color: AppColors.greyText)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateOnly(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  Widget _buildSearchButton() {
    return FilledButton.icon(
      onPressed: _applyFilters,
      icon: const Icon(Icons.search_rounded, size: 20),
      label: const Text('Search'),
      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryTeal, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _resetFilters,
      icon: const Icon(Icons.refresh_rounded, size: 20),
      label: const Text('Reset'),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildLogList(TriggerLogPageResult result, bool isMobile) {
    if (result.items.isEmpty) {
      return const Center(
        child: Text(
          'No logs found.',
          style: TextStyle(color: AppColors.greyText, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      children: [
        if (!isMobile) _buildTableHeader(),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(isMobile ? 10 : 16),
            itemCount: result.items.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _TriggerLogTile(
              log: result.items[index],
              isMobile: isMobile,
            ),
          ),
        ),
        _buildPagination(result, isMobile),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightTeal.withValues(alpha: 0.3),
        border: const Border(bottom: BorderSide(color: AppColors.lightGreyText)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 52), // Matching icon space (40 + 12)
          Expanded(
            flex: 4,
            child: Text(
              'Component (Action)',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'LogId',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'ESP',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Com. Id',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText),
            ),
          ),
          SizedBox(width: 100), // Matching badge space
        ],
      ),
    );
  }

  Widget _buildPagination(TriggerLogPageResult result, bool isMobile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Text(
            'Page ${result.page + 1} of ${result.totalPages} • Total ${result.totalElements}',
            style: const TextStyle(color: AppColors.greyText, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: result.hasPrevious ? () => ref.read(triggerLogQueryProvider.notifier).previous() : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: result.hasNext ? () => ref.read(triggerLogQueryProvider.notifier).next() : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 48),
          const SizedBox(height: 10),
          Text(error is ApiException ? error.message : 'Unable to load logs.', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          AppButton(text: 'Retry', onPressed: () => ref.invalidate(triggerLogListProvider)),
        ],
      ),
    );
  }
}

class _TriggerLogTile extends StatelessWidget {
  const _TriggerLogTile({required this.log, required this.isMobile});

  final TriggerLog log;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _buildMobileView(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildTypeIcon(log.componentType),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Text(
                  '${log.componentName} (${log.action})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${log.logId}',
                  style: const TextStyle(color: AppColors.greyText, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  log.espId,
                  style: const TextStyle(color: AppColors.greyText, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${log.componentId}',
                  style: const TextStyle(color: AppColors.greyText, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  log.status.toLowerCase(),
                  style: TextStyle(
                    color: log.status == 'SUCCESS' ? AppColors.success : AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildTriggerTypeBadge(log.triggerType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildInfoItem(Icons.access_time, AppDateTimeFormatter.formatDateTime(log.triggeredAt)),
                if (log.triggeredByUsername != null || log.actorName != null)
                  _buildInfoItem(Icons.person_outline, log.actorName ?? log.triggeredByUsername!),
                if (log.durationMins != null)
                  _buildInfoItem(Icons.timer_outlined, '${log.durationMins} mins'),
                if (log.scheduleId != null)
                  _buildInfoItem(Icons.calendar_today_outlined, 'Schedule: ${log.scheduleId}'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (log.notes != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(
                'Note: ${log.notes!}',
                style: const TextStyle(
                  color: AppColors.greyText,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeIcon(log.componentType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.componentName} (${log.action})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      'LogId: ${log.logId} • ${log.espId} • Component Id: ${log.componentId}',
                      style: const TextStyle(color: AppColors.greyText, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Status: ${log.status.toLowerCase()}',
                      style: TextStyle(
                        color: log.status == 'SUCCESS' ? AppColors.success : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTriggerTypeBadge(log.triggerType),
            ],
          ),
          const SizedBox(height: 8),
          if (log.notes != null) ...[
            Text(
              'Note: ${log.notes!}',
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildInfoItem(Icons.access_time, AppDateTimeFormatter.formatDateTime(log.triggeredAt)),
              if (log.triggeredByUsername != null || log.actorName != null)
                _buildInfoItem(Icons.person_outline, log.actorName ?? log.triggeredByUsername!),
              if (log.durationMins != null)
                _buildInfoItem(Icons.timer_outlined, '${log.durationMins} mins'),
              if (log.scheduleId != null)
                _buildInfoItem(Icons.calendar_today_outlined, 'Schedule: ${log.scheduleId}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.greyText),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.greyText, fontSize: 12)),
      ],
    );
  }

  Widget _buildTypeIcon(AdminComponentType type) {
    final icon = switch (type) {
      AdminComponentType.motor => Icons.settings_input_component_rounded,
      AdminComponentType.valve => Icons.vibration_rounded,
      AdminComponentType.sensor => Icons.sensors_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.lightTeal, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.primaryTeal, size: 20),
    );
  }

  Widget _buildTriggerTypeBadge(TriggerType type) {
    final color = switch (type) {
      TriggerType.manual => AppColors.info,
      TriggerType.scheduled => AppColors.warning,
      TriggerType.auto => AppColors.success,
      TriggerType.autoCutoff => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        type.value,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
