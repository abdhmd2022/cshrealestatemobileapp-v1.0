import 'package:cshrealestatemobile/AvailableUnitsReport.dart';
import 'package:cshrealestatemobile/AnalyticsReport.dart';
import 'package:cshrealestatemobile/MaintenanceTicketReport.dart';
import 'package:cshrealestatemobile/SalesProfile.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'SalesInquiryReport.dart';
import 'Sidebar.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AdminDashboardScreen(),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {

  String? selectedYear;
  Map<String, Map<String, int>> salesData = {
    "2024": {
      "Jan": 1000,
      "Feb": 2000,
      "Mar": 1500,
      "Apr": 3000,
      "May": 2500,
      "Jun": 1800,
      "Jul": 2200,
      "Aug": 1900,
      "Sep": 2100,
      "Oct": 2300,
      "Nov": 2400,
      "Dec": 2500,
    },
    "2023": {
      "Jan": 1200,
      "Feb": 1800,
      "Mar": 2200,
      "Apr": 2500,
      "May": 1900,
      "Jun": 1600,
      "Jul": 2100,
      "Aug": 2000,
      "Sep": 1800,
      "Oct": 2300,
      "Nov": 2400,
      "Dec": 2500,
    },
    "2022": {
      "Jan": 1100,
      "Feb": 2100,
      "Mar": 2300,
      "Apr": 2700,
      "May": 2900,
      "Jun": 1800,
      "Jul": 2400,
      "Aug": 2000,
      "Sep": 1500,
      "Oct": 2200,
      "Nov": 2100,
      "Dec": 2500,
    },
    "2021": {
      "Jan": 5100,
      "Feb": 6200,
      "Mar": 7300,
      "Apr": 8400,
      "May": 9500,
      "Jun": 10600,
      "Jul": 11700,
      "Aug": 12800,
      "Sep": 13900,
      "Oct": 15000,
      "Nov": 15000,
      "Dec": 8000,
    }
  };

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {

    setState(() {
      DateTime now = DateTime.now();  // Get the current date and time
      selectedYear = (now.year).toString();  // Store the year as a string
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    List<String> years = salesData.keys.toList();

    int initialYearIndex = years.indexOf(selectedYear ?? years.last);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        elevation: 1,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SalesProfileScreen()), // Navigate to the profile screen
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [appbar_color.shade200, appbar_color.shade700],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Sidebar(
        isDashEnable: true,
        isRolesVisible: true,
        isRolesEnable: true,
        isUserEnable: true,
        isUserVisible: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left:16.0,right:16,bottom:16,top:10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 70,
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
              child:  // Section Title
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child:  Container(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 65,
                            width: 150,
                            child: CupertinoPicker(
                              itemExtent: 32,
                              scrollController: FixedExtentScrollController(initialItem: initialYearIndex),  // Set initial scroll position

                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedYear = years[index]; // Update selected year based on index
                                });
                              },
                              children: years
                                  .map((year) => Center(child: Text(year, style: GoogleFonts.poppins(fontSize: 16))))
                                  .toList(),
                            ),
                          ),
                          Tooltip(
                            message: 'Scroll up/down to change year',
                            child: IconButton(
                              icon: Icon(Icons.info_outline),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.info, color: Colors.white),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Scroll up/down to change year',
                                            style: GoogleFonts.poppins(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.grey,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    action: SnackBarAction(
                                      label: 'Got it',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        // Optional: Add action logic
                                      },
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ))),
            ),

            SizedBox(height: 10),

            Container(
              height: 275,
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
              padding: EdgeInsets.all(16),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width,
                child:

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Sales',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: SalesBarChart(salesData: salesData, selectedYear: selectedYear!),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            /*Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDashboardButton(Icons.show_chart, 'In Progress', '12', appbar_color, () {}),
                _buildDashboardButton(Icons.check_circle_outline, 'Closed', '8', appbar_color, () {}),
              ],
            ),

            SizedBox(height: 10),*/


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDashboardButton(Icons.inbox, 'Inquiries', '', Colors.purpleAccent, () {
                  Navigator.pushReplacement(
                    context,

                    MaterialPageRoute(builder: (context) => SalesInquiryReport()),          // navigate to users screen
                  );
                }),


              ],
            ),

            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                _buildDashboardButton(Icons.analytics_outlined, 'Analytics', '', Colors.redAccent, () {

                  Navigator.pushReplacement(
                    context,

                    MaterialPageRoute(builder: (context) => LandlordDashboardScreen()),          // navigate to users screen
                  );


                }),

              ],
            ),

            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDashboardButton(Icons.build, 'Maintenance', '', appbar_color, () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(builder: (context) => MaintenanceTicketReport()),          // navigate to users screen
                  );
                }),
                _buildDashboardButton(Icons.home, 'Available Units', '', Colors.orangeAccent, () {
                  Navigator.pushReplacement(
                    context,

                    MaterialPageRoute(builder: (context) => AvailableUnitsReport()),          // navigate to users screen
                  );
                }),              ],
            ),



          ],
        ),
      ),
    );

    /*return Scaffold(
    key: _scaffoldKey,
    backgroundColor: const Color(0xFFF2F4F8),
    appBar: AppBar(
      backgroundColor: appbar_color.withOpacity(0.9),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SalesProfileScreen()), // Navigate to the profile screen
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [appbar_color.shade200, appbar_color.shade700],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      title: Text('Sales Dashboard',
          style: GoogleFonts.poppins(color: Colors.white)),
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

    ),
    body: SingleChildScrollView(
        child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sales Bar Chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Sales',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      )
                      ,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [



                          Container(
                            height: 40,
                            width: 120,
                            child: CupertinoPicker(
                              itemExtent: 32,
                              scrollController: FixedExtentScrollController(initialItem: initialYearIndex),  // Set initial scroll position

                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedYear = years[index]; // Update selected year based on index
                                });
                              },
                              children: years
                                  .map((year) => Center(child: Text(year, style: GoogleFonts.poppins(fontSize: 16))))
                                  .toList(),
                            ),
                          ),


                          Tooltip(
                            message: 'Scroll up/down to change year',
                            child: IconButton(
                              icon: Icon(Icons.info_outline),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.info, color: Colors.white),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Scroll up/down to change year',
                                            style: GoogleFonts.poppins(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.redAccent.withOpacity(1.0),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    action: SnackBarAction(
                                      label: 'Got it',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        // Optional: Add action logic
                                      },
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 50,),

                  Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: MediaQuery.of(context).size.width,
                    child: SalesBarChart(salesData: salesData, selectedYear: selectedYear!),
                  ),

                  SizedBox(height: 50,),

                  // In-Progress and Closed Leads Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(

                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero, // Remove padding from button to ensure container fills the space
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), // Rounded corners for the button
                            ),
                            backgroundColor: Colors.transparent, // Transparent background to allow the container to show
                            shadowColor: Colors.black.withOpacity(0.2), // Soft shadow for depth
                            elevation: 5, // Moderate elevation for a subtle 3D effect
                          ),
                          child: Container(
                              alignment: Alignment.center, // Center the content inside the container
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [appbar_color.withOpacity(0.6), appbar_color.withOpacity(0.8)], // Gradient background
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(16), // Consistent rounded corners
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'In Progress',
                                    style: GoogleFonts.poppins(fontSize: 16,
                                        color: Colors.white),
                                  ),
                                  SizedBox(height: 2,),
                                  Text(
                                    '12', // Example count
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              )
                          ),
                        ),

                      ),
                      SizedBox(width: 10),
                      Expanded(



                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero, // Remove padding from button to ensure container fills the space
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), // Rounded corners for the button
                            ),
                            backgroundColor: Colors.transparent, // Transparent background to allow the container to show
                            shadowColor: Colors.black.withOpacity(0.2), // Soft shadow for depth
                            elevation: 5, // Moderate elevation for a subtle 3D effect
                          ),
                          child: Container(
                              alignment: Alignment.center, // Center the content inside the container
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [appbar_color.withOpacity(0.6), appbar_color.withOpacity(0.8)], // Gradient background
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(16), // Consistent rounded corners
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Closed',
                                    style: GoogleFonts.poppins(fontSize: 16,
                                        color: Colors.white),
                                  ),
                                  SizedBox(height: 2,),
                                  Text(
                                    '8', // Example count
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              )
                          ),
                        ),

                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Other Buttons
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // First Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {

                                    Navigator.pushReplacement(
                                      context,

                                      MaterialPageRoute(builder: (context) => SalesInquiryReport()),          // navigate to users screen
                                    );


                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero, // Remove padding from button to ensure container fills the space
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16), // Rounded corners for the button
                                    ),
                                    backgroundColor: Colors.transparent, // Transparent background to allow the container to show
                                    shadowColor: Colors.black.withOpacity(0.2), // Soft shadow for depth
                                    elevation: 5, // Moderate elevation for a subtle 3D effect
                                  ),

                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    width: double.infinity, // Ensure container fills the button space
                                    height: double.infinity, // Ensure container fills the button space
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [appbar_color.withOpacity(0.6), appbar_color.withOpacity(0.8)], // Gradient background
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(16), // Consistent rounded corners
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.inbox,
                                            color: Colors.white,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Inquiries',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 10),

                              // Third Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.all(0), // Remove padding for full gradient coverage
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: Colors.transparent, // Transparent background
                                    shadowColor: Colors.black.withOpacity(0.2),
                                    elevation: 5,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [appbar_color.withOpacity(0.6), appbar_color.withOpacity(0.8)], // Gradient background
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(16), // Consistent rounded corners
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.account_balance_wallet,
                                            color: Colors.white,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Outstanding',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10),

                        // Fourth Button
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {

                                  Navigator.pushReplacement(
                                    context,

                                    MaterialPageRoute(builder: (context) => AvailableUnitsReport()),          // navigate to users screen
                                  );

                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.all(0), // Remove padding for full gradient coverage
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.transparent, // Transparent background
                                  shadowColor: Colors.black.withOpacity(0.2),
                                  elevation: 5,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [appbar_color.withOpacity(0.6), appbar_color.withOpacity(0.8)], // Gradient background
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16), // Consistent rounded corners
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.home,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Available Units',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 50,),

                ]))));*/
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

}

