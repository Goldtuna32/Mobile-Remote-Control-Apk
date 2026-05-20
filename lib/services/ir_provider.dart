import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ir_service.dart';

enum IrTransmitState { idle, transmitting, success, error }

class IrDebugNotifier extends Notifier<IrDebugState> {
  @override
  IrDebugState build() => const IrDebugState();

  Future<void> checkBlaster() async {
    state = state.copyWith(
      isChecking: true,
      log: [...state.log, '⟳ Checking IR hardware...'],
    );
    final has = await IrService.checkIrBlaster();
    state = state.copyWith(
      isChecking: false,
      hasBlaster: has,
      log: [
        ...state.log,
        has ? '✓ IR blaster detected' : '✗ No IR blaster on this device',
      ],
    );
  }

  Future<void> sendTestCode(String label, int freq, List<int> pattern) async {
    if (state.hasBlaster == false) {
      state = state.copyWith(
        transmitState: IrTransmitState.error,
        log: [...state.log, '✗ Aborted — no IR blaster'],
      );
      return;
    }

    state = state.copyWith(
      transmitState: IrTransmitState.transmitting,
      log: [
        ...state.log,
        '⟳ Sending: $label @ ${freq}Hz (${pattern.length} pulses)',
      ],
    );

    try {
      await IrService.transmit(carrierFrequency: freq, pattern: pattern);
      state = state.copyWith(
        transmitState: IrTransmitState.success,
        log: [...state.log, '✓ Transmitted: $label'],
      );
    } catch (e) {
      state = state.copyWith(
        transmitState: IrTransmitState.error,
        log: [...state.log, '✗ Error: $e'],
      );
    }
  }

  void clearLog() =>
      state = state.copyWith(log: [], transmitState: IrTransmitState.idle);
}

class IrDebugState {
  final bool? hasBlaster;
  final bool isChecking;
  final IrTransmitState transmitState;
  final List<String> log;

  const IrDebugState({
    this.hasBlaster,
    this.isChecking = false,
    this.transmitState = IrTransmitState.idle,
    this.log = const [],
  });

  IrDebugState copyWith({
    bool? hasBlaster,
    bool? isChecking,
    IrTransmitState? transmitState,
    List<String>? log,
  }) => IrDebugState(
    hasBlaster: hasBlaster ?? this.hasBlaster,
    isChecking: isChecking ?? this.isChecking,
    transmitState: transmitState ?? this.transmitState,
    log: log ?? this.log,
  );
}

final irDebugProvider = NotifierProvider<IrDebugNotifier, IrDebugState>(
  IrDebugNotifier.new,
);
