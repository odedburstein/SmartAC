import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smart_ac/repositories/bluetooth_repository.dart';
import 'package:smart_ac/screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final _initializeApp = Firebase.initializeApp();
  final _fetchDebugMode = BluetoothRepository.instance().fetchDebugMode();

  App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([_initializeApp, _fetchDebugMode]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ChangeNotifierProvider(
            create: (_) => BluetoothRepository.instance(),
            child: MaterialApp(
              title: 'Smart A/C',
              theme: ThemeData(
                  primarySwatch: Colors.indigo,
                  brightness: Brightness.light,
                  appBarTheme: Theme.of(context)
                      .appBarTheme
                      .copyWith(brightness: Brightness.dark),
                  textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme)
              ),
              home: MyHomePage(),
            ),
          );
        }

        return MaterialApp(
          theme: ThemeData(primarySwatch: Colors.indigo),
          home: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

