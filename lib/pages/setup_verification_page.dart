import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_control/models/saved_device.dart';
import 'package:remote_control/pages/wifi_discovery_widget.dart';
import 'package:remote_control/services/device_storage_service.dart';
import 'package:remote_control/services/ir_code.dart';
import 'package:remote_control/services/ir_code_set.dart';
import '../services/ir_service.dart';

// ─── Design tokens ───────────────────────────────────────────────
const _bg = Color(0xFF0A0A0F); // near-black with blue tint
const _surface = Color(0xFF13131A); // card surface
const _surfaceAlt = Color(0xFF1C1C27); // elevated surface
const _accent = Color(0xFF6C63FF); // violet-blue — primary accent
const _accentDim = Color(0x336C63FF); // accent at 20% opacity
const _amber = Color(0xFFFFB547); // IR/power warm tone
const _amberDim = Color(0x33FFB547); // amber at 20% opacity
const _green = Color(0xFF3ECF8E); // confirmed / success
const _greenDim = Color(0x333ECF8E);
const _textPrimary = Color(0xFFF0F0F8);
const _textSecondary = Color(0xFF8888AA);
const _border = Color(0xFF2A2A3A);
// ─────────────────────────────────────────────────────────────────

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

class _SetupVerificationPageState extends ConsumerState<SetupVerificationPage>
    with TickerProviderStateMixin {
  List<IrCodeSet> _configurations = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSending = false;
  bool _deviceResponded = false;

  // Pulse animation for the power button ring
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadConfigurations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
    });
  }

  Future<void> _sendPowerSignal() async {
    debugPrint("Tap");
    if (_configurations.isEmpty || _isSending) return;
    final config = _configurations[_currentIndex];
    final powerCode = config.codes.firstWhere(
      (c) => c.action == 'power',
      orElse: () => config.codes.first,
    );

    // ── HAPTIC: Distinct deep pulse indicating raw outbound signal transmission
    HapticFeedback.heavyImpact();
    setState(() => _isSending = true);

    try {
      await IrService.transmit(
        carrierFrequency: powerCode.frequency,
        pattern: powerCode.pattern,
      );
    } catch (e) {
      if (mounted) {
        // ── HAPTIC: Quick consecutive light errors if pipeline misfires
        HapticFeedback.lightImpact();
        _showErrorSnack('Signal failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _nextConfiguration() {
    if (_currentIndex < _configurations.length - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex++;
        _deviceResponded = false;
      });
    }
  }

  void _onDeviceResponded() async {
    HapticFeedback.heavyImpact();

    final roomName = await showDialog<String>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final controller = TextEditingController();
        return Dialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _accentDim,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.label_rounded,
                        color: _accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Name this device',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: _textPrimary, fontSize: 15),
                  cursorColor: _accent,
                  decoration: InputDecoration(
                    hintText: 'e.g. Living Room, Bedroom',
                    hintStyle: const TextStyle(color: _textSecondary),
                    filled: true,
                    fillColor: _surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text.trim()),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (roomName == null || roomName.isEmpty) return;

    final List<IrCode> configCodes = _configurations.isNotEmpty
        ? List<IrCode>.from(_configurations[_currentIndex].codes)
        : <IrCode>[];

    final device = SavedDevice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: widget.categoryId,
      brand: widget.brandName,
      roomName: roomName,
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

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: _textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = _currentIndex < (_configurations.length - 1);
    final canProceed = _deviceResponded;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _textPrimary,
              size: 18,
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              widget.brandName.toUpperCase(),
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            Text(
              widget.categoryId.toUpperCase(),
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Step indicator ──
                  _StepIndicator(
                    current: _currentIndex + 1,
                    total: _configurations.length,
                  ),

                  const SizedBox(height: 28),

                  // ── Instruction card ──
                  _InstructionCard(categoryId: widget.categoryId),

                  const SizedBox(height: 16),

                  WifiDiscoveryWidget(
                    onDeviceSelected: (BonsoirService selectedService) {
                      debugPrint(
                        "Paired targeted item: ${selectedService.name}",
                      );
                      // Trigger your response confirmation logic!
                      setState(() {
                        _deviceResponded = true;
                      });
                    },
                  ),
                  const Spacer(),

                  // ── Power button with pulse ring ──
                  Center(child: _buildPowerButton(hasNext)),

                  const SizedBox(height: 40),

                  // ── Response confirmation card ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _deviceResponded
                        ? _ConfirmedBadge(key: const ValueKey('confirmed'))
                        : // Inside the build method body under _ResponseCard parameters:
                          _ResponseCard(
                            key: const ValueKey('response'),
                            hasNext: hasNext,
                            onYes: () {
                              HapticFeedback.mediumImpact().then((_) {
                                Future.delayed(
                                  const Duration(milliseconds: 80),
                                  () {
                                    HapticFeedback.mediumImpact();
                                  },
                                );
                              });
                              setState(() => _deviceResponded = true);
                            },
                            onNo: () {
                              // ── HAPTIC: Single light feedback step
                              HapticFeedback.lightImpact();
                              if (hasNext) {
                                _nextConfiguration();
                              } else {
                                // Warning vibration
                                HapticFeedback.vibrate();
                                _showErrorSnack(
                                  'No more configs. Point directly at the device.',
                                );
                              }
                            },
                          ),
                  ),

                  const SizedBox(height: 20),

                  // ── Save button ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: canProceed
                        ? _SaveButton(
                            key: const ValueKey('save'),
                            onTap: _onDeviceResponded,
                          )
                        : const SizedBox(key: ValueKey('hidden'), height: 56),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildPowerButton(bool hasNext) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated pulse rings + power button
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) {
            return SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Transform.scale(
                    scale: _isSending ? 1.0 + (_pulseAnim.value * 0.25) : 1.0,
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSending
                              ? _amber.withValues(alpha: 0.25)
                              : _amberDim,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Middle ring
                  Transform.scale(
                    scale: _isSending ? 1.0 + (_pulseAnim.value * 0.12) : 1.0,
                    child: Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSending
                              ? _amber.withValues(alpha: 0.35)
                              : _amberDim.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Core button
                  GestureDetector(
                    onTap: _sendPowerSignal,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSending
                            ? _amber.withValues(alpha: 0.15)
                            : _amberDim,
                        border: Border.all(
                          color: _isSending
                              ? _amber
                              : _amber.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: _isSending
                            ? [
                                BoxShadow(
                                  color: _amber.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ]
                            : [],
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  color: _amber,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.power_settings_new_rounded,
                              color: _amber,
                              size: 38,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Next config arrow
        if (hasNext) ...[
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _nextConfiguration,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: _textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _accentDim,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Config $current of $total',
            style: const TextStyle(
              color: _accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: _surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(_accent),
              minHeight: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String categoryId;
  const _InstructionCard({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _amberDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sensors_rounded, color: _amber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Point at your device',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Press the power button and see if your '
                  '${categoryId.toUpperCase()} responds.',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final bool hasNext;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _ResponseCard({
    super.key,
    required this.hasNext,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Did your device respond?',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ResponseButton(
                  label: 'Yes, it worked',
                  icon: Icons.check_rounded,
                  color: _green,
                  dimColor: _greenDim,
                  onTap: onYes,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResponseButton(
                  label: hasNext ? 'Try next' : 'Not working',
                  icon: hasNext
                      ? Icons.arrow_forward_rounded
                      : Icons.close_rounded,
                  color: _textSecondary,
                  dimColor: _surfaceAlt,
                  onTap: onNo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color dimColor;
  final VoidCallback onTap;

  const _ResponseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.dimColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: dimColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmedBadge extends StatelessWidget {
  const _ConfirmedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _greenDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: _green, size: 20),
          SizedBox(width: 10),
          Text(
            'Device confirmed — tap Save to continue',
            style: TextStyle(
              color: _green,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF9B6DFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Save this device',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
