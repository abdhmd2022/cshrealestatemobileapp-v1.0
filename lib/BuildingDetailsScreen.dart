import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/BuildingsScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class BuildingReportScreen extends StatefulWidget {
  final dynamic building;

  BuildingReportScreen({required this.building});

  @override
  _BuildingReportScreenState createState() => _BuildingReportScreenState();
}
class _BuildingReportScreenState extends State<BuildingReportScreen> {

  bool showPieChart = true; // toggle state

  int? loadingTileIndex;
  String selectedFilter = 'All'; // Options: 'All', 'Occupied', 'Available'


  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openMaps() async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.building['name'])}";
    final String appleMapsUrl =
        "https://maps.apple.com/?q=${Uri.encodeComponent(widget.building['name'])}";
    final String wazeUrl =
        "waze://?q=${Uri.encodeComponent(widget.building['name'])}"; // Waze URL scheme

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
    final building = widget.building;
    final int occupied = building['flats']
        .where((f) => f['is_occupied'] == 'true')
        .length;
    final int available = building['flats']
        .where((f) => f['is_occupied'] == 'false')
        .length;
    final filteredFlats = widget.building['flats'].where((f) {
      if (selectedFilter == 'All') return true;
      if (selectedFilter == 'Occupied') return f['is_occupied'] == 'true';
      if (selectedFilter == 'Available') return f['is_occupied'] == 'false';
      return true;
    }).toList();

    final completionDate = DateTime.tryParse(building['completion_date'] ?? '');
    final formattedDate = completionDate != null
        ? DateFormat('dd-MMM-yy').format(completionDate)
        : 'N/A';
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        title: Text(building['name'],
            style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
        leading: GestureDetector(
          onTap: ()
          {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BuildingsScreen()),
            );
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),
      ),
      body: Container(
          color: Colors.white,
          height: MediaQuery.of(context).size.height,
          child:Stack(
              children:[
                SingleChildScrollView(child:
                Container(
                  padding: EdgeInsets.all(16),
                    color: Colors.white,

                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
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
                    padding: EdgeInsets.only(top: 5,bottom: 5,left: 15,right: 15),
                    child:                       Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              avatar: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: building['status'] == 'Open' ? Colors.green : Colors.red,
                              ),
                              label: Text(
                                "${building['status']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: building['status'] == 'Open' ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                              backgroundColor: building['status'] == 'Open'
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: building['status'] == 'Open' ? Colors.green : Colors.red,
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),

                            // Completion Date Chip
                            Chip(
                              avatar: Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: appbar_color,
                              ),
                              label: Text(
                                'Completed: $formattedDate',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: appbar_color.shade700,
                                ),
                              ),
                              backgroundColor: appbar_color.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: appbar_color, width: 1),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  Stack(
                    children: [
                      // Main chart container
                      Container(
                        height: 315,
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
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: Duration(milliseconds: 600),
                                  switchInCurve: Curves.easeOutExpo,
                                  switchOutCurve: Curves.easeInExpo,
                                  transitionBuilder: (child, animation) {
                                    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);
                                    final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(animation);
                                    final slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(animation);

                                    return FadeTransition(
                                      opacity: fadeAnimation,
                                      child: SlideTransition(
                                        position: slideAnimation,
                                        child: ScaleTransition(
                                          scale: scaleAnimation,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: showPieChart
                                      ? PieChartGraph(
                                    key: ValueKey('pie'),
                                    occupied: occupied,
                                    available: available,
                                    buildingName: building['name'],
                                    onSectionTap: (type) {
                                      setState(() {
                                        selectedFilter = (selectedFilter == type) ? 'All' : type;
                                      });
                                    },
                                  )
                                      : BarChartGraph(
                                    key: ValueKey('bar'),
                                    occupied: occupied,
                                    available: available,
                                    buildingName: building['name'],
                                    onBarTap: (type) {
                                      setState(() {
                                        selectedFilter = (selectedFilter == type) ? 'All' : type;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              SizedBox(height: 10),
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

                      // Positioned toggle button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showPieChart = !showPieChart;
                              });
                            },
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) =>
                                  RotationTransition(turns: animation, child: child),
                              child: Icon(
                                showPieChart ? Icons.pie_chart : Icons.bar_chart,
                                key: ValueKey(showPieChart),
                                color: appbar_color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10,),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredFlats.length,


                    itemBuilder: (context, index) {

                      final flat = filteredFlats[index];

                      final flat_id = flat['id'];
                      final isOccupied = flat['is_occupied'] == 'true';
                      final flatName = flat['name'] ?? 'N/A';
                      final flatType = flat['flat_type']?['name'] ?? 'N/A';
                      final isLoading = loadingTileIndex == index;

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () async {
                            setState(() {
                              loadingTileIndex = index;
                            });

                            final response = await http.get(
                              Uri.parse('$baseurl/master/flat/$flat_id'),
                              headers: {
                                "Authorization": "Bearer $Company_Token",
                                "Content-Type": "application/json",
                              },
                            );
                            final data = json.decode(response.body);

                            setState(() {
                              loadingTileIndex = null;
                            });

                            if (response.statusCode == 200) {
                              final flat = data['data']['flat'];

                              final unitno = flat['name'] ?? 'N/A';
                              final buildingName = flat['building']?['name'] ?? 'N/A';
                              final area = flat['building']?['area']?['name'] ?? 'N/A';
                              final emirate = flat['building']?['area']?['state']?['name'] ?? 'N/A';
                              final unittype = flat['flat_type']?['name'] ?? 'N/A';
                              final rent = (flat['basic_rent']?.toString() ?? '0') + ' AED';
                              final parking = flat['no_of_parkings']?.toString() ?? 'N/A';
                              final balcony = 'N/A';
                              final bathrooms = flat['no_of_bathrooms']?.toString() ?? 'N/A';
                              final ownership = flat['ownership'] ?? 'N/A';
                              final basicRent = flat['basic_rent']?.toString() ?? 'N/A';
                              final basicSaleValue = flat['basic_sale_value']?.toString() ?? 'N/A';
                              final isExempt = flat['is_exempt'] ?? 'false';
                              final amenities = (flat['amenities'] as List)
                                  .map<String>((a) => a['amenity']['name'].toString())
                                  .toList();

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AvailableUnitsDialog(
                                    unitno: unitno,
                                    area: area,
                                    building_name: buildingName,
                                    emirate: emirate,
                                    unittype: unittype,
                                    rent: rent,
                                    parking: parking,
                                    balcony: balcony,
                                    bathrooms: bathrooms,
                                    ownership: ownership,
                                    basicRent: basicRent,
                                    basicSaleValue: basicSaleValue,
                                    isExempt: isExempt,
                                    amenities: amenities,
                                  );
                                },
                              );
                            } else {
                              final errorMessage = data['message'] ?? 'Unknown error occurred';
                              showErrorSnackbar(context, errorMessage);
                            }
                          },
                          child: isLoading
                              ? ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              subtitle: Center(
                                child: Platform.isIOS
                                    ? const CupertinoActivityIndicator(radius: 18)
                                    : CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
                                ),

                              )
                          )
                              : ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOccupied ? Colors.orange.shade100 : appbar_color.withOpacity(0.2),
                              ),
                              child: Icon(
                                isOccupied ? Icons.home_work_rounded : Icons.home_outlined,
                                color: isOccupied ? Colors.orange : appbar_color,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              'Unit $flatName',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Type: $flatType ',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOccupied ? Colors.orange.shade50 : appbar_color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isOccupied ? 'Occupied' : 'Available',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isOccupied ? Colors.orange : appbar_color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
          ),
                  ),

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
      ),

    );
  }
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

