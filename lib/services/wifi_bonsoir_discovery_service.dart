// services/wifi_bonsoir_discovery_service.dart
import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class WifiBonsoirService {
  final Connectivity _connectivity = Connectivity();
  BonsoirDiscovery? _discovery;
  StreamController<BonsoirDiscoveryEvent>? _eventStreamController;

  Future<bool> isConnectedToWifi() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  Future<Stream<BonsoirDiscoveryEvent>?> startDiscovery({
    String serviceType = '_http._tcp',
  }) async {
    if (!await isConnectedToWifi()) return null;

    await stopDiscovery();

    _eventStreamController =
        StreamController<BonsoirDiscoveryEvent>.broadcast();

    // Using the legacy syntax style with trailing dot removal protection
    final cleanType = serviceType.endsWith('.')
        ? serviceType.substring(0, serviceType.length - 1)
        : serviceType;

    _discovery = BonsoirDiscovery(type: cleanType);

    // Fallback safe init: await the native plugin initialization hook
    await _discovery!.ready;

    _discovery!.eventStream!.listen((event) {
      if (_eventStreamController?.isClosed == false) {
        _eventStreamController!.add(event);
      }

      // Standard Event Check: resolve when a node target enters visibility
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound &&
          event.service != null) {
        event.service!.resolve(_discovery!.serviceResolver);
      }
    }, onError: (err) => _eventStreamController?.addError(err));

    await _discovery!.start();
    return _eventStreamController!.stream;
  }

  Future<void> stopDiscovery() async {
    try {
      if (_discovery != null) {
        await _discovery!.stop();
        _discovery = null;
      }
    } catch (e) {
      debugPrint("Error stopping Bonsoir: $e");
    }

    if (_eventStreamController != null && !_eventStreamController!.isClosed) {
      await _eventStreamController!.close();
      _eventStreamController = null;
    }
  }
}
