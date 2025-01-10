import 'package:cshrealestatemobile/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'LandlordBuildingScreen.dart';
import 'Sidebar.dart';

class LandlordDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Landlord Dashboard',
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
        backgroundColor: appbar_color,
        title: Text('Landlord Dashboard',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Units Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            color: Colors.redAccent.shade200,
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
                            color: Colors.blueAccent.shade200,
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

              SizedBox(height: 16,),
              Text(
                'Building(s)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Container(

                  child: ListView.builder(
                    itemCount: buildingNames.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
                        child: Card(
                          elevation: 8.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), // Adjust the radius here
                          ),

                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blueGrey.shade100, Colors.blueGrey.shade500],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              title: Text(
                                buildingNames[index],
                                style: TextStyle(fontWeight: FontWeight.bold,
                                color: Colors.white),
                              ),
                              trailing: Icon(Icons.arrow_forward,color: Colors.white,),
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BuildingReportScreen(
                                      buildingName: buildingNames[index],
                                      occupiedUnits: [occupiedUnits[index]], // Pass only the selected building's occupied units
                                      availableUnits: [availableUnits[index]],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
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
            barGroups: List.generate(
              buildingNames.length,
                  (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    fromY: 0,
                    toY: occupiedUnits[index].toDouble(),
                    gradient: LinearGradient(
                      colors: [Colors.redAccent.shade100,Colors.redAccent.shade200, Colors.redAccent.shade200], // Gradient background
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
                      colors: [Colors.blueAccent.shade100,Colors.blueAccent.shade200, Colors.blueAccent.shade200], // Gradient background
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



