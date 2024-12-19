import 'dart:io';
import 'package:cshrealestatemobile/MaintenanceTicketCreation.dart';
import 'package:cshrealestatemobile/Profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'RolesReport.dart';
import 'UsersReport.dart';
import 'constants.dart';


class Sidebar extends StatelessWidget {
  final bool isDashEnable,isRolesVisible,isUserEnable ,isRolesEnable,isUserVisible;
/*
  bool isSalesEntryVisible = false,isSalesEntryEnable = true,isReceiptEntryVisible = false,isReceiptEntryEnable = true;
*/
  String? Username = "", Email = "",SalesEntryHolder = '',username_prefs ='',password_prefs = '',ReceiptEntryHolder = '';

  String socketId = ''; // To store the socket ID.
  String deviceIdentifier = '';

  Sidebar(
      {
        Key? key,
        required this.isDashEnable,
        required this.isRolesVisible,
        required this.isRolesEnable,
        required this.isUserEnable,
        required this.Username,
        required this.Email,
        required this.tickerProvider,
        required this.isUserVisible,
      }
      ) : super(key: key)
  {
    _loadSharedPreferences();
  }


  void _loadSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

  }

  final TickerProvider tickerProvider ;

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.transparent, // set the background color to red
                              radius: 30.0,
                              child: SizedBox(
                                height: 50.0,
                                width: 50,
                                child: Icon(Icons.person),
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Padding(padding: EdgeInsets.only(top:30.0),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        Username!,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.0,
                                        ),
                                      ),
                                      SizedBox(width: 15.0,
                                        height: 3.0,),

                                      Text(
                                          Email!,
                                          style: TextStyle
                                            (
                                            color: Colors.black,
                                            fontSize: 13.0,
                                          ))]))]))),
              ListTile
                (
                title: Text('Dashboard'),
                leading: Icon(Icons.dashboard,
                  color: Colors.black,
                ),
                enabled: isDashEnable, // disable the item based on the parameter

                onTap: () {
                  /*Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Dashboard()), // navigate to dashboard screen
                  );*/
                },
              ),
              ListTile(
                title: Text('Maintenance Ticket'),
                leading: Icon(Icons.hardware,
                  color: Colors.black,
                ),
                onTap: () async {
                  Navigator.pushReplacement
                    (
                    context,
                    MaterialPageRoute(builder: (context) => MaintenanceTicketCreation()), // navigate to company and serial select screen
                  );
                  // navigate to companies screen
                },
              ),
              /*Visibility(
                visible: isSalesEntryVisible,
                child:  ListTile(
                  title: Text('Sales Entry'),
                  leading: Icon(Icons.point_of_sale,
                    color: Colors.black,
                  ),
                  enabled: isSalesEntryEnable,
                  onTap: () {
                    Navigator.pop(context);

                    *//*Fluttertoast.showToast(msg: 'Coming Soon');*//*
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PendingSalesEntry()),
                    );
                    *//*ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Coming Soon"),
                      ),
                    );*//*
                  },
                )
            ),

            Visibility(
                visible: isReceiptEntryVisible,
                child:  ListTile(
                  title: Text('Receipts Entry'),
                  leading: Icon(Icons.receipt_long,

                    color: Colors.black,
                  ),
                  enabled: isReceiptEntryEnable,
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PendingReceiptEntry()),
                    );
                    *//*Fluttertoast.showToast(msg: 'Coming Soon');*//*

                    *//*ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Coming Soon"),
                      ),
                    );*//*
                  },
                )
            ),*/
              Visibility(
                  visible: isRolesVisible,
                  child:  ListTile(
                    title: Text('Roles'),
                    leading: Icon(Icons.group,
                      color: Colors.black,
                    ),
                    enabled: isRolesEnable,
                    onTap: ()
                    {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => RolesReport()),          // navigate to roles screen
                      );
                    },
                  )
              ),

              Visibility(
                  visible: isUserVisible,

                  child: ListTile(
                      title: Text('Users'),
                      leading: Icon(Icons.person,
                        color: Colors.black,
                      ),
                      enabled: isUserEnable,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => UsersReport()),          // navigate to users screen
                        );
                      })),

              ListTile(
                  title: Text('Profile'),
                  leading: Icon(Icons.info_outline,
                    color: Colors.black,
                  ),
                  enabled: true,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Profile()),          // navigate to users screen
                    );
                  }),

              /*ListTile(
                  title: Text('Settings'),
                  leading: Icon(Icons.settings,
                    color: Colors.black,
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the dialog
                    *//*Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Settings()),         // navigate to settings screen
                    );*//*
                  }),*/
              Divider(),
              ListTile(
                title: Text('Version 1.0'),
                leading: Icon(Icons.build,
                  color: Colors.black,
                ),
                onTap: () {
                  // show version information
                },
              ),
              ListTile(
                  title: Text('Help'),
                  leading: Icon(Icons.contact_support,
                    color: Colors.black,
                  ),
                  onTap: ()
                  {
                    Navigator.pop(context); // Close the dialog
                    /*Navigator.push
                      (
                      context,
                      MaterialPageRoute(builder: (context) => Help()), // navigate to help screen
                    );*/
                  }
              ),

              ListTile
                (
                  title: Text('Logout'),
                  leading: Icon(Icons.logout,
                    color: Colors.black,
                  ),
                  onTap: ()
                  {
                    _showConfirmationDialogAndNavigate(context);
                  })]));
  }

  /*void emitDeleteMyId(Map<String, dynamic> jsonPayload, Function() onComplete) {
    socket.emit('deleteMyId', jsonPayload);

    if (onComplete != null) {
      onComplete();
    }
  }*/
  Future<void> _showConfirmationDialogAndNavigate(BuildContext context) async { // logout dialog function
    await showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button to close dialog
        builder: (context) {
          return ScaleTransition(
              scale: CurvedAnimation(
                parent: AnimationController(
                  duration: const Duration(milliseconds: 500),
                  vsync: tickerProvider,
                )..forward(),
                curve: Curves.fastOutSlowIn,
              ),
              child: AlertDialog(
                  title: Text('Logout Confirmation'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text('Do you really want to Logout?'),
                      ],
                    ),
                  ),
                  actions: <Widget>[

                    TextButton(
                        child: Text(
                          'No',
                          style: TextStyle(
                            color: Color(0xFF30D5C8), // Change the text color here
                          ),
                        ),
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
                          final prefs = await SharedPreferences.getInstance();

                          prefs.remove('username_remember');
                          prefs.remove('password_remember');
                          prefs.remove('username');
                          prefs.remove('password');
                          prefs.remove('serial_no');
                          prefs.remove('company_name');
                          prefs.remove('startfrom');
                          prefs.remove('serial_no');
                          prefs.remove('inactiveparties_days');

                          final jsonPayload = {
                            'username': username_prefs,
                            'password': password_prefs,
                            'macId': deviceIdentifier,
                          };
                          Navigator.of(context).pop();

                          /*socket.emit('deleteMyId', jsonPayload);*/
                          /*emitDeleteMyId(jsonPayload, () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => Login(username: '',password: '')),
                            );})*/;}
                    ),]));});}}