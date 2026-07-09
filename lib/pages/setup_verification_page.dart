import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_control/models/saved_device.dart';
import 'package:remote_control/services/device_storage_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  Future<void> _loadConfigurations() async {
    setState(() => _isLoading = true);

    final configs = await IrCodeService.getConfigurationsForBrand(
      categoryId: widget.categoryId,
      brand: widget.brandName,
    );

    setState(() {
      _configurations = configs;
      _isLoading = false;
      _statusText =
          'Point the remote at ${widget.categoryId.toUpperCase()} and tap the button.\n'
          'Make sure ${widget.categoryId.toUpperCase()} responds.';
    });
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
    HapticFeedback.heavyImpact();

    // Ask for room name
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

    final config = _configurations[_currentIndex];
    final device = SavedDevice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: widget.categoryId,
      brand: widget.brandName,
      roomName: roomName,
      configIndex: _currentIndex,
      codes: config.codes,
    );

    await DeviceStorageService.saveDevice(device);

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      '/remote-control',
      arguments: {
        'categoryId': widget.categoryId,
        'brand': widget.brandName,
        'configIndex': _currentIndex,
        'savedDevice': device, // pass full device so no re-fetch needed
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = _currentIndex < (_configurations.length - 1);
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
                  const SizedBox(height: 48),

                  // ── Instruction text ──
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

                  // ── Config counter (blue, matches screenshot) ──
                  if (_configurations.isNotEmpty)
                    Text(
                      configLabel,
                      style: const TextStyle(
                        color: Color(0xFF4D9EFF),
                        fontSize: 16,
                      ),
                    ),

                  const Spacer(),

                  // ── Buttons row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Power button (green circle)
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

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _onDeviceResponded,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1E1E),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Device responded — done',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }
}
