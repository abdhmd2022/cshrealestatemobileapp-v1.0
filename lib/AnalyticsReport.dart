import 'dart:convert';
import 'dart:io';

import 'package:cshrealestatemobile/BuildingsScreen.dart';
import 'package:cshrealestatemobile/AdminDashboard.dart';
import 'package:cshrealestatemobile/ComplaintReport.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'BuildingDetailsScreen.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;

import 'package:google_fonts/google_fonts.dart';

class LandlordDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Analytics',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LandlordDashboardScreen(),
    );
  }
}


class LandlordDashboardScreen extends StatefulWidget {
  @override
  _LandlordDashboardScreenState createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> with TickerProviderStateMixin {

   List<String> buildingNames = [

  ];

   bool isLoadingBarChart = false;
   List<int> occupiedUnits = []; // Example data for occupied units
   List<int> availableUnits = []; // Example data for available units


  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }


  Future<void> _initSharedPreferences() async {

    if(hasPermission('canViewAllBuildingsGraph'))
      {
        fetchBuildingData();

      }
  }

  Future<void> fetchBuildingData() async {

    buildingNames.clear();
    availableUnits.clear();
    occupiedUnits.clear();

    setState(() {
      isLoadingBarChart = true;
    });
    final response = await http.get(
      Uri.parse("$baseurl/reports/building/available/date?date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}"),
      headers: {
        "Authorization": "Bearer $Company_Token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {

      final jsonData = json.decode(response.body);
      final buildingsJson = jsonData['data']['buildings'] as List;

      for (var building in buildingsJson) {
        final name = building['name'];
        final flats = building['flats'] as List;

        int occupied = flats.where((f) => f['is_occupied'] == 'true').length;
        int available = flats.where((f) => f['is_occupied'] == 'false').length;

        buildingNames.add(name);
        occupiedUnits.add(occupied);
        availableUnits.add(available);
      }
    } else {
      throw Exception('Failed to load buildings');
    }
    setState(() {
      isLoadingBarChart = false;
    });
  }


    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        title: Text('Analytics',
            style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
        leading: GestureDetector(

          onTap: ()
          {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
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
        height: MediaQuery.of(context).size.height,

        color: Colors.white,
        child: SingleChildScrollView(

            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if(hasPermission('canViewAllBuildingsGraph'))...[

                        isLoadingBarChart
                            ? Center(
                          child: Platform.isIOS
                              ? const CupertinoActivityIndicator(radius: 18)
                              : CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
                          ),
                        )
                            :
                        buildingNames.isEmpty
                            ? Center(
                          child: Column(

                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.domain_disabled, color: Colors.grey, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'Building(s) Not Found',
                                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                            :

                        SizedBox(height: 0),



                        if(buildingNames.isNotEmpty)...[

                          Container(
                            height: 370,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(20),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.4,
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    'Unit(s) Overview',
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),

                                  SizedBox(height: 20),
                                  Expanded(
                                    flex: 1,

                                    child: BarGraph(occupiedUnits: occupiedUnits, buildingNames: buildingNames,availableUnits: availableUnits,),

                                  ),                        SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 15,
                                              height: 15,
                                              decoration: BoxDecoration(
                                                color: Colors.orangeAccent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Occupied'),
                                          ],
                                        ),
                                        SizedBox(width: 16),
                                        Row(
                                          children: [
                                            Container(
                                              width: 15,
                                              height: 15,
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Available'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),



                          SizedBox(height: 16),

                        ],
                      ],




                      Container(

                        child:

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, // stretches children

                          children: [
                            if(hasPermission('canViewBuildingWise'))...[
                              _buildDashboardButton(Icons.apartment, 'Building(s)', '', appbar_color, () {

                                Navigator.pushReplacement(
                                  context,

                                  MaterialPageRoute(builder: (context) => BuildingsScreen()),          // navigate to users screen
                                );
                              }),

                              SizedBox( height: 10), 
                            ],
                            if(hasPermission('canViewComplaintSuggestions') || hasPermission('canFollowUpComplaintSuggestion'))...[
                              _buildDashboardButton(Icons.apartment, 'Complaints/Suggestions', '', appbar_color, () {

                                Navigator.pushReplacement(
                                  context,

                                  MaterialPageRoute(builder: (context) => ComplaintSuggestionReportScreen()),          // navigate to users screen
                                );
                              }),
                            ]
                          ],
                        ),
                      )])))
      ),
        );}
}



