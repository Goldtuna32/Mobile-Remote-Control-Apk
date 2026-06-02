import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_control/models/saved_device.dart';
import 'package:remote_control/services/ir_code.dart';
import 'package:remote_control/services/smart_tv_service.dart';
import '../services/ir_service.dart';
import '../services/ir_code_set.dart';

enum DeviceType {
  ac,
  tv,
  fan,
  generic,
  smartBox,
  projector,
  avReceiver,
  dvdPlayer,
}

DeviceType resolveDeviceType(String categoryId) {
  switch (categoryId.toLowerCase().trim()) {
    case 'ac':
      return DeviceType.ac;
    case 'tv':
    case 'mitv':
      return DeviceType.tv;
    case 'fan':
      return DeviceType.fan;
    case 'smartbox':
    case 'stb':
      return DeviceType.smartBox;
    case 'projector':
      return DeviceType.projector;
    case 'av':
      return DeviceType.avReceiver;
    case 'dvd':
      return DeviceType.dvdPlayer;
    default:
      return DeviceType.generic;
  }
}

class AcState {
  int temperature;
  String mode;
  String fanSpeed;

  bool isOn;
  bool swingOn;

  AcState({
    this.temperature = 24,
    this.mode = 'cool',
    this.fanSpeed = 'auto',
    this.isOn = false,
    this.swingOn = false,
  });
}

class TvState {
  bool isOn;
  bool isMuted;
  int volume;

  TvState({this.isOn = false, this.isMuted = false, this.volume = 20});
}

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

