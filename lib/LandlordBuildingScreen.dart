import 'package:cshrealestatemobile/LandlordDashboard.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';

class BuildingReportScreen extends StatelessWidget {
  final String buildingName;
  final List<int> occupiedUnits;
  final List<int> availableUnits;

  BuildingReportScreen({required this.buildingName, required this.occupiedUnits, required this.availableUnits});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openMaps() async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(buildingName)}";
    final String appleMapsUrl =
        "https://maps.apple.com/?q=${Uri.encodeComponent(buildingName)}";
    final String wazeUrl =
        "waze://?q=${Uri.encodeComponent(buildingName)}"; // Waze URL scheme

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // For iOS, prefer Apple Maps
      if (await canLaunch(appleMapsUrl)) {
        await launch(appleMapsUrl);
      } else if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not open map app';
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // For Android, check if Google Maps or Waze is installed
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else if (await canLaunch(wazeUrl)) {
        await launch(wazeUrl);
      } else {
        throw 'Could not open map app';
      }
    } else {
      // Default case for unsupported platforms
      throw 'Platform not supported';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: appbar_color,
        title: Text(buildingName,
            style: TextStyle(color: Colors.white)),
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
      body: Stack(
          children:[

            SingleChildScrollView(child: Expanded(child: Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$buildingName Units Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 1),

                  PieChartGraph(occupiedUnits: occupiedUnits, availableUnits: availableUnits,buildingName: buildingName,),

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
                                color: Colors.orangeAccent,
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
                                color: Colors.blueAccent,
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
                ],
              ),
            ),),),


            Positioned(
              bottom: 20, // Adjust as needed
              left: 0,
              right: 20,
              child: Align(
                alignment: Alignment.bottomRight,


                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/building_location.png', // Image from assets
                    width: 75, // Adjust size as needed
                    height: 75,
                  ),
                ),
              ),

            ),
          ]
      )
    );
  }
}

class PieChartGraph extends StatelessWidget {
  final List<int> occupiedUnits;
  final List<int> availableUnits;
  final String buildingName;

  PieChartGraph({
    required this.occupiedUnits,
    required this.availableUnits,
    required this.buildingName,
  });

  @override
  Widget build(BuildContext context) {
    // Combine occupied and available units for a single building
    int totalOccupied = occupiedUnits[0]; // Assuming single building
    int totalAvailable = availableUnits[0];
    int totalUnits = totalOccupied + totalAvailable;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Container(
          height: MediaQuery.of(context).size.height / 3,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 0,
              sectionsSpace: 0,

              sections: [
                PieChartSectionData(
                  value: totalOccupied.toDouble(),
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent.shade100,Colors.orangeAccent.shade200, Colors.orangeAccent.shade200], // Gradient background
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  title: "${totalOccupied.toString()} Unit(s)",
                  titleStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  radius: 120,
                ),
                PieChartSectionData(
                  value: totalAvailable.toDouble(),
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent.shade100,Colors.blueAccent.shade200, Colors.blueAccent.shade200], // Gradient background
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  title: '${totalAvailable.toString()} Unit(s)',
                  titleStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  radius: 120,
                ),
              ],
              borderData: FlBorderData(show: false),
            ),
          ),
        ),


      ],
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;

  Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
/*class BarGraph extends StatelessWidget {
  final List<int> occupiedUnits;
  final List<int> availableUnits;
  final String buildingName;

  BarGraph({required this.occupiedUnits, required this.availableUnits, required this.buildingName});

  @override
  Widget build(BuildContext context) {
    // Print occupied and available units in the console
    print('occupied Units: $occupiedUnits');
    print('Available Units: $availableUnits');

    // Constants for spacing and dimensions
    const double barWidth = 40; // Width of each bar
    const double barSpacing = 5; // Space between bars in a group

    // Calculate chart width based on the number of units
    double calculatedWidth = occupiedUnits.length * (barWidth * 2);

    // Ensure the chart width is at least as wide as the screen
    double screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = calculatedWidth > screenWidth ? calculatedWidth : screenWidth;

    // Calculate maximum value for the left titles
    int maxUnits = (occupiedUnits + availableUnits).reduce((a, b) => a > b ? a : b);
    double leftTitleReservedSize = (maxUnits.toString().length * 7.0) + 16.0; // Adjust size based on number length

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
        height: MediaQuery.of(context).size.height/2,
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
                        buildingName, // Single building label
                        style: TextStyle(fontSize: 10), // Adjust font size
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
            barGroups: [
              BarChartGroupData(
                x: 0, // Single group (for single building)
                barRods: [
                  BarChartRodData(
                    fromY: 0,
                    toY: occupiedUnits[0].toDouble(), // occupied units
                    color: Colors.redAccent,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  BarChartRodData(
                    fromY: 0,
                    toY: availableUnits[0].toDouble(), // Available units
                    color: Colors.greenAccent,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
                barsSpace: barSpacing,
              ),
            ],
            gridData: FlGridData(show: true, drawVerticalLine: false),
          ),
        ),
      ),
    );
  }
}*/
