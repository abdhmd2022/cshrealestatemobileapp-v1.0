import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'BuildingDetailsScreen.dart';
import 'AnalyticsReport.dart';
import 'Sidebar.dart';

class BuildingsScreen extends StatefulWidget {
  @override
  _BuildingsScreenState createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> buildings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchBuildings();
  }

  Future<void> fetchBuildings() async {

    setState(() {

      _isLoading = true;
    });
    buildings.clear();
    final url = Uri.parse("$baseurl/reports/building/available/date?date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}");

    print('building url -> $url');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $Company_Token",
      "Content-Type": "application/json"
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        buildings = json['data']['buildings'];
      });
    } else {
      setState(() {
        buildings = []; // or keep as is, just trigger UI rebuild
      });
      // Handle error
      final error = jsonDecode(response.body);
      showErrorSnackbar(context, "${error['message'] ?? 'Unknown error'}");
    }

    setState(() {

      _isLoading = false;
    });
  }
  void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }


  Widget buildBuildingCard(dynamic building) {
    final area = building['area'] ?? {};
    final state = area['state'] ?? {};
    final country = state['country'] ?? {};

    return
      GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BuildingReportScreen(building: building),
              ),
            );
          },

      child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    building['name'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.shade100,
                  ),
                  child: Text(
                    building['status'] ?? 'Open',
                    style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.green.shade800),
                  ),
                )
              ],
            ),
            SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade300),

            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${area['name']}, ${state['name']}, ${country['name']}' ,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),

            if(building['completion_date']!=null)...[
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.redAccent),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Completed On: ${formatDate(building['completion_date'])}' ,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    ));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        title: Text('Building(s)', style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
        leading: GestureDetector(

          onTap: ()
          {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LandlordDashboardScreen()),
            );
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),
      ),
      drawer: Sidebar(
        isDashEnable: true,
        isRolesVisible: true,
        isRolesEnable: true,
        isUserEnable: true,
        isUserVisible: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: _isLoading
            ? Center(
          child: Platform.isIOS
              ? const CupertinoActivityIndicator(radius: 18)
              : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
          ),
        )
            : buildings.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.domain_disabled, color: Colors.grey, size: 48),
              SizedBox(height: 12),
              Text(
                'Buildings Not Found',
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            return buildBuildingCard(buildings[index]);
          },
        ),
      ),
    );
  }
}
