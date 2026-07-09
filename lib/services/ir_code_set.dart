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
    final codes = IrDatabase.getCodes(categoryId, brand);
    if (codes.isEmpty) return [];
    return [IrCodeSet(configIndex: 1, codes: codes)];
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
