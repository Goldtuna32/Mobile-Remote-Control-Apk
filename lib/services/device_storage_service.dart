import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:remote_control/data/ir_database.dart';
import 'package:remote_control/services/ir_code.dart';
import 'package:remote_control/services/ir_code_set.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_device.dart';

class DeviceStorageService {
  static const _key = 'saved_devices';

  static Future<List<SavedDevice>> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SavedDevice.fromJson(e)).toList();
  }

  static Future<void> saveDevice(SavedDevice device) async {
    final devices = await loadDevices();
    devices.add(device);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(devices.map((d) => d.toJson()).toList()),
    );
  }

  static Future<void> deleteDevice(String id) async {
    final devices = await loadDevices();
    devices.removeWhere((d) => d.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(devices.map((d) => d.toJson()).toList()),
    );
  }

  static Future<List<IrCodeSet>> getConfigurationsForBrand({
    required String categoryId,
    required String brand,
  }) async {
    try {
      final List<IrCode> rawCodes = IrDatabase.getCodes(categoryId, brand);

      if (rawCodes.isEmpty) return [];

      final runtimeConfigSet = IrCodeSet(configIndex: 1, codes: rawCodes);

      return [runtimeConfigSet];
    } catch (e) {
      debugPrint("Error converting configurations: $e");
      return [];
    }
  }
}