class PieChartGraph extends StatelessWidget {
  final int occupied;
  final int available;
  final String buildingName;
  final Key? key; // <-- ADD THIS

  final Function(String type)? onSectionTap;
  PieChartGraph({
    this.key,
    required this.occupied,
    required this.available,
    required this.buildingName,
    this.onSectionTap,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 235,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 0,
              sectionsSpace: 0,
              sections: [
                PieChartSectionData(
                  value: occupied.toDouble(),
                  title: "$occupied Unit(s)",
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent.shade100,Colors.orangeAccent.shade200, Colors.orangeAccent.shade200], // Gradient background
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  radius: 120,

                ),
                PieChartSectionData(
                  value: available.toDouble(),
                  title: "$available Unit(s)",
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent.shade100,Colors.blueAccent.shade200, Colors.blueAccent.shade200], // Gradient background
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  radius: 120,
                ),
              ],

              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (response?.touchedSection != null && onSectionTap != null) {
                    final index = response!.touchedSection!.touchedSectionIndex;
                    onSectionTap!(index == 0 ? 'Occupied' : 'Available');
                  }
                },
              ),
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
        Text(text, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }
}
class BarChartGraph extends StatelessWidget {
  final int occupied;
  final int available;
  final String buildingName;
  final Key? key; // <-- ADD THIS

