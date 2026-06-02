import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:remote_control/models/saved_device.dart';
import 'package:remote_control/services/device_storage_service.dart';
import 'package:remote_control/services/ir_code.dart';
import 'package:remote_control/services/ir_code_set.dart';
import '../services/ir_service.dart';

class SetupVerificationPage extends ConsumerStatefulWidget {
  final String categoryId;
  final String brandName;

  const SetupVerificationPage({
    super.key,
    required this.categoryId,
    required this.brandName,
  });

  @override
  ConsumerState<SetupVerificationPage> createState() =>
      _SetupVerificationPageState();
}

class _SetupVerificationPageState extends ConsumerState<SetupVerificationPage> {
  List<IrCodeSet> _configurations = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSending = false;
  String _statusText = '';

  bool _isScanningNetwork = false;
  String? _discoveredDeviceIp;

  @override
  void initState() {
    super.initState();
    _initializeSetup();
  }

  Future<void> _initializeSetup() async {
    setState(() => _isLoading = true);

    try {
      final configs = await IrCodeService.getConfigurationsForBrand(
        categoryId: widget.categoryId,
        brand: widget.brandName,
      );
      _configurations = configs;
    } catch (e) {
      debugPrint('[SetupVerification] Error loading IR configurations: $e');
    }

    if (widget.categoryId == 'tv' || widget.categoryId == 'smartbox') {
      _updateStatusText();
      setState(() => _isLoading = false);

      await _performNetworkDiscovery();
    } else {
      setState(() => _isLoading = false);
      _updateStatusText();
    }
  }

  void _updateStatusText() {
    if (!mounted) return;
    setState(() {
      if (_discoveredDeviceIp != null) {
        _statusText =
            'Smart TV discovered over Wi-Fi!\n'
            'You can save and connect directly via your local network layout.';
      } else if (_configurations.isNotEmpty) {
        _statusText =
            'Point the remote at your ${widget.categoryId.toUpperCase()} and tap the button.\n'
            'Make sure your equipment responds.';
      } else {
        _statusText =
            'No remote configurations or network devices found for '
            '${widget.brandName} ${widget.categoryId.toUpperCase()}.';
      }
    });
  }

  Future<void> _performNetworkDiscovery() async {
    setState(() {
      _isScanningNetwork = true;
    });

    try {
      final info = NetworkInfo();
      final localIp = await info.getWifiIP();

      if (localIp != null && localIp.contains('.')) {
        final subnet = localIp.substring(0, localIp.lastIndexOf('.') + 1);
        final targetPorts = [8001, 8002, 8060];

        for (int i = 1; i < 255; i++) {
          final candidateIp = '$subnet$i';
          if (candidateIp == localIp) continue;

          for (final port in targetPorts) {
            try {
              final socket = await Socket.connect(
                candidateIp,
                port,
                timeout: const Duration(milliseconds: 100),
              );
              socket.destroy();

              if (mounted) {
                setState(() {
                  _discoveredDeviceIp = candidateIp;
                });
              }
              break;
            } catch (_) {}
          }
          if (_discoveredDeviceIp != null) break;
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isScanningNetwork = false);
        _updateStatusText();
      }
    }
  }

  Future<void> _sendPowerSignal() async {
    if (_configurations.isEmpty || _isSending) return;

    final config = _configurations[_currentIndex];
    final powerCode = config.codes.firstWhere(
      (c) => c.action == 'power',
      orElse: () => config.codes.first,
    );

    HapticFeedback.mediumImpact();
    setState(() => _isSending = true);

    try {
      await IrService.transmit(
        carrierFrequency: powerCode.frequency,
        pattern: powerCode.pattern,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E1E),
            content: Text(
              'Failed to send signal: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _nextConfiguration() {
    if (_currentIndex < _configurations.length - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex++);
    }
  }

  void _onDeviceResponded() async {
    if (_configurations.isEmpty && _discoveredDeviceIp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot save device: No IR code or Wi-Fi targets verified.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    final roomName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Name this device',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. Bedroom, Living Room',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (roomName == null || roomName.isEmpty) return;

    final List<IrCode> configCodes = _configurations.isNotEmpty
        ? _configurations[_currentIndex].codes.cast<IrCode>()
        : <IrCode>[];

    final device = SavedDevice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: widget.categoryId,
      brand: widget.brandName,
      roomName: _discoveredDeviceIp != null
          ? '$roomName ($_discoveredDeviceIp)'
          : roomName,
      configIndex: _currentIndex,
      codes: configCodes,
    );

    await DeviceStorageService.saveDevice(device);

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      '/remote-control',
      arguments: {
        'categoryId': widget.categoryId,
        'brand': widget.brandName,
        'configIndex': _currentIndex,
        'savedDevice': device,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = _currentIndex < (_configurations.length - 1);
    final isWifiReady = _discoveredDeviceIp != null;
    final canProceed = _configurations.isNotEmpty || isWifiReady;

    final configLabel = _configurations.isEmpty
        ? ''
        : 'Checking available configurations '
              '${_currentIndex + 1}/${_configurations.length}';

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
          widget.categoryId.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  if (widget.categoryId == 'tv' ||
                      widget.categoryId == 'smartbox')
                    _buildNetworkStatusBanner(),

                  const SizedBox(height: 24),

                  Text(
                    _statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_configurations.isNotEmpty) ...[
                    Text(
                      configLabel,
                      style: const TextStyle(
                        color: Color(0xFF4D9EFF),
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _sendPowerSignal,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isSending
                                  ? const Color(0xFF2E7D52)
                                  : const Color(0xFF3DAA72),
                            ),
                            child: _isSending
                                ? const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.power_settings_new_rounded,
                                    color: Colors.white,
                                    size: 42,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        if (hasNext)
                          GestureDetector(
                            onTap: _nextConfiguration,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2A2A2A),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white54,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    const Spacer(),
                    Center(
                      child: Text(
                        _isScanningNetwork
                            ? 'Scanning network for smart features...'
                            : 'No IR configuration profile available.',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  if (canProceed)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _onDeviceResponded,
                        style: FilledButton.styleFrom(
                          backgroundColor: isWifiReady
                              ? const Color(0xFF3DAA72)
                              : const Color(0xFF1E1E1E),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isWifiReady
                              ? 'Connect via Wi-Fi Mode'
                              : 'Device responded — done',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildNetworkStatusBanner() {
    final hasFoundDevice = _discoveredDeviceIp != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasFoundDevice
            ? const Color(0xFF142B20)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFoundDevice
              ? const Color(0xFF3DAA72).withValues(alpha: 0.3)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFoundDevice
                ? Icons.wifi_find_rounded
                : Icons.wifi_tethering_rounded,
            color: hasFoundDevice ? const Color(0xFF3DAA72) : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFoundDevice
                      ? 'Smart TV Detected Online!'
                      : 'Checking Wi-Fi Network...',
                  style: TextStyle(
                    color: hasFoundDevice
                        ? const Color(0xFF3DAA72)
                        : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasFoundDevice
                      ? 'Found at IP $_discoveredDeviceIp. Smart control active.'
                      : (_isScanningNetwork
                            ? 'Searching local network bands...'
                            : 'IR Only Mode active. Connect to same Wi-Fi.'),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_isScanningNetwork)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}
