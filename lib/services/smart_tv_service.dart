import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum TvConnectionState { disconnected, connecting, connected, failed }

class SmartTvConnectionService {
  WebSocket? _socket;
  TvConnectionState _state = TvConnectionState.disconnected;
  String? _connectedIp;

  final _stateController = StreamController<TvConnectionState>.broadcast();
  Stream<TvConnectionState> get stateStream => _stateController.stream;
  TvConnectionState get state => _state;

  static const String _appName = 'FlutterRemote';
  static const String _appId = 'com.flutter.remote';
  static const Map<String, String> _samsungKeyMap = {
    'power': 'KEY_POWER',
    'volume_up': 'KEY_VOLUMEUP',
    'volume_down': 'KEY_VOLUMEDOWN',
    'mute': 'KEY_MUTE',
    'channel_up': 'KEY_CHUP',
    'channel_down': 'KEY_CHDOWN',
    'up': 'KEY_UP',
    'down': 'KEY_DOWN',
    'left': 'KEY_LEFT',
    'right': 'KEY_RIGHT',
    'enter': 'KEY_ENTER',
    'back': 'KEY_RETURN',
    'home': 'KEY_HOME',
    'menu': 'KEY_MENU',
    'settings': 'KEY_TOOLS',
    'input': 'KEY_SOURCE',
    'smart': 'KEY_SMART',
    'play_pause': 'KEY_PLAY',
    'prev': 'KEY_REWIND',
    'next': 'KEY_FF',
    'info': 'KEY_INFO',
    'exit': 'KEY_EXIT',
  };

  static const Map<String, String> _lgKeyMap = {
    'power': 'POWER',
    'volume_up': 'VOLUMEUP',
    'volume_down': 'VOLUMEDOWN',
    'mute': 'MUTE',
    'channel_up': 'CHANNELUP',
    'channel_down': 'CHANNELDOWN',
    'up': 'UP',
    'down': 'DOWN',
    'left': 'LEFT',
    'right': 'RIGHT',
    'enter': 'ENTER',
    'back': 'BACK',
    'home': 'HOME',
    'menu': 'MENU',
    'settings': 'MENU',
    'input': 'EXTERNALINPUT',
    'smart': 'HOME',
    'play_pause': 'PLAY',
    'prev': 'REWIND',
    'next': 'FASTFORWARD',
  };

  bool _isLg = false;

  Future<bool> connectToTv(String ip) async {
    if (_state == TvConnectionState.connected && _connectedIp == ip) {
      return true;
    }

    await disconnect();
    _setState(TvConnectionState.connecting);
    _connectedIp = ip;

    if (await _trySamsungConnect(ip)) return true;

    if (await _tryLgConnect(ip)) return true;

    _setState(TvConnectionState.failed);
    return false;
  }

  Future<bool> sendKey(String action) async {
    if (_state != TvConnectionState.connected || _socket == null) {
      debugPrint('[SmartTV] Not connected — cannot send "$action"');
      return false;
    }

    final keyMap = _isLg ? _lgKeyMap : _samsungKeyMap;
    final keyName = keyMap[action];

    if (keyName == null) {
      debugPrint('[SmartTV] No key mapping for action: "$action"');
      return false;
    }

    try {
      if (_isLg) {
        _sendLgKey(keyName);
      } else {
        _sendSamsungKey(keyName);
      }
      debugPrint('[SmartTV] Sent key "$keyName" for action "$action"');
      return true;
    } catch (e) {
      debugPrint('[SmartTV] Failed to send key: $e');
      _setState(TvConnectionState.failed);
      return false;
    }
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _isLg = false;
    _setState(TvConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
  }

  Future<bool> _trySamsungConnect(String ip) async {
    final encodedName = base64.encode(utf8.encode(_appName));
    final wsUrl =
        'ws://$ip:8001/api/v2/channels/samsung.remote.control'
        '?name=$encodedName';

    try {
      _socket = await WebSocket.connect(
        wsUrl,
      ).timeout(const Duration(seconds: 5));

      _isLg = false;
      _listenToSocket();
      _setState(TvConnectionState.connected);
      debugPrint('[SmartTV] Connected to Samsung TV at $ip');
      return true;
    } catch (e) {
      debugPrint('[SmartTV] Samsung connect failed: $e');
      _socket = null;
      return false;
    }
  }

  void _sendSamsungKey(String keyName) {
    final payload = jsonEncode({
      'method': 'ms.remote.control',
      'params': {
        'Cmd': 'Click',
        'DataOfCmd': keyName,
        'Option': 'false',
        'TypeOfRemote': 'SendRemoteKey',
      },
    });
    _socket!.add(payload);
  }

  Future<bool> _tryLgConnect(String ip) async {
    try {
      _socket = await WebSocket.connect(
        'ws://$ip:3000',
      ).timeout(const Duration(seconds: 5));

      _isLg = true;

      final registration = jsonEncode({
        'type': 'register',
        'id': 'reg0',
        'payload': {
          'forcePairing': false,
          'pairingType': 'PROMPT',
          'manifest': {
            'manifestVersion': 1,
            'appVersion': '1.1',
            'signed': {
              'created': '20140509',
              'appId': _appId,
              'vendorId': 'flutter',
              'localizedAppNames': {'': _appName},
              'localizedVendorNames': {'': 'Flutter'},
              'permissions': [
                'TEST_OPEN',
                'TEST_PROTECTED',
                'LAUNCH',
                'LAUNCH_WEBAPP',
                'APP_TO_APP',
                'CONTROL_AUDIO',
                'CONTROL_INPUT_JOYSTICK',
                'CONTROL_MOUSE_AND_KEYBOARD',
                'READ_INSTALLED_APPS',
                'READ_LGE_SDX',
                'READ_NOTIFICATIONS',
                'SEARCH',
                'WRITE_SETTINGS',
                'WRITE_NOTIFICATION_ALERT',
                'CONTROL_POWER',
                'READ_CURRENT_CHANNEL',
                'READ_RUNNING_APPS',
                'READ_UPDATE_INFO',
                'UPDATE_FROM_REMOTE_APP',
                'READ_LGE_TV_INPUT_EVENTS',
                'READ_TV_CURRENT_TIME',
              ],
            },
          },
        },
      });

      _socket!.add(registration);
      _listenToSocket();
      _setState(TvConnectionState.connected);
      debugPrint('[SmartTV] Connected to LG TV at $ip');
      return true;
    } catch (e) {
      debugPrint('[SmartTV] LG connect failed: $e');
      _socket = null;
      return false;
    }
  }

  void _sendLgKey(String keyName) {
    jsonEncode({
      'type': 'request',
      'uri': 'ssap://com.webos.service.ime/sendKeyboardInput',
      'payload': {'text': keyName, 'replace': false},
    });
    final buttonPayload = jsonEncode({
      'type': 'request',
      'uri': 'ssap://com.webos.service.remoteinput.tv/send',
      'id': 'btn0',
      'payload': {'keyCode': keyName},
    });
    _socket!.add(buttonPayload);
  }

  void _listenToSocket() {
    _socket!.listen(
      (message) {
        debugPrint('[SmartTV] Message: $message');
      },
      onError: (error) {
        debugPrint('[SmartTV] Socket error: $error');
        _setState(TvConnectionState.failed);
      },
      onDone: () {
        debugPrint('[SmartTV] Socket closed');
        _setState(TvConnectionState.disconnected);
      },
    );
  }

  void _setState(TvConnectionState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
