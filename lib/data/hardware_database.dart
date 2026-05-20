import 'package:flutter/material.dart';
import '../models/device_models.dart';

class HardwareDatabase {
  static const List<DeviceCategory> categories = [
    DeviceCategory(id: 'mitv', name: 'Mi TV/Mi Box', icon: Icons.tv_rounded),
    DeviceCategory(id: 'tv', name: 'TV', icon: Icons.tv_off_rounded),
    DeviceCategory(id: 'stb', name: 'Set-top box', icon: Icons.developer_board),
    DeviceCategory(id: 'ac', name: 'AC', icon: Icons.air_rounded),
    DeviceCategory(id: 'fan', name: 'Fan', icon: Icons.toys_rounded),
    DeviceCategory(id: 'smartbox', name: 'Smart box', icon: Icons.dns_rounded),
    DeviceCategory(
      id: 'av',
      name: 'A/V receiver',
      icon: Icons.speaker_group_rounded,
    ),
    DeviceCategory(id: 'dvd', name: 'DVD Player', icon: Icons.album_rounded),
    DeviceCategory(
      id: 'projector',
      name: 'Projector',
      icon: Icons.cast_connected_rounded,
    ),
  ];

  static const Map<String, List<Brand>> brandsByCategory = {
    'ac': [
      Brand(name: 'Gree', isPopular: true),
      Brand(name: 'Midea', isPopular: true),
      Brand(name: 'Haier', isPopular: true),
      Brand(name: 'Aux', isPopular: true),
      Brand(name: 'Daikin', isPopular: true),
      Brand(name: 'Panasonic', isPopular: true),
      Brand(name: '3M'),
      Brand(name: 'ACL'),
      Brand(name: 'Airwell'),
      Brand(name: 'Amico'),
    ],
    'tv': [
      Brand(name: 'Samsung', isPopular: true),
      Brand(name: 'LG', isPopular: true),
      Brand(name: 'Sony', isPopular: true),
      Brand(name: 'TCL', isPopular: true),
      Brand(name: 'Hisense', isPopular: true),
      Brand(name: 'Philips'),
      Brand(name: 'Panasonic'),
      Brand(name: 'Sharp'),
      Brand(name: 'Toshiba'),
      Brand(name: 'Vizio'),
    ],
    'mitv': [
      Brand(name: 'Xiaomi Mi TV 4A', isPopular: true),
      Brand(name: 'Xiaomi Mi Box S', isPopular: true),
      Brand(name: 'Xiaomi Laser Projector', isPopular: true),
      Brand(name: 'Redmi Smart TV', isPopular: false),
    ],
    'projector': [
      Brand(name: 'Epson', isPopular: true),
      Brand(name: 'BenQ', isPopular: true),
      Brand(name: 'Optoma', isPopular: true),
      Brand(name: 'ViewSonic', isPopular: true),
      Brand(name: 'Sony', isPopular: false),
      Brand(name: 'Anker Nebula', isPopular: false),
      Brand(name: 'Acer'),
    ],
    'stb': [
      Brand(name: 'Roku', isPopular: true),
      Brand(name: 'Apple TV', isPopular: true),
      Brand(name: 'Chromecast', isPopular: true),
      Brand(name: 'Arris'),
      Brand(name: 'Cisco'),
    ],

    // ── NEW ENTRIES BELOW ──
    'fan': [
      Brand(name: 'Xiaomi', isPopular: true),
      Brand(name: 'Panasonic', isPopular: true),
      Brand(name: 'Midea', isPopular: true),
      Brand(name: 'KDK', isPopular: true),
      Brand(name: 'Deka', isPopular: true),
      Brand(name: 'Alpha', isPopular: false),
      Brand(name: 'Elmark'),
      Brand(name: 'Fanco'),
      Brand(name: 'Crestar'),
      Brand(name: 'Acorn'),
    ],
    'smartbox': [
      Brand(name: 'Nvidia Shield', isPopular: true),
      Brand(name: 'Amazon Fire TV', isPopular: true),
      Brand(name: 'Xiaomi Mi Box', isPopular: true),
      Brand(name: 'HiMedia', isPopular: true),
      Brand(name: 'Zidoo', isPopular: true),
      Brand(name: 'MXQ Pro', isPopular: false),
      Brand(name: 'H96 Max'),
      Brand(name: 'Tanix'),
      Brand(name: 'Mecool'),
      Brand(name: 'Beelink'),
    ],
    'av': [
      Brand(name: 'Yamaha', isPopular: true),
      Brand(name: 'Denon', isPopular: true),
      Brand(name: 'Onkyo', isPopular: true),
      Brand(name: 'Pioneer', isPopular: true),
      Brand(name: 'Marantz', isPopular: true),
      Brand(name: 'Sony', isPopular: false),
      Brand(name: 'Harman Kardon'),
      Brand(name: 'NAD'),
      Brand(name: 'Anthem'),
      Brand(name: 'Cambridge Audio'),
    ],
    'dvd': [
      Brand(name: 'Sony', isPopular: true),
      Brand(name: 'Samsung', isPopular: true),
      Brand(name: 'LG', isPopular: true),
      Brand(name: 'Panasonic', isPopular: true),
      Brand(name: 'Pioneer', isPopular: true),
      Brand(name: 'Philips', isPopular: false),
      Brand(name: 'Toshiba'),
      Brand(name: 'Coby'),
      Brand(name: 'Magnavox'),
      Brand(name: 'Funai'),
    ],
  };

  static List<Brand> getBrandsForCategory(String categoryId) {
    return brandsByCategory[categoryId] ??
        [
          const Brand(name: 'Generic Brand V1', isPopular: true),
          const Brand(name: 'Universal Learning Profile'),
        ];
  }
}
