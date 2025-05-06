import 'dart:convert';
import 'dart:io';

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
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ChequeListScreen.dart';
import 'SalesInquiryReport.dart';
import 'Sidebar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;


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

  List<dynamic> cheques = [];
  bool isLoading = true;
  DateTimeRange? selectedRange;

  int returned = 0;
  int received = 0;
  int pending = 0;
  int cleared = 0;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {

     prefs = await SharedPreferences.getInstance();
     String? startDateString = prefs.getString("startdate");
     String? endDateString = prefs.getString("enddate");

     DateTime now = DateTime.now();

     if (startDateString != null && endDateString != null) {
       selectedRange = DateTimeRange(
         start: DateTime.parse(startDateString),
         end: DateTime.parse(endDateString),
       );
     } else {
       selectedRange = DateTimeRange(
         start: DateTime(now.year, now.month, 1),
         end: now,
       );
     }

     prefs.setString("startdate", selectedRange!.start.toIso8601String());
     prefs.setString("enddate", selectedRange!.end.toIso8601String());

     print('start date -> ${selectedRange!.start..toIso8601String()}');
     print('end date -> ${selectedRange!.end.toIso8601String()}');


     await fetchChequeData(); // make sure cheques are loaded
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: appbar_color,           // start & end circle
              onPrimary: Colors.white,         // text on primary (start/end date)
              secondary: appbar_color.withOpacity(0.5),         // range fill color
              onSecondary: Colors.white,       // text color inside range
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: appbar_color, // Save / Cancel buttons
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedRange = picked;

      print('range -> $selectedRange');
      prefs.setString("startdate", selectedRange!.start.toString());
      prefs.setString("enddate", selectedRange!.end.toString());
      await fetchChequeData();
    }
  }

  String _formatRange(DateTimeRange range) {
    final now = DateTime.now();
    final currentYear = now.year;

    final start = range.start;
    final end = range.end;

    final sameYear = start.year == end.year;

    if (sameYear && start.year == currentYear) {
      // Same year and current year
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}';
    } else {
      // Either different years or same year but not current year
      return '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
    }
  }

  void _updateStatusCounts() {
    returned = 0;
    received = 0;
    pending = 0;
    cleared = 0;

    for (var cheque in cheques) {
      final payment = cheque['payment'];
      if (payment == null) continue;

      DateTime? returnedOn = _parseDate(payment['returned_on']);
      DateTime? receivedOn = _parseDate(cheque['received_on']);
      DateTime? depositedOn = _parseDate(cheque['deposited_on']);
      DateTime? chequeDate = _parseDate(cheque['date']);

      final isReceived = cheque['is_received'].toString().toLowerCase() == 'true';
      final isDeposited = cheque['is_deposited'].toString().toLowerCase() == 'true';

      bool counted = false;

      // Returned cheque in range
      if (returnedOn != null &&
          !returnedOn.isBefore(selectedRange!.start) &&
          !returnedOn.isAfter(selectedRange!.end)) {
        returned++;
        counted = true;
      }
      // Received but not deposited in range
      else if (isReceived && !isDeposited &&
          receivedOn != null &&
          !receivedOn.isBefore(selectedRange!.start) &&
          !receivedOn.isAfter(selectedRange!.end)) {
        received++;
        counted = true;
      }
      // Received and deposited in range
      else if (isReceived && isDeposited &&
          depositedOn != null &&
          !depositedOn.isBefore(selectedRange!.start) &&
          !depositedOn.isAfter(selectedRange!.end)) {
        cleared++;
        counted = true;
      }

      // If not counted in any above, check if cheque date falls in range to consider as pending
      if (!counted &&
          chequeDate != null &&
          !chequeDate.isBefore(selectedRange!.start) &&
          !chequeDate.isAfter(selectedRange!.end)) {
        pending++;
      }
    }

    print('--- Cheque Status Counts ---');
    print('Returned: $returned');
    print('Received: $received');
    print('Pending: $pending');
    print('Cleared: $cleared');
    print('----------------------------');

    setState(() {});
  }

  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr.toString());
  }

  Future<void> fetchChequeData() async {
    setState(() {
      cheques.clear();
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$baseurl/tenant/cheque'),
        headers: {
          "Authorization": "Bearer $Company_Token",
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // Update cheques and trigger status count update in same state block
        setState(() {
          cheques = json['data']['cheques'];
          isLoading = false;
        });

        _updateStatusCounts(); // call for statuses update

      } else {
        print('Failed to load: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {

    final List<BarChartGroupData> visibleBars = [];
    final List<String> labels = [];
    int index = 0;

    void addBarIfCountPositive(int count, String label, Color startColor, Color endColor) {
      if (count > 0) {
        visibleBars.add(
          BarChartGroupData(x: index, barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              width: 40,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [startColor, endColor],
              ),
              borderRadius: BorderRadius.circular(12),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: count.toDouble(),
                color: startColor.withOpacity(0.1),
              ),
            )
          ]),
        );
        labels.add(label);
        index++; // Increase index for each valid bar
      }
    }

    // Use this to build your bars
    addBarIfCountPositive(returned, "Returned", Colors.red.shade300, Colors.red.shade700);
    addBarIfCountPositive(received, "Received", Colors.green.shade400, Colors.green.shade700);
    addBarIfCountPositive(pending, "Pending", Colors.orangeAccent.shade200, Colors.deepOrange.shade400);
    addBarIfCountPositive(cleared, "Cleared", appbar_color.shade100, appbar_color.shade400);

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

            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChequeListScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 330,
                margin: EdgeInsets.only(left: 8, right: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Date Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Cheque Status",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 10),
                        Flexible( // Allows the right side to shrink as needed
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: InkWell(
                              onTap: _pickDateRange,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: appbar_color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.date_range, size: 18, color: appbar_color),
                                    SizedBox(width: 6),
                                    selectedRange != null
                                        ? Text(
                                      _formatRange(selectedRange!),
                                      style: GoogleFonts.poppins(fontSize: 12, color: appbar_color.shade700),
                                    )
                                        : CircularProgressIndicator(), // or SizedBox(), or any fallback widget
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),


                    SizedBox(height: 26),
                    // Bar Chart

                    Expanded(
                      child:  isLoading
                          ? Center(child:  Platform.isIOS
                          ? const CupertinoActivityIndicator(radius: 18)
                          : CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
                      ),)
                          : (returned == 0 && received == 0 && pending == 0 && cleared == 0)
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "All cheques (Returned, Received, Pending and Cleared) are 0 for the selected period.\nPlease choose a different date range to view activity.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      )
                          : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width-80,
                          child: BarChart(
                            BarChartData(
                              barGroups: visibleBars,
                              maxY: [returned, received, pending, cleared].reduce((a, b) => a > b ? a : b).toDouble(),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 12.0,left: 10,right:10),
                                        child: Text(
                                          labels[value.toInt()],
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                      );
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) => SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 4,
                                      child: Text(
                                        value.toInt().toString(),
                                        style: GoogleFonts.poppins(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) => SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 4,
                                      child: Text(
                                        value.toInt().toString(),
                                        style: GoogleFonts.poppins(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(show: true, drawVerticalLine: false),
                              borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                                  if (event is FlTapUpEvent && response != null && response.spot != null) {
                                    // final tappedIndex = response.spot!.touchedBarGroupIndex;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChequeListScreen(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDashboardButton(Icons.inbox, 'Inquiries', '', Colors.purpleAccent, () {
                  Navigator.pushReplacement(
                    context,

                    MaterialPageRoute(builder: (context) => SalesInquiryReport()),          // navigate to users screen
                  );
                }),

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

Widget _legend(String title, Color color) {
  return Row(
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
      SizedBox(width: 6),
      Text(title, style: GoogleFonts.poppins(fontSize: 12)),
    ],
  );
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
                  reservedSize: 30,
                  interval: 1, // Only show titles at step = 1
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0) return const SizedBox(); // Skip non-integers
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                    );
                  },
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


