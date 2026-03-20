import 'package:wms/core/api/api.dart';

class AdminCustomerRequest {
  const AdminCustomerRequest({
    required this.phoneNumber,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.village,
    required this.addressLine1,
    required this.district,
    required this.state,
    required this.pincode,
    required this.espUnitIds,
    this.addressLine2,
    this.taluka,
  });

  final String phoneNumber;
  final String username;
  final String password;
  final String fullName;
  final String email;
  final String village;
  final String addressLine1;
  final String? addressLine2;
  final String? taluka;
  final String district;
  final String state;
  final String pincode;
  final List<String> espUnitIds;

  Map<String, dynamic> toJson() {
    final normalizedAddressLine1 = _requiredTrimmed(
      addressLine1,
      'Address Line 1',
    );
    final normalizedAddressLine2 = (addressLine2 ?? '').trim();
    final normalizedTaluka = (taluka ?? '').trim();
    final normalizedDistrict = _requiredTrimmed(district, 'District');
    final normalizedState = _requiredTrimmed(state, 'State');
    final normalizedPincode = _requiredTrimmed(pincode, 'Pincode');

    final normalizedEspUnitIds = espUnitIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id.toLowerCase() != 'string')
        .toSet()
        .toList();

    return {
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'village': village,
      'addressLine1': normalizedAddressLine1,
      'addressLine2': normalizedAddressLine2,
      'taluka': normalizedTaluka,
      'district': normalizedDistrict,
      'state': normalizedState,
      'pincode': normalizedPincode,
      'espUnitIds': normalizedEspUnitIds,
    };
  }
}

class AdminCustomerUpdateRequest {
  const AdminCustomerUpdateRequest({
    required this.fullName,
    required this.email,
    required this.village,
    required this.addressLine1,
    required this.district,
    required this.state,
    required this.pincode,
    this.addressLine2,
    this.taluka,
  });

  final String fullName;
  final String email;
  final String village;
  final String addressLine1;
  final String? addressLine2;
  final String? taluka;
  final String district;
  final String state;
  final String pincode;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'village': village,
      'addressLine1': addressLine1.trim(),
      'addressLine2': (addressLine2 ?? '').trim(),
      'taluka': (taluka ?? '').trim(),
      'district': district,
      'state': state,
      'pincode': pincode,
    };
  }
}

class AdminCustomerAssignDevicesRequest {
  const AdminCustomerAssignDevicesRequest({
    required this.userId,
    required this.espUnitIds,
  });

  final String userId;
  final List<String> espUnitIds;

  Map<String, dynamic> toJson() {
    final normalizedEspUnitIds = espUnitIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id.toLowerCase() != 'string')
        .toSet()
        .toList();
    return {'userId': userId.trim(), 'espUnitIds': normalizedEspUnitIds};
  }
}

class AdminCustomerSummary {
  const AdminCustomerSummary({
    required this.id,
    required this.phoneNumber,
    required this.username,
    required this.fullName,
    required this.email,
    required this.village,
    required this.addressLine1,
    required this.addressLine2,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pincode,
    required this.espUnitIds,
  });

  final String id;
  final String phoneNumber;
  final String username;
  final String fullName;
  final String email;
  final String village;
  final String addressLine1;
  final String addressLine2;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final List<String> espUnitIds;

