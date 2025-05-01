import 'dart:convert';

import 'package:cshrealestatemobile/AvailableUnitsReport.dart';
import 'package:cshrealestatemobile/ComplaintList.dart';
import 'package:cshrealestatemobile/KYCUpdate.dart';
import 'package:cshrealestatemobile/RequestList.dart';
import 'package:cshrealestatemobile/TenantProfile.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'dart:ui' as ui;
import 'MaintenanceTicketReport.dart';
import 'Sidebar.dart';
import 'package:google_fonts/google_fonts.dart';


class TenantDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TenantDashboardScreen(),
    );
  }
}

class TenantDashboardScreen extends StatefulWidget {
  @override
  _SalesDashboardScreenState createState() => _SalesDashboardScreenState();
}

class Cheque {
  final bool isReceived;
  final bool isDeposited;

  Cheque({required this.isReceived, required this.isDeposited});

  factory Cheque.fromJson(Map<String, dynamic> json) {
    return Cheque(
      isReceived: json['is_received'] == "true",
      isDeposited: json['is_deposited'] == "true",
    );
  }
}

class Invoice {
  final double amount;
  final String dueDate;

  Invoice({required this.amount, required this.dueDate});

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      amount: json['amount_incl']?.toDouble() ?? 0.0,
      dueDate: json['received_date'] ?? DateTime.now().toIso8601String(),
    );
  }
}


class _SalesDashboardScreenState extends State<TenantDashboardScreen> with TickerProviderStateMixin {

  final List<Map<String, String>> apartments = [
    {"apartment": "1 BHK", "building": "Al Khaleej Center"},
    {"apartment": "2 BHK", "building": "Musalla Tower"},
  ];

  // Data for each apartment's cheques
  final Map<String, Map<String, int>> chequeData = {

  };

  final Map<String, Map<String, double>> pendingInvoicesData = {

  };

  String? selectedApartment;

  // Current index for CupertinoPicker
  int selectedIndex = 0;

  Future<void> fetchTenantDashboardData() async {
    final url = Uri.parse("$baseurl/reports/tenant/cheques/$user_id"); // Replace with your actual endpoint
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $Company_Token", // Update this token accordingly
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)["data"]["tenant"];
      final chequesJson = List<Map<String, dynamic>>.from(data["cheques"]);

      List<Cheque> cheques = chequesJson.map((e) => Cheque.fromJson(e)).toList();
      List<Invoice> invoices = chequesJson.map((e) => Invoice.fromJson(e["payment"])).toList();

      int cleared = cheques.where((c) => c.isReceived).length;
      int pending = cheques.where((c) => !c.isReceived).length;

      final invoiceMap = <String, double>{};
      for (var invoice in invoices) {
        final month = invoice.dueDate.substring(0, 7);
        invoiceMap[month] = (invoiceMap[month] ?? 0) + invoice.amount;
      }

