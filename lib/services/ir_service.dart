import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IrService {
  IrService._();

  static const _channel = MethodChannel(
    'com.example.remote_control/ir_blaster',
  );

  static bool? _hasBlaster;

  static Future<bool> checkIrBlaster() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasIrEmitter');
      _hasBlaster = result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[IrService] hasIrEmitter failed: ${e.message}');
      _hasBlaster = false;
    } on MissingPluginException {
      // Running on emulator or iOS — IR never available
      debugPrint('[IrService] Platform channel not found (emulator/iOS)');
      _hasBlaster = false;
    }
    return _hasBlaster!;
  }

  static bool get hasBlaster => _hasBlaster ?? false;

  static Future<List<IrFrequencyRange>> getSupportedFrequencies() async {
    try {
      final raw = await _channel.invokeMethod<List>('getCarrierFrequencies');
      if (raw == null) return [];
      return raw.map((e) {
        final map = Map<String, int>.from(e as Map);
        return IrFrequencyRange(
          minFrequency: map['minFrequency'] ?? 0,
          maxFrequency: map['maxFrequency'] ?? 0,
        );
      }).toList();
    } on PlatformException catch (e) {
      debugPrint('[IrService] getCarrierFrequencies failed: ${e.message}');
      return [];
    }
  }

  static Future<void> transmit({
    required int carrierFrequency,
    required List<int> pattern,
  }) async {
    if (_hasBlaster == false) {
      throw IrException(
        IrErrorCode.noHardware,
        'No IR blaster detected on this device.',
      );
    }
    if (pattern.isEmpty) {
      throw IrException(IrErrorCode.invalidPattern, 'IR pattern is empty.');
    }

    final normalized = pattern.length % 2 == 0
        ? pattern.sublist(0, pattern.length - 1)
        : pattern;

    debugPrint(
      '[IrService] Transmitting ${normalized.length} pulses at ${carrierFrequency}Hz',
    );

    try {
      await _channel.invokeMethod<void>('transmit', {
        'frequency': carrierFrequency,
        'pattern': normalized,
      });
    } on PlatformException catch (e) {
      debugPrint('[IrService] transmit failed: ${e.code} — ${e.message}');
      throw IrException(
        _mapErrorCode(e.code),
        e.message ?? 'Unknown transmit error',
      );
    }
  }

  static IrErrorCode _mapErrorCode(String platformCode) {
    switch (platformCode) {
      case 'NO_IR':
        return IrErrorCode.noHardware;
      case 'BAD_ARGS':
        return IrErrorCode.invalidPattern;
      case 'TRANSMIT_FAILED':
        return IrErrorCode.transmitFailed;
      default:
        return IrErrorCode.unknown;
    }
  }
}

enum IrErrorCode { noHardware, invalidPattern, transmitFailed, unknown }

class IrException implements Exception {
  final IrErrorCode code;
  final String message;

  const IrException(this.code, this.message);

  @override
  String toString() => '[IrException:${code.name}] $message';
}

class IrFrequencyRange {
  final int minFrequency;
  final int maxFrequency;

  const IrFrequencyRange({
    required this.minFrequency,
    required this.maxFrequency,
  });

  bool supports(int frequency) =>
      frequency >= minFrequency && frequency <= maxFrequency;

  @override
  String toString() =>
      '${(minFrequency / 1000).toStringAsFixed(0)}–'
      '${(maxFrequency / 1000).toStringAsFixed(0)} kHz';
}
