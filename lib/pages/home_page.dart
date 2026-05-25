import 'package:flutter/material.dart';
import 'package:remote_control/models/device_models.dart';
import 'package:remote_control/models/saved_device.dart';
import 'package:remote_control/pages/device_page.dart';
import 'package:remote_control/pages/remote_control_page.dart';
import 'package:remote_control/services/device_storage_service.dart';
import 'package:remote_control/data/hardware_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<SavedDevice> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final devices = await DeviceStorageService.loadDevices();
    setState(() {
      _devices = devices;
      _isLoading = false;
    });
  }

  Future<void> _deleteDevice(String id) async {
    await DeviceStorageService.deleteDevice(id);
    _loadDevices();
  }

  IconData _iconForCategory(String categoryId) {
    return HardwareDatabase.categories
        .firstWhere(
          (c) => c.id == categoryId,
          orElse: () => const DeviceCategory(
            id: '',
            name: '',
            icon: Icons.devices_rounded,
          ),
        )
        .icon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mi Remote',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.grey),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DevicePage()),
              );
              _loadDevices(); // refresh after returning
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _devices.isEmpty
          ? _buildEmptyState()
          : _buildDeviceList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline_rounded, size: 100, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text(
            'Add New',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return Dismissible(
          key: Key(device.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.red),
          ),
          onDismissed: (_) => _deleteDevice(device.id),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RemoteControlPage(
                  categoryId: device.categoryId,
                  brand: device.brand,
                  configIndex: device.configIndex,
                  savedDevice: device, // uses cached IR codes
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _iconForCategory(device.categoryId),
                    color: Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.brand,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.roomName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
