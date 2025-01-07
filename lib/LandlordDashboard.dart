import 'package:cshrealestatemobile/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
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

  final List<int> vacantUnits = [10, 5, 8]; // Example data for vacant units
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
                'Vacant Units Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                flex: 2,
                child: BarGraph(vacantUnits: vacantUnits, buildingNames: buildingNames,availableUnits: availableUnits,),
              ),
              SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Red Color for Vacant
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
                        Text('Vacant'),
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

              SizedBox(height: 16,),
              Text(
                'Buildings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: buildingNames.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(buildingNames[index]),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                       /* Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BuildingReportScreen(
                              buildingName: buildingNames[index],
                            ),
                          ),
                        );*/
                      },
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }


}



class BarGraph extends StatelessWidget {
  final List<int> vacantUnits;
  final List<String> buildingNames;
  final List<int> availableUnits;

  BarGraph({required this.vacantUnits, required this.buildingNames,required this.availableUnits});

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
    int maxUnits = (vacantUnits + availableUnits).reduce((a, b) => a > b ? a : b);
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
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              buildingNames.length,
                  (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    fromY: 0,
                    toY: vacantUnits[index].toDouble(),
                    color: Colors.redAccent,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  BarChartRodData(
                    fromY: 0,
                    toY: availableUnits[index].toDouble(),
                    color: Colors.greenAccent,
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



