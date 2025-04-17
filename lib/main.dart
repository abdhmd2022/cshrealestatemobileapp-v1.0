import 'package:flutter/material.dart';
import 'Login.dart';
import 'constants.dart';

void main() {
  runApp(const MyApp());
}
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: app_name,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        textTheme: globalTextTheme, // ✅ Apply global text theme without fixed sizes
      ),
      home: Login(title: app_name),
    );
  }
}