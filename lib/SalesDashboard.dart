import'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'Sidebar.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;


class SalesDashboard extends StatefulWidget
{
  const SalesDashboard({Key? key}) : super(key: key);
    @override
    _SalesDashboardPageState createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboard> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDashEnable = false,
       isRolesEnable = true,
       isUserEnable = true,
       isRolesVisible = true,
       isUserVisible = true;

  bool isSalesEntryVisible = false,isReceiptEntryVisible = false,isSalesOrderEntryVisible = false;

  String SalesEntryHolder = '',ReceiptEntryHolder = '',SalesOrderEntryHolder = "";
  String email = "";
  String name = "", token = '';

  late final TickerProvider tickerProvider ;

  String vchtype = "";
  DateTime? expire_date;

  String?  company = "Company";

  Future<void> _showConfirmationDialogAndExit(BuildContext context) async {
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button to close dialog
        builder: (BuildContext context) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: AnimationController(
                duration: const Duration(milliseconds: 500),
                vsync: tickerProvider,
              )..forward(),
              curve: Curves.fastOutSlowIn,
            ),
            child: AlertDialog(
              title: Text('Exit Confirmation'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Do you really want to Exit?'),
                  ])),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: Color(0xFF30D5C8), // Change the text color here
                    )),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
                TextButton(
                  child: Text(
                    'Yes',
                    style: TextStyle(
                      color: Color(0xFF30D5C8), // Change the text color here
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    exit(0);
                  })]));});
  }

  Future<void> _initSharedPreferences() async {
  }

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
          return  WillPopScope(
            onWillPop: () async {
              _showConfirmationDialogAndExit(context);
              return true;
            },
            child: Scaffold(
                key: _scaffoldKey,
                appBar: AppBar(
                  title: GestureDetector(
                    onTap: () {
                     /* Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SerialSelect()),
                      );*/
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              company!,
                              style: TextStyle(
                                  color: Colors.white
                              ),
                              overflow: TextOverflow.ellipsis, // Truncate text if it overflows
                              maxLines: 1, // Display only one line of text
                            ),
                          ),
                          SizedBox(width: 10), // Add some spacing between text and image
                          Image.asset(
                            'assets/ic_launcher_edit_items_criteria_img.png',
                            height: 50,
                            width: 45,
                          )]))),
                  backgroundColor: Colors.black,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    icon: Icon(Icons.menu,
                        color: Colors.white),
                    onPressed: () {
                      _scaffoldKey.currentState!.openDrawer();
                    },
                  ),
                ),
                drawer: Sidebar(
                    isDashEnable: isDashEnable,
                    isRolesVisible: isRolesVisible,
                    isRolesEnable: isRolesEnable,
                    isUserEnable: isUserEnable,
                    isUserVisible: isUserVisible,
                    Username: name,
                    Email: email,
                    tickerProvider: this), // add the Sidebar widget here
                body: Stack(
                  children: [

                  ],
                )
            ),// Empty container if the license is still valid
          );
    }
  }


