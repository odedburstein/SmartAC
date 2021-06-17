import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_ac/repositories/bluetooth_repository.dart';

class DebugModeSwitch extends StatelessWidget {
  const DebugModeSwitch({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bluetoothRepository = Provider.of<BluetoothRepository>(context);

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Debug mode', style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
      )),
      Switch(
          value: bluetoothRepository.isDebugMode,
          onChanged: (_) async {
            await bluetoothRepository.toggleDebugMode();
          }
      ),
    ]);
  }
}