      setState(() {
        chequeData[selectedApartment!] = {
          "Cleared": cleared,
          "Pending": pending,
        };
        pendingInvoicesData[selectedApartment!] = invoiceMap;
      });
    } else {
      print("API Error: ${response.body}");
    }
  }


  List<Map<String, dynamic>> groupInvoicesByMonth(List<Invoice> invoices) {
    final grouped = <String, double>{};

    for (var invoice in invoices) {
      // Extract year and month from the dueDate
      final month = invoice.dueDate.substring(0, 7); // Format as YYYY-MM
      grouped[month] = (grouped[month] ?? 0) + invoice.amount;
    }

    return grouped.entries.map((e) {
      final parsedDate = DateTime.parse('${e.key}-01'); // Append '-01' to make it a valid date
      return {
        "month": parsedDate,
        "amount": e.value,
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    fetchTenantDashboardData();

  }

  double _getTextWidth(String text, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
        textDirection:  ui.TextDirection.ltr
    )..layout();
    return textPainter.size.width;
  }

  Future<void> _initSharedPreferences() async {

    /*setState(() {
      DateTime now = DateTime.now();  // Get the current date and time
      selectedYear = (now.year).toString();  // Store the year as a string
    });*/

    setState(() {
      selectedApartment = "${apartments[selectedIndex]['apartment']} (${apartments[selectedIndex]['building']})";
    });

  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
/* List<String> years = salesData.keys.toList();

    int initialYearIndex = years.indexOf(selectedYear ?? years.last);
*/

    final data = chequeData[selectedApartment]!;

    double maxWidth = 0.0;
    for (var apartment in apartments) {
      String text = "${apartment['apartment']} (${apartment['building']})";
      double textWidth = _getTextWidth(text, GoogleFonts.poppins(fontSize: 18.0));
      if (textWidth > maxWidth) {
        maxWidth = textWidth;
      }
    }

    // Add some padding to the width
    double containerWidth = maxWidth + 20.0;



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
                  MaterialPageRoute(builder: (context) => TenantProfile()), // Navigate to the profile screen
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
        title: Text('Tenant Dashboard',
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
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child:  Container(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Text(
                            'Cheque(s)',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          )
                          ,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 65,
                                width: containerWidth,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                                  itemExtent: 40,
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      selectedIndex = index;
                                      final selected = apartments[index];
                                      selectedApartment =
                                      "${selected['apartment']} (${selected['building']})";
                                    });
                                  },
                                  children: apartments
                                      .map((apartment) => Center(
                                    child: Text(
                                      "${apartment['apartment']} (${apartment['building']})",
                                      style: GoogleFonts.poppins(fontSize: 18.0,),
                                    ),
                                  ))
                                      .toList(),
                                ),
                              ),


                              Tooltip(
                                message: 'Scroll up/down to change unit',
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
                                                'Scroll up/down to change unit',
                                                style: GoogleFonts.poppins(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: appbar_color.shade700,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        action: SnackBarAction(
                                          label: 'Got it',
                                          textColor: Colors.lightGreenAccent,
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
                      ))),
              SizedBox(height: 20),
              // Pie Chart
              SizedBox(
                height: 275,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0, // Small gap between sections for better visual appeal
                    centerSpaceRadius: 0, // Space in the middle of the pie chart
                    sections: [
                      PieChartSectionData(
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent.shade100,Colors.blueAccent.shade200, Colors.blueAccent.shade200], // Gradient background
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),                        value: data["Cleared"]!.toDouble(),
                        title: 'Cleared\n${data["Cleared"]}',
                        radius: 140,
                        titleStyle: GoogleFonts.poppins(fontSize: 15.0, fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      PieChartSectionData(
                        gradient: LinearGradient(
                          colors: [Colors.orangeAccent.shade100,Colors.orangeAccent.shade200, Colors.orangeAccent.shade200], // Gradient background
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        value: data["Pending"]!.toDouble(),
                        title: 'Pending\n${data["Pending"]}',
                        radius: 140,
                        titleStyle: GoogleFonts.poppins(fontSize: 15.0, fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.only(left:0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pending Invoices",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: ApartmentBarChart(
                          selectedApartment: selectedApartment!,
                          pendingInvoicesData: pendingInvoicesData,
                        ),
                      ),

                    )


                  ],
                ),
              ),
              SizedBox(height: 20),


              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push
                          (
                          context,
                          MaterialPageRoute(builder: (context) => MaintenanceTicketReport()), // navigate to company and serial select screen
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

                              Icon(
                                Icons.home_repair_service,
                                color: Colors.white,
                              ),

                              SizedBox(height: 5,),
                              Text(
                                'Maintenance',
                                style: GoogleFonts.poppins(fontSize: 16,
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
                                              MaterialPageRoute(builder: (context) => TenantmoveinoutRequest()),          // navigate to users screen
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
                                                          Icons.transfer_within_a_station_outlined,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(height: 10),
                                                        Text(
                                                            'Move In/Out Request',
                                                            textAlign: TextAlign.center,
                                                            style: GoogleFonts.poppins(
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white,
                                                              letterSpacing: 0.8,
                                                            ))]))))),

                                  SizedBox(width: 10),
                                  // Second Button
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => TenantAccessCardRequest()),          // navigate to users screen
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
                                                          Icons.refresh,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(height: 10),
                                                        Text(
                                                            'Access Card Replacement Request',
                                                            textAlign: TextAlign.center,
                                                            style: GoogleFonts.poppins(
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white,
                                                              letterSpacing: 0.8,
                                                            ))])))))])),

                        SizedBox(height: 10),

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
                                                        ))])))))]),

                        SizedBox(height: 10,),

                        IntrinsicHeight(child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement
                                      (
                                      context,
                                      MaterialPageRoute(builder: (context) => DecentTenantKYCForm()), // navigate to company and serial select screen
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.upload_file,
                                            color: Colors.white,
                                          ),

                                          SizedBox(height: 10,),
                                          Text(
                                            'KYC Update',
                                            style: GoogleFonts.poppins(fontSize: 16,
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
                                      onPressed: () {
                                        Navigator.pushReplacement
                                          (
                                          context,
                                          MaterialPageRoute(builder: (context) => TenantComplaint()), // navigate to company and serial select screen
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
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    Icons.info_outline,
                                                    color: Colors.white
                                                ),
                                                SizedBox(height: 10,),
                                                Text(
                                                  'Complaints/Suggestions',
                                                  style: GoogleFonts.poppins(fontSize: 16,
                                                      color: Colors.white),
                                                )
                                              ]
                                          )
                                      )
                                  )
                              )
                            ]
                        ))
                      ]
                  )
              ),


              SizedBox(height: 30),

              // Sales Bar Chart
              *//*Row(
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
                                backgroundColor: appbar_color.shade500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                action: SnackBarAction(
                                  label: 'Got it',
                                  textColor: Colors.lightGreenAccent,
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

              SizedBox(height: 50,),*//*


              *//* Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width,
                child: SalesBarChart(salesData: salesData, selectedYear: selectedYear!),
              ),*//*

            ],
          ),
        ),
      ),
    );*/

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
                  MaterialPageRoute(builder: (context) => TenantProfile()), // Navigate to the profile screen
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
      drawer: Sidebar(  isDashEnable: true,
        isRolesVisible: true,
        isRolesEnable: true,
        isUserEnable: true,
        isUserVisible: true,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              height: 80,
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
                            width: containerWidth,
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                              itemExtent: 40,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedIndex = index;
                                  final selected = apartments[index];
                                  selectedApartment =
                                  "${selected['apartment']} (${selected['building']})";
                                });
                              },
                              children: apartments
                                  .map((apartment) => Center(
                                child: Text(
                                  "${apartment['apartment']} (${apartment['building']})",
                                  style: GoogleFonts.poppins(fontSize: 18.0,),
                                ),
                              ))
                                  .toList(),
                            ),
                          ),


                          Tooltip(
                            message: 'Scroll up/down to change unit',
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
                                            'Scroll up/down to change unit',
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
            // Pie Chart

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cheque(s)',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0, // Small gap between sections for better visual appeal
                        centerSpaceRadius: 0, // Space in the middle of the pie chart
                        sections: [
                          PieChartSectionData(
                            gradient: LinearGradient(
                              colors: [Colors.blueAccent.shade100,Colors.blueAccent.shade200, Colors.blueAccent.shade200], // Gradient background
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            value: data["Cleared"]!.toDouble(),
                            title: 'Cleared\n${data["Cleared"]}',
                            radius: 110,
                            titleStyle: GoogleFonts.poppins(fontSize: 15.0, fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          PieChartSectionData(
                            gradient: LinearGradient(
                              colors: [Colors.orangeAccent.shade100,Colors.orangeAccent.shade200, Colors.orangeAccent.shade200], // Gradient background
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            value: data["Pending"]!.toDouble(),
                            title: 'Pending\n${data["Pending"]}',
                            radius: 110,
                            titleStyle: GoogleFonts.poppins(fontSize: 15.0, fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),

            // Pending Invoices Bar Chart
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Invoices',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      child: Center(
                        child: ApartmentBarChart(
                          selectedApartment: selectedApartment!,
                          pendingInvoicesData: pendingInvoicesData,
                        ),
                      ),
                    )
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                _buildDashboardButton(Icons.build, 'Maintenance', appbar_color, () {
                  Navigator.push
                    (
                    context,
                    MaterialPageRoute(builder: (context) => MaintenanceTicketReport()), // navigate to company and serial select screen
                  );
                }),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDashboardButton(Icons.credit_card, 'Request', Colors.purpleAccent, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RequestListScreen()),          // navigate to users screen
                  );
                }),
                _buildDashboardButton(Icons.home, 'Available Units', Colors.orangeAccent, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AvailableUnitsReport()),          // navigate to users screen
                  );
                }),
              ],
            ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDashboardButton(Icons.upload_file, 'KYC Update', Colors.tealAccent, () {
                Navigator.pushReplacement
                  (
                  context,
                  MaterialPageRoute(builder: (context) => DecentTenantKYCForm()), // navigate to company and serial select screen
                );
              }),
              _buildDashboardButton(Icons.info_outline, 'Complaints/Suggestions', Colors.redAccent, () {

                Navigator.pushReplacement
                  (
                  context,
                  MaterialPageRoute(builder: (context) => ComplaintListScreen()), // navigate to company and serial select screen
                );
              }),
            ],
          ),


            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          height: 90,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/*class SalesBarChart extends StatelessWidget {
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
                        colors: [appbar_color.withOpacity(0.1), appbar_color.withOpacity(0.5)], // Gradient background
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
                  reservedSize: _getReservedSize(salesData[selectedYear]?.values?.toList() ?? []),
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
}*/

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
double _getTextHeight(String text) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: GoogleFonts.poppins(fontSize: 12)),
    textDirection:  ui.TextDirection.ltr
    , // This should work now
  );
  textPainter.layout();
  return textPainter.size.height; // Return the height of the text
}

