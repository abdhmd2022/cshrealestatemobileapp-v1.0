import 'package:cshrealestatemobile/CreateInquiry.dart';
import 'package:cshrealestatemobile/SplashScreen.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'constants.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: app_name,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: Login(title: app_name,),
    );}}