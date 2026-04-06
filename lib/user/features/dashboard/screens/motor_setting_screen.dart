import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

class MotorSettingScreen extends ConsumerStatefulWidget {
  const MotorSettingScreen({required this.device, super.key});

  final CustomerDeviceSummary device;

  @override
  ConsumerState<MotorSettingScreen> createState() => _MotorSettingScreenState();
}

class _MotorSettingScreenState extends ConsumerState<MotorSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  String? _appliedSettingsKey;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final args = MotorSettingArgs(
        espId: widget.device.espId,
        initialComponents: widget.device.componentDetails,
      );
      final error = await ref
          .read(motorSettingProvider(args))
          .ensureInitialDataLoaded();
      if (error != null && mounted) {
        showAppSnackBar(
          context,
          error,
          status: AppSnackBarStatus.error,
        );
      }
    });
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = MotorSettingArgs(
      espId: widget.device.espId,
      initialComponents: widget.device.componentDetails,
    );
    final controller = ref.watch(motorSettingProvider(args));
    final state = controller.state;
    final settings = state.settings;
    final settingsKey = settings == null
        ? null
        : '${settings.minLevel}|${settings.maxLevel}|${settings.lastSyncedAt}';
    if (settingsKey != null && settingsKey != _appliedSettingsKey) {
      final resolvedSettings = settings!;
      _minController.text = resolvedSettings.minLevel > 0
          ? '${resolvedSettings.minLevel}'
          : '';
      _maxController.text = resolvedSettings.maxLevel > 0
          ? '${resolvedSettings.maxLevel}'
          : '';
      _appliedSettingsKey = settingsKey;
    }
    final motorComponent = controller.motorComponent;
    final sensorComponent = controller.sensorComponent;
    final canSubmit =
        !state.isSubmitting &&
        !state.isLoadingComponents &&
        !state.isLoadingSettings &&
        motorComponent?.componentId.trim().isNotEmpty == true &&
        sensorComponent?.componentId.trim().isNotEmpty == true;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Motor Setting'),
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 2,
        shadowColor: const Color(0x26000000),
      ),
      body: AppPageBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReadOnlyDetailRow(
                      label: 'Last Synced',
                      value: _formatLastSyncedAt(settings?.lastSyncedAt ?? ''),
                    ),
                    const SizedBox(height: 16),
                    _ReadOnlyDetailRow(
                      label: 'Motor',
                      value: _formatGpioValue(motorComponent),
                    ),
                    const SizedBox(height: 12),
                    _ReadOnlyDetailRow(
                      label: 'Sensor',
                      value: _formatGpioValue(sensorComponent),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _minController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _inputDecoration(
                        labelText: 'Min',
                        hintText: 'Enter minimum value',
                      ),
                      validator: _validateMin,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _inputDecoration(
                        labelText: 'Max',
                        hintText: 'Enter maximum value',
                      ),
                      validator: _validateMax,
                    ),
                    if (!canSubmit) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.isLoadingComponents
                            ? 'Loading component details...'
                            : state.isLoadingSettings
                            ? 'Loading motor settings...'
                            : 'Motor and sensor components are required to save settings.',
                        style: const TextStyle(
                          color: AppColors.greyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canSubmit
                            ? () => _submit(
                                controller: ref.read(motorSettingProvider(args)),
                              )
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit({
    required MotorSettingController controller,
  }) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final motorComponent = controller.motorComponent;
    final sensorComponent = controller.sensorComponent;
    if (motorComponent == null || sensorComponent == null) {
      showAppSnackBar(
        context,
        'Motor and sensor components are required.',
        status: AppSnackBarStatus.error,
      );
      return;
    }

    final min = int.parse(_minController.text.trim());
    final max = int.parse(_maxController.text.trim());

    final error = await controller.submit(min: min, max: max);
    if (!mounted) {
      return;
    }

    if (error == null) {
      showAppSnackBar(
        context,
        'Motor settings updated successfully.',
        status: AppSnackBarStatus.success,
      );
      Navigator.of(context).pop();
      return;
    }

    showAppSnackBar(
      context,
      error,
      status: AppSnackBarStatus.error,
    );
  }

  String _formatGpioValue(CustomerDeviceComponent? component) {
    if (component == null) {
      return '0';
    }
    return component.gpioPin.toString();
  }

  String _formatLastSyncedAt(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return '-';
    }
    return AppDateTimeFormatter.formatString(value);
  }

  String? _validateMin(String? value) {
    return _validateNumber(value, label: 'Min', compareWithMax: true);
  }

  String? _validateMax(String? value) {
    return _validateNumber(value, label: 'Max', compareWithMin: true);
  }

  String? _validateNumber(
    String? value, {
    required String label,
    bool compareWithMin = false,
    bool compareWithMax = false,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$label is required.';
    }
    final parsed = int.tryParse(normalized);
    if (parsed == null) {
      return '$label must be an integer.';
    }
    if (parsed == 0) {
      return '$label cannot be 0.';
    }

    final min = int.tryParse(_minController.text.trim());
    final max = int.tryParse(_maxController.text.trim());

    if (compareWithMax && max != null && parsed > max) {
      return 'Min cannot be greater than max.';
    }
    if (compareWithMin && min != null && parsed < min) {
      return 'Max must be greater than or equal to min.';
    }

    return null;
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      isDense: true,
      fillColor: AppColors.white,
      labelStyle: const TextStyle(color: AppColors.greyText),
      hintStyle: const TextStyle(color: AppColors.lightGreyText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightGreyText),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightGreyText),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.4),
      ),
    );
  }
}

class _ReadOnlyDetailRow extends StatelessWidget {
  const _ReadOnlyDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.greyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
