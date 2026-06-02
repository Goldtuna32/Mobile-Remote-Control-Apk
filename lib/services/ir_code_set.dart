import 'package:flutter/material.dart';
import 'package:remote_control/data/ir_database.dart';
import 'ir_code.dart';

class IrCodeSet {
  final int configIndex;
  final List<IrCode> codes;

  const IrCodeSet({required this.configIndex, required this.codes});
}

class IrCodeService {
  static Future<List<IrCodeSet>> getConfigurationsForBrand({
    required String categoryId,
    required String brand,
  }) async {
    try {
      debugPrint(
        '[IrCodeService] Querying Category: $categoryId | Brand: $brand',
      );

      final List<IrCode> codes = IrDatabase.getCodes(categoryId, brand);
      debugPrint('[IrCodeService] Found ${codes.length} codes');

      if (codes.isEmpty) {
        debugPrint(
          '[IrCodeService] ⚠️ No real codes found. Injecting mock codes for UI testing.',
        );
        final mockCodes = [
          IrCode(action: 'power', frequency: 38000, pattern: [1000, 1000]),
          IrCode(action: 'volume_up', frequency: 38000, pattern: [1000, 1000]),
          IrCode(
            action: 'volume_down',
            frequency: 38000,
            pattern: [1000, 1000],
          ),
          IrCode(action: 'menu', frequency: 38000, pattern: [1000, 1000]),
        ];
        return [IrCodeSet(configIndex: 0, codes: mockCodes)];
      }

      return [IrCodeSet(configIndex: 1, codes: codes)];
    } catch (e) {
      debugPrint("Error converting configuration $e");
      return [];
    }
  }

  static Future<IrCode?> getCode(
    String categoryId,
    String brand,
    String action,
  ) async {
    final codes = IrDatabase.getCodes(categoryId, brand);
    try {
      return codes.firstWhere((c) => c.action == action);
    } catch (_) {
      return null;
    }
  }
}