class BarGraph extends StatelessWidget {
  final List<int> occupiedUnits;
  final List<String> buildingNames;
  final List<int> availableUnits;

  BarGraph({required this.occupiedUnits, required this.buildingNames,required this.availableUnits});

  @override
  Widget build(BuildContext context) {

    // Constants for spacing and dimensions
    const double barWidth = 40; // Width of each bar
    const double groupSpace = 60; // Space between bar groups
    const double barSpacing = 5; // Space between bars in a group

    // Calculate chart width based on the number of buildings
    double calculatedWidth =
        buildingNames.length * (barWidth * 2 + groupSpace) ;

    // Ensure the chart width is at least as wide as the screen
    double screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = calculatedWidth > screenWidth ? calculatedWidth : screenWidth-60;

    // Calculate maximum value for the left titles
    int maxUnits = (occupiedUnits + availableUnits).reduce((a, b) => a > b ? a : b);
    double leftTitleReservedSize = (maxUnits.toString().length * 8.0) + 16.0; // Adjust size based on number length

    String formatLabel(int value) {
      // Display value as 'K' for every multiple of thousand
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        return value.toString();
      }
    }


     return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.only(top: 5),
        width: chartWidth,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,                   // step size of 1 unit on Y-axis&#8203;:contentReference[oaicite:4]{index=4}
                  reservedSize: leftTitleReservedSize,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    // Only label integer values (to avoid 0.5, 1.5, etc.)
                    if (value % 1 != 0) {
                      return const SizedBox.shrink();  // no widget for fractional values
                    }
                    return Text(
                      value.toInt().toString(),        // display the integer value
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,

                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40, // Increased reserved space
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        buildingNames[value.toInt()],
                        style: GoogleFonts.poppins(fontSize: 10), // Adjust font size
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: leftTitleReservedSize,
                interval: 1,                   // step size of 1 unit on Y-axis&#8203;:contentReference[oaicite:4]{index=4}

                getTitlesWidget: (double value, TitleMeta meta) {
                  // Only label integer values (to avoid 0.5, 1.5, etc.)
                  if (value % 1 != 0) {
                    return const SizedBox.shrink();  // no widget for fractional values
                  }
                  return Text(
                    value.toInt().toString(),        // display the integer value
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,

                    ),
                  );
                },
              ),),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              buildingNames.length,
                  (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    fromY: 0,
                    toY: occupiedUnits[index].toDouble(),
                    gradient: LinearGradient(
                      colors: [Colors.orangeAccent.shade100,Colors.orangeAccent.shade200, Colors.orangeAccent.shade200], // Gradient background
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    width: barWidth,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  BarChartRodData(
                    fromY: 0,
                    toY: availableUnits[index].toDouble(),
                    gradient: LinearGradient(
                      colors: [appbar_color.withOpacity(0.5),appbar_color.withOpacity(0.7), appbar_color.withOpacity(0.9)], // Gradient background
                      begin: Alignment.topCenter,

                      end: Alignment.bottomCenter,
                    ),
                    width: barWidth,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
                barsSpace: barSpacing,
              ),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
          ),
        ),
      ),
    );



  }
}

Widget _buildDashboardButton(IconData icon, String label, String count, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 100,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 0),
      padding: EdgeInsets.only(top:10,bottom:10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(icon, color: color, size: 32),
          SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (count.isNotEmpty)
            Column(
              children: [
                SizedBox(height: 3,),
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            )

        ],
      ),
    ),
  );
}




