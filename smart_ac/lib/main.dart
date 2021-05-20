import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:smart_ac/bluetooth_lister.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart A/C',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: AppBar(
        title: Text('A/C Remote', style: TextStyle(
          fontSize: 24,
        )),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<BluetoothConnection>(
        future: _connectToRaspberryPi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final connection = snapshot.data;

            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: theme.scaffoldBackgroundColor,
                      onPrimary: Colors.black,
                      onSurface: Colors.black,
                      elevation: 10,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24.0),
                    ),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: theme.primaryColorDark,
                      size: 100,
                    ),
                    onPressed: () {}
                ),
                Container(height: 26,),
                Container(
                  constraints: BoxConstraints(maxWidth: 200),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Container(height: 16,),
                TextButton(
                  child: Text('Send'),
                  style: TextButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () async {
                    if (connection != null) {
                      await _sendMessage(connection, _messageController.text);
                      _messageController.text = '';
                    }
                  },
                )
              ]),
            );
          }

          return Center(
            child: CircularProgressIndicator(backgroundColor: Colors.white),
          );
        },
      ),
    );
  }

  Future<BluetoothConnection> _connectToRaspberryPi() async {
    var connection;
    try {
      connection = await BluetoothConnection
          .toAddress('E4:5F:01:0E:10:86');
      connection.input.listen((Uint8List data) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ascii.decode(data)),
        ));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
    return connection;
  }

  Future<dynamic> _sendMessage(
      BluetoothConnection connection,
      String message) async {
    connection.output.add(ascii.encode(message));
    return await connection.output.allSent;
  }

  void _showBluetoothList() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(20),
            topEnd: Radius.circular(20)
        ),
      ),
      builder: (_) => BluetoothLister(),
    );
  }
}