class _RemoteControlPageState extends State<RemoteControlPage>
    with SingleTickerProviderStateMixin {
  final AcState _acState = AcState();
  final TvState _tvState = TvState();
  final SmartTvConnectionService _tvService = SmartTvConnectionService();
  bool _isWifiMode = false;
  IrCodeSet? _codeSet;
  bool _isLoading = true;
  bool _isSending = false;
  late final DeviceType _deviceType;
  late final AnimationController _pulseController;
  final SmartTvConnectionService _smartTvService = SmartTvConnectionService();

  @override
  void initState() {
    super.initState();
    _deviceType = resolveDeviceType(widget.categoryId);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _loadCodeSet();

    _checkConnectionMode();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _smartTvService.disconnect();
    super.dispose();
  }

  Future<void> _loadCodeSet() async {
    debugPrint(
      '[Diagnostic] _loadCodeSet started. categoryId: ${widget.categoryId}, brand: ${widget.brand}',
    );

    if (widget.savedDevice != null) {
      debugPrint('[Diagnostic] Loading from savedDevice snapshot.');
      setState(() {
        _codeSet = IrCodeSet(
          configIndex: widget.savedDevice!.configIndex,
          codes: widget.savedDevice!.codes,
        );
        _isLoading = false;
      });
      return;
    }

    final String searchCategory = (widget.categoryId).toLowerCase().trim();
    final String searchBrand = (widget.brand).toLowerCase().trim();
    final int searchIndex = widget.configIndex;

    try {
      final configs = await IrCodeService.getConfigurationsForBrand(
        categoryId: searchCategory,
        brand: searchBrand,
      );

      setState(() {
        if (configs.isNotEmpty) {
          _codeSet = (searchIndex < configs.length)
              ? configs[searchIndex]
              : configs[0];
          debugPrint(
            '[Diagnostic] Success! Loaded _codeSet with ${_codeSet?.codes.length} codes.',
          );
        } else {
          _codeSet = null;
          debugPrint(
            '[Diagnostic] Warning: No configurations returned from Service.',
          );
        }
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      debugPrint('[Diagnostic] CRITICAL CRASH inside _loadCodeSet: $e');
      debugPrint('$stacktrace');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCommand(String action) async {
    if (_isWifiMode) {
      await _sendWifiCommand(action);
      return;
    }

    if (_codeSet == null) {
      debugPrint('[Remote] Cannot send IR command: codeSet is null.');
      return;
    }

    final IrCode? code = _codeSet!.codes.cast<IrCode?>().firstWhere(
      (c) => c?.action == action,
      orElse: () => null,
    );

    if (code == null) {
      debugPrint('[Remote] No IR code for action: $action');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E1E),
            content: Text(
              'No code for "$action"',
              style: const TextStyle(color: Colors.white70),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    await _pulseController.reverse();
    await _pulseController.forward();

    try {
      await IrService.transmit(
        carrierFrequency: code.frequency,
        pattern: code.pattern,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E1E),
            content: Text(
              'Failed: $e',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }

    setState(() {
      _isSending = false;
      _updateLocalState(action);
    });
  }

  Future<void> _sendWifiCommand(String action) async {
    HapticFeedback.mediumImpact();
    setState(() => _isSending = true);

    await _pulseController.reverse();
    await _pulseController.forward();

    final sent = await _tvService.sendKey(action);

    if (!sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Text(
            'Wi-Fi command failed for "$action"',
            style: const TextStyle(color: Colors.orangeAccent),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    setState(() {
      _isSending = false;
      _updateLocalState(action);
    });
  }

  void _checkConnectionMode() {
    if (widget.savedDevice == null) return;

    final roomName = widget.savedDevice!.roomName;

    if (roomName.contains('(') && roomName.contains(')')) {
      final ipStartIndex = roomName.lastIndexOf('(') + 1;
      final ipEndIndex = roomName.lastIndexOf(')');
      final ipAddress = roomName.substring(ipStartIndex, ipEndIndex).trim();

      setState(() {
        _isWifiMode = true;
      });

      _tvService.connectToTv(ipAddress).then((success) {
        if (mounted) {}
      });

      _tvService.stateStream.listen((state) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  Color get _accentColor => switch (_deviceType) {
    DeviceType.ac => const Color(0xFF3ECFAA),
    DeviceType.tv => const Color(0xFF5B8AF5),
    DeviceType.fan => const Color(0xFF9B87F5),
    DeviceType.generic => const Color(0xFFE0A96D),
    DeviceType.smartBox => const Color(0xFF336FFF),
    DeviceType.projector => const Color(0xFF336FFF),
    DeviceType.avReceiver => const Color(0xFF336FFF),
    DeviceType.dvdPlayer => const Color(0xFF336FFF),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              widget.brand,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              widget.categoryId.toUpperCase(),
              style: TextStyle(
                color: _accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _accentColor,
                strokeWidth: 2,
              ),
            )
          : Stack(
              children: [
                Positioned(
                  top: -60,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _accentColor.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          radius: 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: switch (_deviceType) {
                    DeviceType.ac => _AcRemoteLayout(
                      acState: _acState,
                      accentColor: _accentColor,
                      isSending: _isSending,
                      onCommand: _sendCommand,
                    ),
                    DeviceType.tv => _TvRemoteLayout(
                      tvState: _tvState,
                      accentColor: _accentColor,
                      isSending: _isSending,
                      brand: widget.brand,
                      onCommand: _sendCommand,
                    ),
                    DeviceType.fan => _FanRemoteLayout(
                      accentColor: _accentColor,
                      isSending: _isSending,
                      onCommand: _sendCommand,
                    ),
                    DeviceType.generic => _GenericRemoteLayout(
                      accentColor: _accentColor,
                      onCommand: _sendCommand,
                    ),
                    DeviceType.smartBox => _SmartBoxRemoteLayout(
                      accentColor: _accentColor,
                      onCommand: _sendCommand,
                    ),
                    DeviceType.projector => _ProjectorRemoteLayout(
                      accentColor: _accentColor,
                      onCommand: _sendCommand,
                    ),
                    DeviceType.avReceiver => _AvReceiverRemoteLayout(
                      accentColor: _accentColor,
                      onCommand: _sendCommand,
                    ),
                    DeviceType.dvdPlayer => _DvdPlayerRemoteLayout(
                      accentColor: _accentColor,
                      onCommand: _sendCommand,
                    ),
                  },
                ),
              ],
            ),
    );
  }

  void _updateLocalState(String action) {
    switch (action) {
      case 'power':
        if (_deviceType == DeviceType.ac) {
          _acState.isOn = !_acState.isOn;
        } else {
          _tvState.isOn = !_tvState.isOn;
        }
      case 'temp_up':
        if (_acState.temperature < 30) _acState.temperature++;
      case 'temp_down':
        if (_acState.temperature > 16) _acState.temperature--;
    }
  }
}

class _AcRemoteLayout extends StatelessWidget {
  final AcState acState;
  final Color accentColor;
  final bool isSending;
  final Future<void> Function(String) onCommand;

  const _AcRemoteLayout({
    required this.acState,
    required this.accentColor,
    required this.isSending,
    required this.onCommand,
  });

  Color _modeColor(String mode) => switch (mode) {
    'cool' => const Color(0xFF42A5F5),
    'heat' => const Color(0xFFEF6C00),
    'fan' => const Color(0xFF26A69A),
    'dry' => const Color(0xFF7E57C2),
    _ => Colors.grey,
  };

  IconData _modeIcon(String mode) => switch (mode) {
    'cool' => Icons.ac_unit_rounded,
    'heat' => Icons.local_fire_department_rounded,
    'fan' => Icons.air_rounded,
    'dry' => Icons.water_drop_rounded,
    _ => Icons.auto_mode_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: acState.isOn
                    ? accentColor.withOpacity(0.35)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusPill(
                      label: acState.isOn ? 'ON' : 'OFF',
                      color: acState.isOn ? accentColor : Colors.grey,
                    ),
                    _StatusPill(
                      label: acState.mode.toUpperCase(),
                      color: _modeColor(acState.mode),
                      icon: _modeIcon(acState.mode),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${acState.temperature}',
                      style: TextStyle(
                        color: acState.isOn ? Colors.white : Colors.white38,
                        fontSize: 80,
                        fontWeight: FontWeight.w200,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '°C',
                        style: TextStyle(
                          color: acState.isOn ? accentColor : Colors.white24,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.air_rounded,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fan: ${acState.fanSpeed.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.swap_vert_rounded,
                      color: acState.swingOn ? accentColor : Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Swing: ${acState.swingOn ? "ON" : "OFF"}',
                      style: TextStyle(
                        color: acState.swingOn ? accentColor : Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              _BigPowerButton(
                isOn: acState.isOn,
                accentColor: accentColor,
                isSending: isSending,
                onTap: () => onCommand('power'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _TempButton(
                      icon: Icons.keyboard_arrow_up_rounded,
                      label: 'Temp +',
                      accentColor: accentColor,
                      onTap: () => onCommand('temp_up'),
                    ),
                    const SizedBox(height: 10),
                    _TempButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      label: 'Temp −',
                      accentColor: accentColor,
                      onTap: () => onCommand('temp_down'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const _SectionLabel('Mode'),
          const SizedBox(height: 10),
          Row(
            children: [
              _ModeButton(
                icon: Icons.ac_unit_rounded,
                label: 'Cool',
                isActive: acState.mode == 'cool',
                activeColor: const Color(0xFF42A5F5),
                onTap: () => onCommand('cool'),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                icon: Icons.local_fire_department_rounded,
                label: 'Heat',
                isActive: acState.mode == 'heat',
                activeColor: const Color(0xFFEF6C00),
                onTap: () => onCommand('heat'),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                icon: Icons.air_rounded,
                label: 'Fan',
                isActive: acState.mode == 'fan',
                activeColor: const Color(0xFF26A69A),
                onTap: () => onCommand('fan'),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                icon: Icons.water_drop_rounded,
                label: 'Dry',
                isActive: acState.mode == 'dry',
                activeColor: const Color(0xFF7E57C2),
                onTap: () => onCommand('dry'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const _SectionLabel('Fan Speed'),
          const SizedBox(height: 10),
          Row(
            children: [
              _FanSpeedButton(
                label: 'Auto',
                isActive: acState.fanSpeed == 'auto',
                accentColor: accentColor,
                onTap: () => onCommand('fan_auto'),
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                label: 'Low',
                isActive: acState.fanSpeed == 'low',
                accentColor: accentColor,
                onTap: () => onCommand('fan_low'),
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                label: 'Mid',
                isActive: acState.fanSpeed == 'mid',
                accentColor: accentColor,
                onTap: () => onCommand('fan_mid'),
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                label: 'High',
                isActive: acState.fanSpeed == 'high',
                accentColor: accentColor,
                onTap: () => onCommand('fan_high'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => onCommand('swing'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: acState.swingOn
                    ? accentColor.withOpacity(0.15)
                    : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: acState.swingOn
                      ? accentColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_vert_rounded,
                    color: acState.swingOn ? accentColor : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Swing ${acState.swingOn ? "ON" : "OFF"}',
                    style: TextStyle(
                      color: acState.swingOn ? accentColor : Colors.white38,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TvRemoteLayout extends StatelessWidget {
  final TvState tvState;
  final Color accentColor;
  final bool isSending;
  final String brand;
  final Future<void> Function(String) onCommand;

  const _TvRemoteLayout({
    required this.tvState,
    required this.accentColor,
    required this.isSending,
    required this.brand,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusPill(
                  label: tvState.isOn ? 'ON' : 'OFF',
                  color: tvState.isOn ? accentColor : Colors.grey,
                ),
                _StatusPill(
                  label: tvState.isMuted ? 'MUTED' : 'Vol ${tvState.volume}',
                  color: tvState.isMuted ? Colors.orange : Colors.white38,
                  icon: tvState.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.power_settings_new_rounded,
                label: 'Power',
                color: tvState.isOn
                    ? const Color(0xFFE53935)
                    : const Color(0xFF2A2A2A),
                size: 60,
                onTap: () => onCommand('power'),
              ),
              _RoundButton(
                icon: Icons.volume_off_rounded,
                label: 'Mute',
                color: tvState.isMuted
                    ? Colors.orange
                    : const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('mute'),
              ),
              _RoundButton(
                icon: Icons.input_rounded,
                label: 'Input',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('input'),
              ),
              _RoundButton(
                icon: Icons.menu_rounded,
                label: 'Menu',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('menu'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _DPad(accentColor: accentColor, onCommand: onCommand),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const _SectionLabel('Volume'),
                    const SizedBox(height: 8),
                    _RoundButton(
                      icon: Icons.add_rounded,
                      label: 'Vol +',
                      color: const Color(0xFF1E1E1E),
                      size: 56,
                      onTap: () => onCommand('volume_up'),
                    ),
                    const SizedBox(height: 8),
                    _RoundButton(
                      icon: Icons.remove_rounded,
                      label: 'Vol −',
                      color: const Color(0xFF1E1E1E),
                      size: 56,
                      onTap: () => onCommand('volume_down'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    const _SectionLabel('Channel'),
                    const SizedBox(height: 8),
                    _RoundButton(
                      icon: Icons.keyboard_arrow_up_rounded,
                      label: 'Ch +',
                      color: const Color(0xFF1E1E1E),
                      size: 56,
                      onTap: () => onCommand('channel_up'),
                    ),
                    const SizedBox(height: 8),
                    _RoundButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      label: 'Ch −',
                      color: const Color(0xFF1E1E1E),
                      size: 56,
                      onTap: () => onCommand('channel_down'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const _SectionLabel('Playback'),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.skip_previous_rounded,
                label: 'Prev',
                color: const Color(0xFF1E1E1E),
                size: 50,
                onTap: () => onCommand('prev'),
              ),
              _RoundButton(
                icon: Icons.pause_rounded,
                label: 'Play',
                color: accentColor.withOpacity(0.2),
                size: 60,
                onTap: () => onCommand('play_pause'),
              ),
              _RoundButton(
                icon: Icons.skip_next_rounded,
                label: 'Next',
                color: const Color(0xFF1E1E1E),
                size: 50,
                onTap: () => onCommand('next'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.home_rounded,
                label: 'Home',
                color: const Color(0xFF1E1E1E),
                size: 50,
                onTap: () => onCommand('home'),
              ),
              _RoundButton(
                icon: Icons.arrow_back_rounded,
                label: 'Back',
                color: const Color(0xFF1E1E1E),
                size: 50,
                onTap: () => onCommand('back'),
              ),
              _RoundButton(
                icon: Icons.smart_display_rounded,
                label: 'Smart',
                color: accentColor.withOpacity(0.18),
                size: 50,
                onTap: () => onCommand('smart'),
              ),
              _RoundButton(
                icon: Icons.settings_rounded,
                label: 'Settings',
                color: const Color(0xFF1E1E1E),
                size: 50,
                onTap: () => onCommand('settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartBoxRemoteLayout extends StatelessWidget {
  final Color accentColor;
  final Future<void> Function(String) onCommand;

  const _SmartBoxRemoteLayout({
    required this.accentColor,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.power_settings_new_rounded,
                label: 'Power',
                color: const Color(0xFFE53935),
                size: 56,
                onTap: () => onCommand('power'),
              ),
              _RoundButton(
                icon: Icons.search_rounded,
                label: 'Search',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('search'),
              ),
              _RoundButton(
                icon: Icons.mic_rounded,
                label: 'Voice',
                color: accentColor.withOpacity(0.2),
                size: 52,
                onTap: () => onCommand('voice'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _DPad(accentColor: accentColor, onCommand: onCommand),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.arrow_back_rounded,
                label: 'Back',
                color: const Color(0xFF1E1E1E),
                size: 54,
                onTap: () => onCommand('back'),
              ),
              _RoundButton(
                icon: Icons.home_rounded,
                label: 'Home',
                color: const Color(0xFF1E1E1E),
                size: 58,
                onTap: () => onCommand('home'),
              ),
              _RoundButton(
                icon: Icons.menu_rounded,
                label: 'Menu',
                color: const Color(0xFF1E1E1E),
                size: 54,
                onTap: () => onCommand('menu'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Volume Control'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.remove_rounded,
                  label: 'Vol −',
                  onTap: () => onCommand('volume_down'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.add_rounded,
                  label: 'Vol +',
                  onTap: () => onCommand('volume_up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectorRemoteLayout extends StatelessWidget {
  final Color accentColor;
  final Future<void> Function(String) onCommand;

  const _ProjectorRemoteLayout({
    required this.accentColor,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.power_settings_new_rounded,
                label: 'Power',
                color: const Color(0xFFE53935),
                size: 56,
                onTap: () => onCommand('power'),
              ),
              _RoundButton(
                icon: Icons.input_rounded,
                label: 'Source',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('input'),
              ),
              _RoundButton(
                icon: Icons.check_box_outline_blank_rounded,
                label: 'Blank',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('blank'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DPad(accentColor: accentColor, onCommand: onCommand),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.arrow_back_rounded,
                label: 'Back',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('back'),
              ),
              _RoundButton(
                icon: Icons.menu_rounded,
                label: 'Menu',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('menu'),
              ),
              _RoundButton(
                icon: Icons.architecture_rounded,
                label: 'Keystone',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('keystone'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('Focus & Zoom adjustments'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.zoom_in_rounded,
                  label: 'Zoom In',
                  onTap: () => onCommand('zoom_in'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.zoom_out_rounded,
                  label: 'Zoom Out',
                  onTap: () => onCommand('zoom_out'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.blur_on_rounded,
                  label: 'Focus +',
                  onTap: () => onCommand('focus_forward'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.blur_off_rounded,
                  label: 'Focus −',
                  onTap: () => onCommand('focus_backward'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvReceiverRemoteLayout extends StatelessWidget {
  final Color accentColor;
  final Future<void> Function(String) onCommand;

  const _AvReceiverRemoteLayout({
    required this.accentColor,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.power_settings_new_rounded,
                label: 'Power',
                color: const Color(0xFFE53935),
                size: 56,
                onTap: () => onCommand('power'),
              ),
              _RoundButton(
                icon: Icons.volume_off_rounded,
                label: 'Mute',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('mute'),
              ),
              _RoundButton(
                icon: Icons.settings_input_hdmi_rounded,
                label: 'Input',
                color: const Color(0xFF1E1E1E),
                size: 52,
                onTap: () => onCommand('input_cycle'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Input Selectors'),
          const SizedBox(height: 10),
          Row(
            children: [
              _FanSpeedButton(
                label: 'HDMI 1',
                isActive: false,
                accentColor: accentColor,
                onTap: () => onCommand('hdmi1'),
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                label: 'HDMI 2',
                isActive: false,
                accentColor: accentColor,
                onTap: () => onCommand('hdmi2'),
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                label: 'Optical',
                isActive: false,
                accentColor: accentColor,
                onTap: () => onCommand('optical'),
              ),
              const SizedBox(width: 8),
              _FanSpeedButton(
                label: 'Bluetooth',
                isActive: false,
                accentColor: accentColor,
                onTap: () => onCommand('bluetooth'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DPad(accentColor: accentColor, onCommand: onCommand),
          const SizedBox(height: 24),
          const _SectionLabel('Master Volume'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.volume_down_rounded,
                  label: 'Volume Down',
                  onTap: () => onCommand('volume_down'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.volume_up_rounded,
                  label: 'Volume Up',
                  onTap: () => onCommand('volume_up'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Sound Field Profile'),
          const SizedBox(height: 10),
          Row(
            children: [
              _ModeButton(
                icon: Icons.movie_filter_rounded,
                label: 'Movie',
                isActive: false,
                activeColor: accentColor,
                onTap: () => onCommand('mode_movie'),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                icon: Icons.music_note_rounded,
                label: 'Music',
                isActive: false,
                activeColor: accentColor,
                onTap: () => onCommand('mode_music'),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                icon: Icons.surround_sound_rounded,
                label: 'Surround',
                isActive: false,
                activeColor: accentColor,
                onTap: () => onCommand('mode_surround'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DvdPlayerRemoteLayout extends StatelessWidget {
  final Color accentColor;
  final Future<void> Function(String) onCommand;

  const _DvdPlayerRemoteLayout({
    required this.accentColor,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.power_settings_new_rounded,
                label: 'Power',
                color: const Color(0xFFE53935),
                size: 54,
                onTap: () => onCommand('power'),
              ),
              _RoundButton(
                icon: Icons.eject_rounded,
                label: 'Eject',
                color: const Color(0xFF1E1E1E),
                size: 50,
                onTap: () => onCommand('eject'),
              ),
              _RoundButton(
                icon: Icons.subtitles_rounded,
                label: 'Subtitle',
                color: const Color(0xFF1E1E1E),
                size: 50,
                onTap: () => onCommand('subtitle'),
              ),
              _RoundButton(
                icon: Icons.audiotrack_rounded,
                label: 'Audio',
                color: const Color(0xFF1E1E1E),
                size: 50,
                onTap: () => onCommand('audio'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DPad(accentColor: accentColor, onCommand: onCommand),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.arrow_back_rounded,
                label: 'Return',
                color: const Color(0xFF1E1E1E),
                size: 48,
                onTap: () => onCommand('back'),
              ),
              _RoundButton(
                icon: Icons.menu_open_rounded,
                label: 'Title Menu',
                color: const Color(0xFF1E1E1E),
                size: 48,
                onTap: () => onCommand('title_menu'),
              ),
              _RoundButton(
                icon: Icons.menu_rounded,
                label: 'DVD Menu',
                color: const Color(0xFF1E1E1E),
                size: 48,
                onTap: () => onCommand('menu'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _SectionLabel('Deck Controls'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.fast_rewind_rounded,
                label: 'Rewind',
                color: const Color(0xFF1E1E1E),
                size: 48,
                onTap: () => onCommand('rewind'),
              ),
              _RoundButton(
                icon: Icons.play_arrow_rounded,
                label: 'Play',
                color: accentColor.withOpacity(0.2),
                size: 58,
                onTap: () => onCommand('play'),
              ),
              _RoundButton(
                icon: Icons.pause_rounded,
                label: 'Pause',
                color: const Color(0xFF1E1E1E),
                size: 48,
                onTap: () => onCommand('pause'),
              ),
              _RoundButton(
                icon: Icons.stop_rounded,
                label: 'Stop',
                color: const Color(0xFF1E1E1E),
                size: 48,
                onTap: () => onCommand('stop'),
              ),
              _RoundButton(
                icon: Icons.fast_forward_rounded,
                label: 'Fwd',
                color: const Color(0xFF1E1E1E),
                size: 48,
                onTap: () => onCommand('fast_forward'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FanRemoteLayout extends StatelessWidget {
  final Color accentColor;
  final bool isSending;
  final Future<void> Function(String) onCommand;

  const _FanRemoteLayout({
    required this.accentColor,
    required this.isSending,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        children: [
          Center(
            child: Row(
              children: [
                _BigPowerButton(
                  isOn: false,
                  accentColor: accentColor,
                  isSending: isSending,
                  onTap: () => onCommand('power'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _SectionLabel('Fan Speed'),
          const SizedBox(height: 12),
          Row(
            children: [
              _ModeButton(
                icon: Icons.air_rounded,
                label: 'Low',
                isActive: false,
                activeColor: accentColor,
                onTap: () => onCommand('speed_low'),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                icon: Icons.air_rounded,
                label: 'Mid',
                isActive: false,
                activeColor: accentColor,
                onTap: () => onCommand('speed_mid'),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                icon: Icons.air_rounded,
                label: 'High',
                isActive: false,
                activeColor: accentColor,
                onTap: () => onCommand('speed_high'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.swap_vert_rounded,
                  label: 'Swing',
                  onTap: () => onCommand('swing'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TvStyleButton(
                  icon: Icons.timer_rounded,
                  label: 'Timer',
                  onTap: () => onCommand('timer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenericRemoteLayout extends StatelessWidget {
  final Color accentColor;
  final Future<void> Function(String) onCommand;

  const _GenericRemoteLayout({
    required this.accentColor,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BigPowerButton(
                isOn: false,
                accentColor: accentColor,
                isSending: false,
                onTap: () => onCommand('power'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Basic remote',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  final Color accentColor;
  final Future<void> Function(String) onCommand;

  const _DPad({required this.accentColor, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141414),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          Positioned(
            top: 10,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_up_rounded,
              onTap: () => onCommand('up'),
              accentColor: accentColor,
            ),
          ),
          Positioned(
            bottom: 10,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: () => onCommand('down'),
              accentColor: accentColor,
            ),
          ),
          Positioned(
            left: 10,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_left_rounded,
              onTap: () => onCommand('left'),
              accentColor: accentColor,
            ),
          ),
          Positioned(
            right: 10,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_right_rounded,
              onTap: () => onCommand('right'),
              accentColor: accentColor,
            ),
          ),
          GestureDetector(
            onTap: () => onCommand('enter'),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  const _DPadButton({
    required this.icon,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: accentColor.withOpacity(0.15),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusPill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigPowerButton extends StatelessWidget {
  final bool isOn;
  final Color accentColor;
  final bool isSending;
  final VoidCallback onTap;

  const _BigPowerButton({
    required this.isOn,
    required this.accentColor,
    required this.isSending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 122,
          decoration: BoxDecoration(
            color: isOn
                ? accentColor.withOpacity(0.15)
                : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOn
                  ? accentColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Center(
            child: isSending
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    Icons.power_settings_new_rounded,
                    color: isOn ? accentColor : Colors.white38,
                    size: 38,
                  ),
          ),
        ),
      ),
    );
  }
}

class _TempButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _TempButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Icon(icon, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.15)
                : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? activeColor.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : Colors.white38,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FanSpeedButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _FanSpeedButton({
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withOpacity(0.15)
                : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? accentColor.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? accentColor : Colors.white60,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _TvStyleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TvStyleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