class ApartmentBarChart extends StatelessWidget {
  final String selectedApartment;
  final Map<String, Map<String, double>> pendingInvoicesData;

  ApartmentBarChart({
    required this.selectedApartment,
    required this.pendingInvoicesData,
  });

  @override
  Widget build(BuildContext context) {
    // Fetch data for the selected apartment
    final apartmentInvoiceData =
        pendingInvoicesData[selectedApartment] ?? {};

    // Extract months and amounts
    List<String> months = apartmentInvoiceData.keys.toList();
    List<double> amounts = apartmentInvoiceData.values.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.only(top: 15,bottom: 15),
        width: MediaQuery.of(context).size.width-20,
        child: BarChart(
          BarChartData(
            barGroups: [
              for (int i = 0; i < months.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: amounts[i],
                      width: 40,
                      gradient: LinearGradient(
                        colors: [appbar_color.withOpacity(0.6), appbar_color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                    // Display corresponding month
                    if (value.toInt() < months.length) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          months[value.toInt()],
                          style:  GoogleFonts.poppins(fontSize: 10),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 20,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    String formattedValue = value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}K'
                        : value.toStringAsFixed(0);
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        formattedValue,
                        style:  GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  },
                  reservedSize: 45.0,
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.spaceEvenly,
          ),
        ),
      ),
    );
  }
}