class SalesBarChart extends StatelessWidget {
  final Map<String, Map<String, int>> salesData;
  final String selectedYear;

  SalesBarChart({required this.salesData, required this.selectedYear});

  @override
  Widget build(BuildContext context) {
    Map<String, int> yearData = salesData[selectedYear] ?? {};

    // Generate months dynamically from the sales data
    List<String> months = yearData.keys.toList();
    List<int> sales = yearData.values.toList();

    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculate the width of the chart based on the number of months
    double chartWidth = months.length * 65.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.only(top: 5),
        width: chartWidth > screenWidth ? chartWidth : screenWidth, // Adjust width based on screen size
        child: BarChart(
          BarChartData(
            barGroups: [
              for (int i = 0; i < months.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: sales[i].toDouble(), // Use sales data dynamically
                      width: 40,
                      gradient: LinearGradient(
                        colors: [appbar_color.withOpacity(0.6), appbar_color.withOpacity(0.8)], // Gradient background
                        begin: Alignment.topLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _getFormattedMonth(value.toInt(), selectedYear), // Use formatted month names from data
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 20,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    double salesValue = value;
                    String formattedValue = salesValue >= 1000
                        ? '${(salesValue / 1000).toStringAsFixed(1)}K'
                        : salesValue.toStringAsFixed(0);

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        formattedValue,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  },
                  reservedSize: _getReservedSize(salesData[selectedYear]?.values.toList() ?? []),
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            
            borderData: FlBorderData(show: false, border: Border.all(color: Colors.black, width: 1)),
            alignment: BarChartAlignment.spaceEvenly,
          ),
        ),
      ),
    );
  }

  String _getFormattedMonth(int index, String year) {
    String month = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][index];
    return "$month-${year.substring(2)}"; // Format as 'MMM-yy'
  }
}

double _getReservedSize(List<int> salesValues) {
  if (salesValues.isEmpty) return 40; // Default size if there are no sales values
  int maxSales = salesValues.reduce((a, b) => a > b ? a : b); // Find the maximum sales value

  // Dynamically adjust reserved space vertically based on max sales value
  if (maxSales >= 10000) {
    return 45.0; // More space for larger numbers
  } else if (maxSales >= 1500) {
    return 40.0; // Moderate space for medium sales values
  } else {
    return 30.0; // Default space for small sales values
  }
}
