import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_ac/enums/bluetooth_status.dart';
import 'package:smart_ac/repositories/bluetooth_repository.dart';
import 'package:smart_ac/screens/settings.dart';


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _messageController;
  bool _loading;
  bool _isSystemOn;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _loading = false;
    _isSystemOn = false;
  }

  @override
  void dispose() {
    super.dispose();
    _messageController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textFieldBorder = OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white));

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: AppBar(
        title: Text('A/C Remote', style: TextStyle(
          fontSize: 24,
        )),
        centerTitle: true,
        elevation: 0,
        actions: [
          Material(
            color: Colors.transparent,
            shape: CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SettingsScreen()));
                }
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _loading ? Shimmer.fromColors(
            baseColor: theme.primaryColorDark,
            highlightColor: theme.primaryColorLight,
            child: _onButton(theme: theme),
          ) : _onButton(theme: theme, onPressed: () async {
            setState(() {
              _loading = true;
            });

            final bluetoothRepository = Provider.of<BluetoothRepository>(context, listen: false);
            if (bluetoothRepository.status != BluetoothStatus.connected) {
              var connectionResult;
              connectionResult = await bluetoothRepository.connectToRaspberryPi((Uint8List data) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ascii.decode(data)),
                ));
              });

              if (!connectionResult) {
                setState(() {
                  _loading = false;
                });
                return;
              }
            }

            if (bluetoothRepository.status == BluetoothStatus.connected) {
              if (!_isSystemOn) {
                await bluetoothRepository.sendTurnOnSystem();
              } else {
                await bluetoothRepository.sendTurnOffSystem();
              }

              setState(() {
                _isSystemOn = !_isSystemOn;
              });
            }

            setState(() {
              _loading = false;
            });
          }),
          Container(height: 26,),
          Container(
            constraints: BoxConstraints(maxWidth: 200),
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                focusedBorder: textFieldBorder,
                enabledBorder: textFieldBorder,
                border: textFieldBorder,
              ),
            ),
          ),
          Container(height: 16,),
          TextButton(
            child: Text('Send'),
            style: TextButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () async {
              final bluetoothRepository = Provider.of<BluetoothRepository>(context, listen: false);
              if (bluetoothRepository.status == BluetoothStatus.connected) {
                await _sendMessage(bluetoothRepository.connection, _messageController.text);
                _messageController.text = '';
              }
            },
          )
        ]),
      ),
    );
  }

  Future<dynamic> _sendMessage(
      BluetoothConnection connection,
      String message) async {
    connection.output.add(ascii.encode(message));
    return await connection.output.allSent;
  }

  Widget _onButton({ThemeData theme, VoidCallback onPressed}) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: theme?.scaffoldBackgroundColor,
          onPrimary: Colors.black,
          onSurface: Colors.black,
          elevation: 10,
          shape: CircleBorder(),
          padding: EdgeInsets.all(24.0),
        ),
        child: Icon(
          Icons.power_settings_new_rounded,
          color: theme?.primaryColorDark,
          size: 100,
        ),
        onPressed: onPressed
    );

// Future<void> _showBluetoothList() {
//   return showModalBottomSheet(
//     isScrollControlled: true,
//     context: context,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadiusDirectional.only(
//           topStart: Radius.circular(20),
//           topEnd: Radius.circular(20)
//       ),
//     ),
//     builder: (_) => BluetoothLister(),
//   );
// }
}
