import 'package:cshrealestatemobile/BuildingsScreen.dart';
import 'package:cshrealestatemobile/AdminDashboard.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'BuildingDetailsScreen.dart';
import 'Sidebar.dart';
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

  final List<String> buildingNames = [
    'Al Khaleej Center',
    'Al Musalla Tower',
    'Al Ain Center',
  ];

  final List<int> occupiedUnits = [10, 5, 8]; // Example data for occupied units
  final List<int> availableUnits = [20, 15, 12]; // Example data for available units


  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }


  Future<void> _initSharedPreferences() async {



    setState(() {


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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.white,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unit(s) Overview',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              Expanded(
                flex: 1,
                child: BarGraph(occupiedUnits: occupiedUnits, buildingNames: buildingNames,availableUnits: availableUnits,),
              ),
              SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Red Color for occupied
                    Row(
                      children: [
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.shade200,
                            shape: BoxShape.circle, // Make it round
                          ),

                        ),
                        SizedBox(width: 8),
                        Text('Occupied'),
                      ],
                    ),
                    SizedBox(width: 16),
                    // Green Color for Available
                    Row(
                      children: [
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: appbar_color.withOpacity(0.7),
                            shape: BoxShape.circle, // Make it round
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Available'),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Expanded(
                child: Container(

                  child:

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDashboardButton(Icons.apartment, 'Building(s)', '', appbar_color, () {

                        Navigator.pushReplacement(
                          context,

                          MaterialPageRoute(builder: (context) => BuildingsScreen()),          // navigate to users screen
                        );
                      }),
                    ],
                  ),
                ))]))));}
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
        buildingNames.length * (barWidth * 2 + groupSpace);

    // Ensure the chart width is at least as wide as the screen
    double screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = calculatedWidth > screenWidth ? calculatedWidth : screenWidth;

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
                  reservedSize: leftTitleReservedSize,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      child: Text(
                        formatLabel(value.toInt()),
                      ),
                      axisSide: meta.axisSide,
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
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    child: Text(
                      formatLabel(value.toInt()),
                    ),
                    axisSide: meta.axisSide,
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
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.only(top:10,bottom:10),
        height: 110,
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
    ),
  );
}




