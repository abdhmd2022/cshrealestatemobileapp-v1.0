import 'package:cshrealestatemobile/AmenitiesReport.dart';
import 'package:cshrealestatemobile/LeadStatusReport.dart';
import 'package:cshrealestatemobile/LeadTypeReport.dart';
import 'package:cshrealestatemobile/MaintenanceStatusReport.dart';
import 'package:cshrealestatemobile/MaintenanceTypeMastersReport.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ActivitySourceReport.dart';
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

  TextEditingController minController = TextEditingController();
  TextEditingController maxController = TextEditingController();

  double range_min = 10000;
  double range_max = 100000;

  @override
  void initState() {
    super.initState();
    _loadRangeValues();
  }

  void _loadRangeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      range_min = prefs.getDouble('range_min') ?? 10000;
      range_max = prefs.getDouble('range_max') ?? 100000;
      minController.text = range_min.toString();
      maxController.text = range_max.toString();
    });
  }

  void _saveRangeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('range_min', double.parse(minController.text));
    prefs.setDouble('range_max', double.parse(maxController.text));
  }

  // Show dialog to set price range
  void _showPriceRangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
          ),
          child: AlertDialog(
            title: Text('Set Price Range'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Minimum Price',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color, width: 1),
                    ),                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Maximum Price',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color, width: 1),
                    ),                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: appbar_color),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveRangeValues();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: appbar_color),
                child: Text(
                  "Save",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      appBar: AppBar(
        title: Text("Settings",
        style: GoogleFonts.poppins(
          color: Colors.white
        ),),
        backgroundColor: appbar_color.withOpacity(0.9),
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

      ),
      body: Container(
        color: Colors.white,
        child:
      ListView(
        children: [


          if(hasPermissionInCategory('Lead Status'))...[
            Padding(padding: EdgeInsets.only(top: 5,bottom: 5),
                child: ListTile(
                  title: Text('Lead Status'),
                  subtitle: Text('Manage lead/follow-up status masters for the app'),
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
          ],

          if(hasPermission('canCreateAmenities') || hasPermission('canViewAmenities') || hasPermission('canUpdateAmenities') || hasPermission('canDeleteAmenities'))...[
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


          if(hasPermission('canSetPriceRangeForSalesInquiry'))...[
            Padding(
              padding: EdgeInsets.only(top: 5,bottom: 5),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Price Range'),
                    subtitle: Text('Set price range for sales enquiry'),

                    onTap: _showPriceRangeDialog, // Open dialog when tile is tapped
                  ),
                ],
              ),
            ),
            Divider(),
          ],


          if(hasPermissionInCategory('Lead Follow-up Type'))...[
            Padding(padding: EdgeInsets.only(top: 5,bottom: 5),
                child: ListTile(
                  title: Text('Lead Follow-up Type'),
                  subtitle: Text('Manage lead follow-up type masters for the app'),
                  onTap: ()
                  {
                    Navigator.pushReplacement

                      (
                      context,
                      MaterialPageRoute(builder: (context) => LeadFollowupTypeReport()), // navigate to company and serial select screen
                    );

                  },
                )),
            Divider(),
          ],
          
          if(hasPermissionInCategory('Activity Source'))...[

            Padding(padding: EdgeInsets.only(top: 5,bottom: 5),
                child: ListTile(
                  title: Text('Activity Source'),
                  subtitle: Text('Manage activity source masters for the app'),
                  onTap: ()
                  {
                    Navigator.pushReplacement

                      (
                      context,
                      MaterialPageRoute(builder: (context) => ActivitySourceReport()), // navigate to company and serial select screen
                    );

                  },
                )),

            Divider(),
          ],


          if(hasPermissionInCategory('Maintenance Types'))...[
            Padding(padding: EdgeInsets.only(top: 5,bottom: 5),
                child: ListTile(
                  title: Text('Maintenance Types'),
                  subtitle: Text('Manage maintenance types masters for the app'),
                  onTap: ()
                  {
                    Navigator.pushReplacement

                      (
                      context,
                      MaterialPageRoute(builder: (context) => MaintenanceTypeMastersReport()), // navigate to company and serial select screen
                    );

                  },
                )),

            Divider(),
          ],

          if(hasPermissionInCategory('Maintenance Status'))...[
            Padding(padding: EdgeInsets.only(top: 5,bottom: 5),
                child: ListTile(
                  title: Text('Maintenance Status'),
                  subtitle: Text('Manage maintenance status masters for the app'),
                  onTap: ()
                  {
                    Navigator.pushReplacement

                      (
                      context,
                      MaterialPageRoute(builder: (context) => MaintenanceStatusReport()), // navigate to company and serial select screen
                    );

                  },
                )),
          ]





        ],
      ),),

    );
  }
}

