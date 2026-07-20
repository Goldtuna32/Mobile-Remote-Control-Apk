// providers/wifi_discovery_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bonsoir/bonsoir.dart';
import '../services/wifi_bonsoir_discovery_service.dart';

class BonsoirDiscoveryState {
  final bool isScanning;
  final bool isWifiConnected;
  final List<BonsoirService> resolvedDevices;

  const BonsoirDiscoveryState({
    this.isScanning = false,
    this.isWifiConnected = true,
    this.resolvedDevices = const [],
  });

  BonsoirDiscoveryState copyWith({
    bool? isScanning,
    bool? isWifiConnected,
    List<BonsoirService>? resolvedDevices,
  }) {
    return BonsoirDiscoveryState(
      isScanning: isScanning ?? this.isScanning,
      isWifiConnected: isWifiConnected ?? this.isWifiConnected,
      resolvedDevices: resolvedDevices ?? this.resolvedDevices,
    );
  }
}

class BonsoirDiscoveryNotifier extends Notifier<BonsoirDiscoveryState> {
  final _service = WifiBonsoirService();

  @override
  BonsoirDiscoveryState build() {
    ref.onDispose(() {
      _service.stopDiscovery();
    });
    return const BonsoirDiscoveryState();
  }

  Future<void> triggerScan() async {
    final hasWifi = await _service.isConnectedToWifi();
    if (!hasWifi) {
      state = const BonsoirDiscoveryState(isWifiConnected: false);
      return;
    }

    state = const BonsoirDiscoveryState(
      isScanning: true,
      isWifiConnected: true,
      resolvedDevices: [],
    );

    final stream = await _service.startDiscovery();
    if (stream == null) {
      state = state.copyWith(isScanning: false);
      return;
    }

    stream.listen((event) {
      final currentList = List<BonsoirService>.from(state.resolvedDevices);

      // Check standard enum parameters for resolved targets
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved &&
          event.service != null) {
        final index = currentList.indexWhere(
          (element) => element.name == event.service!.name,
        );
        if (index != -1) {
          currentList[index] = event.service!;
        } else {
          currentList.add(event.service!);
        }
        state = state.copyWith(resolvedDevices: currentList);
      }
      // Target dropped off local signal
      else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost &&
          event.service != null) {
        currentList.removeWhere(
          (element) => element.name == event.service!.name,
        );
        state = state.copyWith(resolvedDevices: currentList);
      }
    });

    // Timeout loop protects background processing loops
    Future.delayed(const Duration(seconds: 8), () {
      if (state.isScanning) {
        _service.stopDiscovery();
        state = state.copyWith(isScanning: false);
      }
    });
  }
}

// Configured using standard legacy .autoDispose extension instead of the class modifier
final bonsoirDiscoveryProvider =
    NotifierProvider.autoDispose<
      BonsoirDiscoveryNotifier,
      BonsoirDiscoveryState
    >(() {
      return BonsoirDiscoveryNotifier();
    });
