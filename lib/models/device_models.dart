import 'package:flutter/material.dart';

class DeviceCategory {
  final String id;
  final String name;
  final IconData icon;

  const DeviceCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class Brand {
  final String name;
  final bool isPopular;

  const Brand({required this.name, this.isPopular = false});
}
