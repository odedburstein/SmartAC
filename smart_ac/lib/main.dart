import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_ac/bluetooth_lister.dart';
import 'package:smart_ac/settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final _initializeApp = Firebase.initializeApp();

  App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }

        return MaterialApp(
          theme: ThemeData(primarySwatch: Colors.teal),
          home: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart A/C',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme)
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
  bool _loading;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _loading = false;
  }

  @override
  void dispose() {
    super.dispose();
    _messageController?.dispose();
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
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettingsScreen()));
          }),
        ],
      ),
      body: FutureBuilder<BluetoothConnection>(
        future: _connectToRaspberryPi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final connection = snapshot.data;
            final textFieldBorder = OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white));

            if (_loading) {
              return CircularProgressIndicator(backgroundColor: Colors.white);
            }

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
                    onPressed: () async {
                      setState(() {
                        _loading = true;
                      });

                      await _connectToRaspberryPi();
                      // await _showBluetoothList();

                      setState(() {
                        _loading = false;
                      });
                    }
                ),
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

  Future<void> _showBluetoothList() {
    return showModalBottomSheet(
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
