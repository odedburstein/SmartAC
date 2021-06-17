import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ac/enums/bluetooth_status.dart';

class BluetoothRepository with ChangeNotifier {
  BluetoothConnection _connection;
  BluetoothStatus _status = BluetoothStatus.uninitialized;
  bool _isDebugMode = false;

  BluetoothRepository.instance();

  BluetoothConnection get connection => _connection;
  BluetoothStatus get status => _status;
  bool get isDebugMode => _isDebugMode;

  Future<bool> connectToRaspberryPi(ValueChanged<Uint8List> onChange) async {
    var success = true;
    try {
      _status = BluetoothStatus.connecting;
      notifyListeners();
      _connection = await BluetoothConnection
          .toAddress('E4:5F:01:0E:10:86');
      _connection.input.listen(onChange);
      _status = BluetoothStatus.connected;
      notifyListeners();
    } catch (e) {
      success = false;
      _status = BluetoothStatus.disconnected;
      notifyListeners();
    }
    return success;
  }

  Future<void> fetchDebugMode() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final debugMode = sharedPreferences.getBool('isDebugMode');
    _isDebugMode = debugMode ?? false;
  }

  Future<void> toggleDebugMode() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool('isDebugMode', !_isDebugMode);
    _isDebugMode = !_isDebugMode;
    notifyListeners();
  }

  Future sendTurnOnSystem() {
    return _sendMessage('ON');
  }

  Future sendTurnOffSystem() {
    return _sendMessage('OFF');
  }

  Future sendRefreshUserPicture() {
    return _sendMessage('REFRESH_FACE');
  }

  Future sendRefreshPosition() {
    return _sendMessage('REFRESH_POSITION');
  }

  Future _sendMessage(String message) async {
    if (_connection == null) {
      return;
    }

    _connection.output.add(ascii.encode(message));
    return await _connection.output.allSent;
  }
}