  final Function(String type)? onBarTap; // ✅ Add this line

  BarChartGraph({
    this.key,
    required this.occupied,
    required this.available,
    required this.buildingName,
    this.onBarTap, // ✅ Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 275,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.center,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return SizedBox.shrink();
                  return Text(value.toInt().toString());
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('');
                    case 1:
                      return Text('');
                    default:
                      return Text('');
                  }
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              if (response != null && response.spot != null && onBarTap != null) {
                final tappedIndex = response.spot!.touchedBarGroupIndex;
                if (tappedIndex == 0) {
                  onBarTap!("Occupied");
                } else if (tappedIndex == 1) {
                  onBarTap!("Available");
                }

              }
            },
          ),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: occupied.toDouble(),
                  width: 40,
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent.shade100,Colors.orangeAccent.shade200, Colors.orangeAccent.shade200], // Gradient background
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: available.toDouble(),
                  width: 40,
                  gradient: LinearGradient(
                    colors: [appbar_color.withOpacity(0.5),appbar_color.withOpacity(0.7), appbar_color.withOpacity(0.9)], // Gradient background
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
          gridData: FlGridData(show: true, drawVerticalLine: false),
        ),
      ),
    );
  }
}

class AvailableUnitsDialog extends StatelessWidget {
  final String unitno;
  final String building_name;
  final String area;
  final String emirate;
  final String unittype;
  final String rent;
  final String parking;
  final String balcony;
  final String bathrooms;

  // ✅ New fields
  final String ownership;
  final String basicRent;
  final String basicSaleValue;
  final String isExempt;
  final List<String> amenities;

  const AvailableUnitsDialog({
    Key? key,
    required this.unitno,
    required this.area,
    required this.building_name,
    required this.emirate,
    required this.unittype,
    required this.rent,
    required this.parking,
    required this.balcony,
    required this.bathrooms,
    required this.ownership,
    required this.basicRent,
    required this.basicSaleValue,
    required this.isExempt,
    required this.amenities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double maxDialogHeight = screenHeight * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      elevation: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxDialogHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [appbar_color.shade200, appbar_color.shade400],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Icon(Icons.home, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "$unitno",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),

                // Scrollable Details
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailTile(Icons.apartment, "Unit Type", unittype),
                        _buildDetailTile(Icons.business, "Building", building_name),
                        _buildDetailTile(Icons.location_on, "Location", "$area, $emirate"),
                        _buildDetailTile(Icons.attach_money, "Price", rent),
                        _buildDetailTile(Icons.local_parking, "Parking", parking),
                        _buildDetailTile(Icons.balcony, "Balcony", balcony),
                        _buildDetailTile(Icons.bathtub, "Bathrooms", bathrooms),

                        // ✅ New fields
                        if (amenities.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                            color: Colors.white,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.checklist, color: appbar_color.shade200),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Amenities",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: amenities.map((amenity) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 2,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              amenity,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                      ],
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // Close Button
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      "Close",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Detail Tile Widget
  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      color: Colors.white,
      child: Row(
        children: [
          Icon(icon, color: appbar_color.shade200),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

