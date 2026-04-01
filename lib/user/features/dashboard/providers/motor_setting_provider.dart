import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/providers/customer_devices_providers.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

class MotorSettingArgs {
  const MotorSettingArgs({
    required this.espId,
    required this.initialComponents,
  });

  final String espId;
  final List<CustomerDeviceComponent> initialComponents;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! MotorSettingArgs || other.espId != espId) {
      return false;
    }
    if (other.initialComponents.length != initialComponents.length) {
      return false;
    }
    for (var index = 0; index < initialComponents.length; index++) {
      final left = initialComponents[index];
      final right = other.initialComponents[index];
      if (left.componentId != right.componentId ||
          left.displayName != right.displayName ||
          left.installedArea != right.installedArea ||
          left.type != right.type ||
          left.gpioPin != right.gpioPin) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    espId,
    Object.hashAll(
      initialComponents.map(
        (item) => Object.hash(
          item.componentId,
          item.displayName,
          item.installedArea,
          item.type,
          item.gpioPin,
        ),
      ),
    ),
  );
}

class MotorSettingState {
  const MotorSettingState({
    required this.components,
    required this.settings,
    required this.isLoadingComponents,
    required this.isLoadingSettings,
    required this.isSubmitting,
  });

  final List<CustomerDeviceComponent> components;
  final CustomerMotorSettings? settings;
  final bool isLoadingComponents;
  final bool isLoadingSettings;
  final bool isSubmitting;

  MotorSettingState copyWith({
    List<CustomerDeviceComponent>? components,
    CustomerMotorSettings? settings,
    bool clearSettings = false,
    bool? isLoadingComponents,
    bool? isLoadingSettings,
    bool? isSubmitting,
  }) {
    return MotorSettingState(
      components: components ?? this.components,
      settings: clearSettings ? null : (settings ?? this.settings),
      isLoadingComponents: isLoadingComponents ?? this.isLoadingComponents,
      isLoadingSettings: isLoadingSettings ?? this.isLoadingSettings,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final motorSettingProvider = legacy.ChangeNotifierProvider.autoDispose
    .family<MotorSettingController, MotorSettingArgs>(
      (ref, args) => MotorSettingController(ref, args),
    );

class MotorSettingController extends ChangeNotifier {
  MotorSettingController(this.ref, this.args)
    : _state = MotorSettingState(
        components: args.initialComponents,
        settings: null,
        isLoadingComponents: false,
        isLoadingSettings: false,
        isSubmitting: false,
      );

  final Ref ref;
  final MotorSettingArgs args;
  MotorSettingState _state;

  MotorSettingState get state => _state;

  CustomerDeviceComponent? get motorComponent =>
      _findComponentByType('MOTOR') ?? _findComponentByName('motor');

  CustomerDeviceComponent? get sensorComponent =>
      _findComponentByType('SENSOR') ?? _findComponentByName('sensor');

  Future<String?> ensureInitialDataLoaded() async {
    final componentsError = await ensureComponentsLoaded();
    if (componentsError != null) {
      return componentsError;
    }
    return ensureSettingsLoaded();
  }

  Future<String?> ensureComponentsLoaded() async {
    final motorComponent = this.motorComponent;
    final sensorComponent = this.sensorComponent;
    final needsReload =
        motorComponent == null ||
        sensorComponent == null ||
        motorComponent.gpioPin == 0 ||
        sensorComponent.gpioPin == 0;

    if (!needsReload || _state.isLoadingComponents) {
      return null;
    }

    _updateState(_state.copyWith(isLoadingComponents: true));
    try {
      final token = await _resolveToken();
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      final components = await ref
          .read(customerDevicesServiceProvider)
          .getDeviceComponents(bearerToken: token, espId: args.espId);
      _updateState(
        _state.copyWith(
          components: components,
          isLoadingComponents: false,
        ),
      );
      return null;
    } catch (error) {
      _updateState(_state.copyWith(isLoadingComponents: false));
      return error.toString();
    }
  }

  Future<String?> ensureSettingsLoaded() async {
    if (_state.settings != null || _state.isLoadingSettings) {
      return null;
    }

    _updateState(_state.copyWith(isLoadingSettings: true));
    try {
      final motorComponent = this.motorComponent;
      if (motorComponent == null || motorComponent.componentId.trim().isEmpty) {
        throw const ApiException('Motor ID is missing.');
      }

      final token = await _resolveToken();
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      final settings = await ref
          .read(customerDevicesServiceProvider)
          .getMotorSettings(
            bearerToken: token,
            motorId: motorComponent.componentId,
          );
      _updateState(
        _state.copyWith(
          settings: settings,
          isLoadingSettings: false,
        ),
      );
      return null;
    } catch (error) {
      _updateState(_state.copyWith(isLoadingSettings: false));
      return error.toString();
    }
  }

  Future<String?> submit({
    required int min,
    required int max,
  }) async {
    final motorComponent = this.motorComponent;
    final sensorComponent = this.sensorComponent;
    if (motorComponent == null || sensorComponent == null) {
      return 'Motor and sensor components are required.';
    }

    _updateState(_state.copyWith(isSubmitting: true));
    try {
      final token = await _resolveToken();
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      await ref
          .read(customerDevicesServiceProvider)
          .updateMotorSettings(
            bearerToken: token,
            motorId: motorComponent.componentId,
            sensorId: sensorComponent.componentId,
            min: min,
            max: max,
          );
      final refreshedSettings = _state.settings == null
          ? null
          : CustomerMotorSettings(
              motorId: motorComponent.componentId,
              sensorId: sensorComponent.componentId,
              minLevel: min,
              maxLevel: max,
              active: _state.settings!.active,
              syncStatus: _state.settings!.syncStatus,
              lastSyncedAt: _state.settings!.lastSyncedAt,
            );
      _updateState(
        _state.copyWith(
          settings: refreshedSettings,
          isSubmitting: false,
        ),
      );
      return null;
    } catch (error) {
      _updateState(_state.copyWith(isSubmitting: false));
      return error.toString();
    }
  }

  CustomerDeviceComponent? _findComponentByType(String type) {
    for (final component in _state.components) {
      if (component.type.trim().toUpperCase() == type) {
        return component;
      }
    }
    return null;
  }

  CustomerDeviceComponent? _findComponentByName(String fragment) {
    final normalizedFragment = fragment.trim().toLowerCase();
    for (final component in _state.components) {
      final name = component.displayName.trim().toLowerCase();
      if (name.contains(normalizedFragment)) {
        return component;
      }
    }
    return null;
  }

  Future<String> _resolveToken() async {
    final session = ref.read(currentAuthSessionProvider);
    return (session?.token ?? '').trim();
  }

  void _updateState(MotorSettingState value) {
    _state = value;
    notifyListeners();
  }
}
