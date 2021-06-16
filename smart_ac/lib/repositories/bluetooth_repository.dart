import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:smart_ac/enums/bluetooth_status.dart';

class BluetoothRepository with ChangeNotifier {
  BluetoothConnection _connection;
  BluetoothStatus _status = BluetoothStatus.uninitialized;

  BluetoothRepository.instance();

  BluetoothConnection get connection => _connection;
  BluetoothStatus get status => _status;

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