  String get formattedAddress {
    final parts = <String>[
      village,
      addressLine1,
      addressLine2,
      taluka,
      district,
      state,
      pincode,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  factory AdminCustomerSummary.fromJson(Map<String, dynamic> json) {
    final espUnitsRaw = json['espUnitIds'] ?? json['espIds'] ?? json['devices'];
    final espUnitIds = espUnitsRaw is List
        ? espUnitsRaw
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
        : const <String>[];

    return AdminCustomerSummary(
      id: _extractCustomerId(json),
      phoneNumber: _readStringByKeys(json, const ['phoneNumber', 'phone']),
      username: _readStringByKeys(json, const ['username', 'userName']),
      fullName: _readStringByKeys(json, const ['fullName', 'name']),
      email: _readStringByKeys(json, const ['email', 'mail']),
      village: _readStringByKeys(json, const ['village', 'city']),
      addressLine1: _readStringByKeys(json, const [
        'addressLine1',
        'address1',
        'address',
        'line1',
      ]),
      addressLine2: _readStringByKeys(json, const [
        'addressLine2',
        'address2',
        'line2',
      ]),
      taluka: _readStringByKeys(json, const ['taluka', 'tehsil']),
      district: _readStringByKeys(json, const ['district', 'districtName']),
      state: _readStringByKeys(json, const ['state', 'stateName']),
      pincode: _readStringByKeys(json, const [
        'pincode',
        'pinCode',
        'postalCode',
        'zipCode',
        'zip',
      ]),
      espUnitIds: espUnitIds,
    );
  }
}

class AdminUnassignedDevice {
  const AdminUnassignedDevice({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory AdminUnassignedDevice.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['espId'] ?? json['deviceId'] ?? '')
        .toString();
    final name =
        (json['displayName'] ?? json['name'] ?? json['macAddress'] ?? id)
            .toString();
    return AdminUnassignedDevice(id: id, displayName: name);
  }
}

class AdminCustomerDeviceComponent {
  const AdminCustomerDeviceComponent({
    required this.componentId,
    required this.type,
    required this.gpioPin,
    required this.name,
    required this.currentState,
    required this.active,
    this.stateChangedAt,
  });

  final int componentId;
  final String type;
  final int gpioPin;
  final String name;
  final String currentState;
  final bool active;
  final DateTime? stateChangedAt;

  factory AdminCustomerDeviceComponent.fromJson(Map<String, dynamic> json) {
    return AdminCustomerDeviceComponent(
      componentId: (json['componentId'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? '').toString().trim(),
      gpioPin: (json['gpioPin'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString().trim(),
      currentState: (json['currentState'] ?? '').toString().trim(),
      active: (json['active'] ?? json['isActive'] ?? false) == true,
      stateChangedAt: _tryParseDateTime(json['stateChangedAt']),
    );
  }
}

class AdminCustomerAssignedDevice {
  const AdminCustomerAssignedDevice({
    required this.espId,
    required this.macAddress,
    required this.displayName,
    required this.fwVersion,
    required this.components,
    required this.active,
    required this.online,
    this.lastHeartbeat,
    this.amcExpiry,
    this.rechargeExpiry,
    this.createdAt,
  });

  final String espId;
  final String macAddress;
  final String displayName;
  final String fwVersion;
  final DateTime? lastHeartbeat;
  final DateTime? amcExpiry;
  final DateTime? rechargeExpiry;
  final DateTime? createdAt;
  final List<AdminCustomerDeviceComponent> components;
  final bool active;
  final bool online;

  factory AdminCustomerAssignedDevice.fromJson(Map<String, dynamic> json) {
    final componentsRaw = json['components'];
    final components = componentsRaw is List
        ? componentsRaw
              .whereType<Map<String, dynamic>>()
              .map(AdminCustomerDeviceComponent.fromJson)
              .toList()
        : const <AdminCustomerDeviceComponent>[];

    return AdminCustomerAssignedDevice(
      espId: (json['espId'] ?? json['id'] ?? '').toString().trim(),
      macAddress: (json['macAddress'] ?? '').toString().trim(),
      displayName: (json['displayName'] ?? json['name'] ?? '')
          .toString()
          .trim(),
      fwVersion: (json['fwVersion'] ?? '').toString().trim(),
      lastHeartbeat: _tryParseDateTime(json['lastHeartbeat']),
      amcExpiry: _tryParseDateTime(json['amcExpiry']),
      rechargeExpiry: _tryParseDateTime(json['rechargeExpiry']),
      createdAt: _tryParseDateTime(json['createdAt']),
      components: components,
      active: (json['active'] ?? json['isActive'] ?? false) == true,
      online: (json['online'] ?? false) == true,
    );
  }
}

class AdminCustomerAssignedDevicePageResult {
  const AdminCustomerAssignedDevicePageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
  });

  final List<AdminCustomerAssignedDevice> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

class AdminCustomerPageResult {
  const AdminCustomerPageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
  });

  final List<AdminCustomerSummary> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

String _requiredTrimmed(String value, String label) {
  final text = value.trim();
  if (text.isEmpty) {
    throw ApiException('$label is required.');
  }
  return text;
}

String _extractCustomerId(Map<String, dynamic> json) {
  const keys = <String>[
    'id',
    'userId',
    'userID',
    'user_id',
    'customerId',
    'customerID',
    'customer_id',
    'uuid',
    'customerUuid',
    'customerUUID',
  ];
  for (final key in keys) {
    final value = json[key];
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

String _readStringByKeys(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  final raw = value.toString().trim();
  if (raw.isEmpty || raw.toLowerCase() == 'null') {
    return null;
  }
  return DateTime.tryParse(raw);
}
