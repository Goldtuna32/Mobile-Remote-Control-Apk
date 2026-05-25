import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_control/models/saved_device.dart';
import '../services/ir_service.dart';
import '../services/ir_code_set.dart';

// ── Device type declaration ─────────────────────────────
enum DeviceType { ac, tv, fan, generic }

DeviceType resolveDeviceType(String categoryId) {
  switch (categoryId) {
    case 'ac':
      return DeviceType.ac;
    case 'tv':
    case 'mitv':
    case 'smartbox':
    case 'stb':
      return DeviceType.tv;
    case 'fan':
      return DeviceType.fan;
    default:
      return DeviceType.generic;
  }
}

class AcState {
  int temperature;
  String mode;
  bool isOn;

  AcState({this.temperature = 24, this.mode = 'cool', this.isOn = false});
}

// ── Page ────────────────────────────────────────────────
class RemoteControlPage extends StatefulWidget {
  final String categoryId;
  final String brand;
  final int configIndex;
  final SavedDevice? savedDevice;

  const RemoteControlPage({
    super.key,
    required this.categoryId,
    required this.brand,
    required this.configIndex,
    this.savedDevice,
  });

  @override
  State<RemoteControlPage> createState() => _RemoteControlPageState();
}

class _RemoteControlPageState extends State<RemoteControlPage> {
  final AcState _acState = AcState();
  IrCodeSet? _codeSet;
  bool _isLoading = true;
  late final DeviceType _deviceType;

  @override
  void initState() {
    super.initState();
    _deviceType = resolveDeviceType(widget.categoryId);
    _loadCodeSet();
  }

  Future<void> _loadCodeSet() async {
    if (widget.savedDevice != null) {
      setState(() {
        _codeSet = IrCodeSet(
          configIndex: widget.savedDevice!.configIndex,
          codes: widget.savedDevice!.codes,
        );
        _isLoading = false;
      });
      return;
    }

    final configs = await IrCodeService.getConfigurationsForBrand(
      categoryId: widget.categoryId,
      brand: widget.brand,
    );
    setState(() {
      _codeSet = configs.isNotEmpty ? configs[widget.configIndex] : null;
      _isLoading = false;
    });
  }

  Future<void> _sendCommand(String action) async {
    if (_codeSet == null) return;
    final code = _codeSet!.codes.firstWhere(
      (c) => c.action == action,
      orElse: () => _codeSet!.codes.first,
    );
    HapticFeedback.mediumImpact();
    try {
      await IrService.transmit(
        carrierFrequency: code.frequency,
        pattern: code.pattern,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }

    setState(() {
      switch (action) {
        case 'power':
          _acState.isOn = !_acState.isOn;
        case 'temp_up':
          if (_acState.temperature < 30) _acState.temperature++;
        case 'temp_down':
          if (_acState.temperature > 16) _acState.temperature--;
        case 'cool':
          _acState.mode = 'cool';
        case 'heat':
          _acState.mode = 'heat';
        case 'fan':
          _acState.mode = 'fan';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.brand} ${widget.categoryId.toUpperCase()}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: switch (_deviceType) {
                DeviceType.ac => _buildAcLayout(),
                DeviceType.tv => _buildTvLayout(),
                DeviceType.fan => _buildFanLayout(),
                DeviceType.generic => _buildGenericLayout(),
              },
            ),
    );
  }

  // ── AC layout ────────────────────────────────────────
  Widget _buildAcLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Status card ──────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_acState.temperature}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _acState.isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: _acState.isOn
                          ? const Color(0xFF3DAA72)
                          : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _acState.mode.toUpperCase(),
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // ── Power ────────────────────────────────────────
        _RemoteButton(
          icon: Icons.power_settings_new_rounded,
          label: 'Power',
          color: _acState.isOn
              ? const Color(0xFF3DAA72)
              : const Color(0xFF2A2A2A),
          size: 80,
          onTap: () => _sendCommand('power'),
        ),

        const SizedBox(height: 40),

        // ── Temperature row ───────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              icon: Icons.remove_rounded,
              label: 'Temp −',
              onTap: () => _sendCommand('temp_down'),
            ),
            const SizedBox(width: 48),
            _RemoteButton(
              icon: Icons.add_rounded,
              label: 'Temp +',
              onTap: () => _sendCommand('temp_up'),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ── Mode row ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              icon: Icons.ac_unit_rounded,
              label: 'Cool',
              color: _acState.mode == 'cool'
                  ? const Color(0xFF1A4FCC)
                  : const Color(0xFF1E1E1E),
              onTap: () => _sendCommand('cool'),
            ),
            const SizedBox(width: 24),
            _RemoteButton(
              icon: Icons.local_fire_department_rounded,
              label: 'Heat',
              color: _acState.mode == 'heat'
                  ? const Color(0xFFCC4A1A)
                  : const Color(0xFF1E1E1E),
              onTap: () => _sendCommand('heat'),
            ),
            const SizedBox(width: 24),
            _RemoteButton(
              icon: Icons.air_rounded,
              label: 'Fan',
              color: _acState.mode == 'fan'
                  ? const Color(0xFF1A7A6E)
                  : const Color(0xFF1E1E1E),
              onTap: () => _sendCommand('fan'),
            ),
          ],
        ),
      ],
    );
  }

  // ── TV layout ────────────────────────────────────────
  Widget _buildTvLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Power
        _RemoteButton(
          icon: Icons.power_settings_new_rounded,
          label: 'Power',
          color: const Color(0xFF3DAA72),
          size: 80,
          onTap: () => _sendCommand('power'),
        ),
        const SizedBox(height: 48),

        // Volume row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              icon: Icons.volume_down_rounded,
              label: 'Vol −',
              onTap: () => _sendCommand('volume_down'),
            ),
            const SizedBox(width: 32),
            _RemoteButton(
              icon: Icons.volume_up_rounded,
              label: 'Vol +',
              onTap: () => _sendCommand('volume_up'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Channel row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'Ch −',
              onTap: () => _sendCommand('channel_down'),
            ),
            const SizedBox(width: 32),
            _RemoteButton(
              icon: Icons.keyboard_arrow_up_rounded,
              label: 'Ch +',
              onTap: () => _sendCommand('channel_up'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Mute
        _RemoteButton(
          icon: Icons.volume_off_rounded,
          label: 'Mute',
          onTap: () => _sendCommand('mute'),
        ),
      ],
    );
  }

  // ── Fan layout ───────────────────────────────────────
  Widget _buildFanLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RemoteButton(
          icon: Icons.power_settings_new_rounded,
          label: 'Power',
          color: const Color(0xFF3DAA72),
          size: 80,
          onTap: () => _sendCommand('power'),
        ),
        const SizedBox(height: 48),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              icon: Icons.speed_rounded,
              label: 'Speed −',
              onTap: () => _sendCommand('speed_down'),
            ),
            const SizedBox(width: 32),
            _RemoteButton(
              icon: Icons.speed_rounded,
              label: 'Speed +',
              onTap: () => _sendCommand('speed_up'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _RemoteButton(
          icon: Icons.rotate_right_rounded,
          label: 'Swing',
          onTap: () => _sendCommand('swing'),
        ),
      ],
    );
  }

  // ── Generic layout (fallback) ────────────────────────
  Widget _buildGenericLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RemoteButton(
          icon: Icons.power_settings_new_rounded,
          label: 'Power',
          color: const Color(0xFF3DAA72),
          size: 80,
          onTap: () => _sendCommand('power'),
        ),
      ],
    );
  }
}

// ── Reusable button widget ───────────────────────────────
class _RemoteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const _RemoteButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF1E1E1E),
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
