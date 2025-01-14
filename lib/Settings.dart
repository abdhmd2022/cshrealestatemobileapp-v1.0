import 'package:cshrealestatemobile/AmenitiesReport.dart';
import 'package:cshrealestatemobile/LeadStatusReport.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding
import 'package:http/http.dart' as http;

import 'Sidebar.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  bool isQualified = false;
  TextEditingController leadStatusController = TextEditingController();
  final String uuid = "6e35f08d-8285-45e3-ae32-a0e9efe5407e";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      appBar: AppBar(
        title: Text("Settings",
        style: TextStyle(
          color: Colors.white
        ),),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),
      ),
      drawer: Sidebar(
        isDashEnable: true,
        isRolesVisible: true,
        isRolesEnable: true,
        isUserEnable: true,
        isUserVisible: true,
        Username: "",
        Email: "",
        tickerProvider: this,
      ),
      body: ListView(
        children: [


          Padding(padding: EdgeInsets.only(top: 5,bottom: 5),
              child: ListTile(
                  title: Text('Lead Status'),
                  subtitle: Text('Manage lead status masters for the app'),
                  onTap: ()
                {
                  Navigator.pushReplacement

                    (
                    context,
                    MaterialPageRoute(builder: (context) => LeadStatusReport()), // navigate to company and serial select screen
                  );

                },
                  )),
          Divider(),

          Padding(padding: EdgeInsets.only(top: 5,bottom: 5),
              child: ListTile(
                title: Text('Amenities'),
                subtitle: Text('Manage amenities masters for the app'),
                onTap: ()
                {
                  Navigator.pushReplacement

                    (
                    context,
                    MaterialPageRoute(builder: (context) => AmentiesReport()), // navigate to company and serial select screen
                  );

                },
              )),
          Divider(),



        ],
      ),
    );
  }
}

