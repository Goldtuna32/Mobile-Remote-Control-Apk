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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          'Mi Remote',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add device',
            icon: const Icon(Icons.add_circle_rounded, color: Colors.grey),
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHero(theme),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _isLoading
                    ? _buildLoading()
                    : _devices.isEmpty
                    ? _buildEmptyState()
                    : _buildDeviceList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    const Color card = Color(0xFF111111);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: (0.55 * 255).round() / 255),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D2D2D), Color(0xFF3A3A3A)],
                ),
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(
                Icons.devices_rounded,
                color: Colors.white.withValues(
                  alpha: (0.85 * 255).round() / 255,
                ),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your devices',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoading
                        ? 'Loading...'
                        : '${_devices.length} device${_devices.length == 1 ? '' : 's'} saved',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.add_box_rounded,
                size: 54,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add your first device',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the + button to set up a new remote.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: (0.65 * 255).round() / 255,
                ),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForCategory(String categoryId) {
    switch (categoryId) {
      case 'ac':
        return const Color(0xFF3DAA72);
      case 'tv':
      case 'mitv':
      case 'stb':
      case 'smartbox':
        return const Color(0xFF6C63FF);
      case 'fan':
        return const Color(0xFF1A7A6E);
      default:
        return const Color(0xFF8A8A8A);
    }
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      key: const ValueKey('devices'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final accent = _colorForCategory(device.categoryId);

        return Dismissible(
          key: Key(device.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: (0.25 * 255).round() / 255),
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
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF151515),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: (0.08 * 255).round() / 255),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(
                        alpha: (0.14 * 255).round() / 255,
                      ),
                      border: Border.all(
                        color: accent.withValues(
                          alpha: (0.32 * 255).round() / 255,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _iconForCategory(device.categoryId),
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                device.brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _CategoryChip(
                              label: HardwareDatabase.categories
                                  .firstWhere(
                                    (c) => c.id == device.categoryId,
                                    orElse: () => const DeviceCategory(
                                      id: '',
                                      name: 'Device',
                                      icon: Icons.devices_rounded,
                                    ),
                                  )
                                  .name,
                              accent: accent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          device.roomName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: (0.65 * 255).round() / 255,
                            ),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _CategoryChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: (0.12 * 255).round() / 255),
        border: Border.all(
          color: accent.withValues(alpha: (0.35 * 255).round() / 255),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: (0.78 * 255).round() / 255),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
