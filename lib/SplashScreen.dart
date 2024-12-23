/*
import'dart:async';
import 'package:cshrealestatemobile/CreateSalesInquiry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget
{
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  late SharedPreferences prefs;

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    Timer(Duration(seconds: 3), ()
    {
      Navigator.pushReplacement
        (
        context,
        MaterialPageRoute(builder: (context) => CreateInquiry(),
      ));
    });
  }

  @override
  void initState()
  {
    super.initState();

    _initSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:Stack(children: [
          Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(

                      Icons.real_estate_agent_outlined,
                      color: Colors.black,
                      size: 50,
                    ),
                    SizedBox(height: 20),
                    SpinKitFadingCube(
                      color: Colors.black,
                      size: 30.0,
                    )])),

          Positioned(
              bottom: 20, // Adjust this value according to your preference
              left: 0,
              right: 0,
              child: Center(
                  child: Text(
                      "© 2024 Chaturvedi Software House LLC. All Rights Reserved.",
                      style: TextStyle(
                        color: Colors.black54, // You can adjust the color here
                        fontSize: 12, // You can adjust the font size here
                      ))))]));}}*/
