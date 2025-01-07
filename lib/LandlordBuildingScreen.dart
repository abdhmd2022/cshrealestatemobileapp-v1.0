import 'package:cshrealestatemobile/LandlordDashboard.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'constants.dart';

class BuildingReportScreen extends StatelessWidget {
  final String buildingName;
  final List<int> occupiedUnits;
  final List<int> availableUnits;

  BuildingReportScreen({required this.buildingName, required this.occupiedUnits, required this.availableUnits});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$buildingName Units Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),


            SizedBox(height: 30),




            BarGraph(occupiedUnits: occupiedUnits, availableUnits: availableUnits,buildingName: buildingName,),

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
                          color: Colors.redAccent,
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
                          color: Colors.greenAccent,
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
      ),
    );
  }
}
class BarGraph extends StatelessWidget {
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
}
