import 'dart:convert';
import '../services/ir_code.dart';

class SavedDevice {
  final String id;
  final String categoryId;
  final String brand;
  final String roomName;
  final int configIndex;
  final List<IrCode> codes;

  const SavedDevice({
    required this.id,
    required this.categoryId,
    required this.brand,
    required this.roomName,
    required this.configIndex,
    required this.codes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'brand': brand,
    'roomName': roomName,
    'configIndex': configIndex,
    'codes': codes.map((c) => c.toJson()).toList(),
  };

  factory SavedDevice.fromJson(Map<String, dynamic> json) => SavedDevice(
    id: json['id'],
    categoryId: json['categoryId'],
    brand: json['brand'],
    roomName: json['roomName'],
    configIndex: json['configIndex'],
    codes: (json['codes'] as List).map((e) => IrCode.fromJson(e)).toList(),
  );
}
