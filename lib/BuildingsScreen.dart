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

    final url = Uri.parse(
        "$baseurl/reports/building/available/date?date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}"
    );

    print('building url -> $url');

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $Company_Token",
      "Content-Type": "application/json"
    });

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final buildingsJson = jsonData['data']['buildings'] as List;

      // Add available + occupied counts into each building map
      final processedBuildings = buildingsJson.map((building) {
        final flats = building['flats'] as List;
        final availableRent = (building['availableFlatsForRent'] ?? 0) as int;
        final occupied = flats.length - availableRent;

        return {
          ...building,
          'available_count': availableRent,
          'occupied_count': occupied
        };
      }).toList();

      setState(() {
        buildings = processedBuildings;
      });

    } else {
      setState(() {
        buildings = [];
      });

      try {
        final error = jsonDecode(response.body);
        showErrorSnackbar(context, "${error['message'] ?? 'Unknown error'}");
      } catch (_) {
        showErrorSnackbar(context, "Failed to load buildings");
      }
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
    final available = building['available_count'] ?? 0;
    final occupied = building['occupied_count'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BuildingReportScreen(building: building),
          ),
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    building['name'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    building['status'] ?? 'Open',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Location
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.blueAccent),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${area['name']}, ${state['name']}, ${country['name']}',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),

            if (building['completion_date'] != null) ...[
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 16, color: Colors.deepOrangeAccent),
                  SizedBox(width: 6),
                  Text(
                    'Completed: ${formatDate(building['completion_date'])}',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],

            SizedBox(height: 12),

            // Available + Occupied pills
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Available: $available',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Occupied: $occupied',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
