import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothLister extends StatefulWidget {
  const BluetoothLister({Key key}) : super(key: key);

  @override
  _BluetoothListerState createState() => _BluetoothListerState();
}

class _BluetoothListerState extends State<BluetoothLister> {
  final FlutterBluetoothSerial _bluetoothSerial = FlutterBluetoothSerial.instance;
  List<BluetoothDiscoveryResult> _scanResults = [];
  StreamSubscription<BluetoothDiscoveryResult> _subscription;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _subscription = _bluetoothSerial.startDiscovery()
        .listen((result) {
      if (result.device.name == 'MyLocalPi') {
        _bluetoothSerial.bondDeviceAtAddress('E4:5F:01:0E:10:86');
      }
      setState(() {
        _scanResults.add(result);
      });
    });

    _subscription?.onDone(() {
      setState(() {
        _finished = true;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished && _scanResults.length == 0) {
      return Container(
        height: 500,
        child: Center(child: Text('Nothing found')),
      );
    }

    if (_scanResults.length == 0) {
      return Container(
        height: 500,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: 500,
      child: Scrollbar(
        child: ListView.builder(
          itemCount: _scanResults.length,
          itemBuilder: (_, index) {
            final device = _scanResults[index].device;

            return ListTile(
              title: Text(device.name ?? 'No name'),
              trailing: Text(device.address ?? 'No address'),
              leading: Text(device.bondState.stringValue),
            );
          },
        ),
      ),
    );
  }
}
