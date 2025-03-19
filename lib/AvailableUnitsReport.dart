import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class AvailableUnitsReport extends StatefulWidget {
  const AvailableUnitsReport({Key? key}) : super(key: key);
  @override
  _AvailableUnitsReportPageState createState() => _AvailableUnitsReportPageState();
}


class _AvailableUnitsReportPageState extends State<AvailableUnitsReport> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoUserFound = false;

  String searchQuery = "";
  String name = "", email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  late SharedPreferences prefs;

  String? hostname = "", company = "", company_lowercase = "", serial_no = "", username = "", HttpURL = "", SecuritybtnAcessHolder = "";
  late Future<List<Flat>> futureFlats;
  List<Flat> filteredUnits = []; // List to store API data
  List<Flat> allUnits = []; // Stores all units fetched from API

  void fetchFlats() async {
    try {
      List<Flat> flats = await ApiService().fetchFlats();
      setState(() {
        allUnits = flats;
        allUnits = allUnits.reversed.toList();
        filteredUnits = allUnits;
      });
    } catch (e) {
      print("Error fetching flats: $e");
    }
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      fetchFlats();
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredUnits = allUnits.where((unit) =>
      unit.flatTypeName.toLowerCase().contains(query.toLowerCase()) ||
          unit.buildingName.toLowerCase().contains(query.toLowerCase()) ||
          unit.name.toLowerCase().contains(query.toLowerCase()) ||
          unit.areaName.toLowerCase().contains(query.toLowerCase()) ||
          unit.stateName.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  Future<void> _refresh() async {
    setState(() {
      fetchFlats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF2F4F8),
            appBar: AppBar(
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: _updateSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search Units',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              title: Text(
                'Available Units',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: appbar_color.withOpacity(0.9),
              automaticallyImplyLeading: false,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
              ),
            ),
            drawer: Sidebar(
              isDashEnable: isDashEnable,
              isRolesVisible: isRolesVisible,
              isRolesEnable: isRolesEnable,
              isUserEnable: isUserEnable,
              isUserVisible: isUserVisible,
            ),
            body: RefreshIndicator(
                onRefresh: _refresh,
                child: Stack(children: [
                  Visibility(
                      visible: isVisibleNoUserFound,
                      child: Container(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Center(
                              child: Text(
                                'No User Found',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24.0,
                                ),
                              )))),
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: filteredUnits.length,
                      itemBuilder: (context, index) {
                        final unit = filteredUnits[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 10.0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.home),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      unit.flatTypeName,
                                      style: GoogleFonts.poppins(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.location_city),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      unit.buildingName,
                                      style: GoogleFonts.poppins(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.location_on),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${unit.areaName}, ${unit.stateName}",
                                      style: GoogleFonts.poppins(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(top: 0, bottom: 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildDecentButton(
                                      'View',
                                      Icons.remove_red_eye,
                                      Colors.orange,
                                          () {
                                        String unitno = unit.name.toString();
                                        String unittype = unit.flatTypeName;
                                        String area = unit.areaName;
                                        String emirate = unit.stateName;
                                        String rent = "AED N/A";
                                        String parking = "N/A";
                                        String balcony = "N/A";
                                        String bathrooms = "N/A";
                                        String building = unit.buildingName;

                                        showDialog(
                                          context: context,
                                          builder: (context) => AvailableUnitsDialog(
                                            unitno: unitno,
                                            area: area,
                                            emirate: emirate,
                                            unittype: unittype,
                                            rent: rent,
                                            parking: parking,
                                            balcony: balcony,
                                            bathrooms: bathrooms,
                                            building_name: building,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Visibility(
                    visible: _isLoading,
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                ]))));
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double maxDialogHeight = screenHeight * 0.8; // Prevents full-screen expansion

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      elevation: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // ✅ Light background for contrast
          borderRadius: BorderRadius.circular(20), // ✅ Round corners for container
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxDialogHeight, // Adaptive height, not exceeding 80% of screen
          ),
          child: IntrinsicHeight( // Makes dialog fit content when possible
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with unit number & background
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
                        "Unit $unitno",
                        style: GoogleFonts.poppins( // ✅ Poppins Font Applied
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),

                // Scrollable Details Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailTile(Icons.apartment, "Unit Type", unittype),
                        _buildDetailTile(Icons.business, "Building", building_name),
                        _buildDetailTile(Icons.location_on, "Location", "$area, $emirate"),
                        _buildDetailTile(Icons.attach_money, "Rent", rent),
                        _buildDetailTile(Icons.local_parking, "Parking", parking),
                        _buildDetailTile(Icons.balcony, "Balcony", balcony),
                        _buildDetailTile(Icons.bathtub, "Bathrooms", bathrooms),
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
                      style: GoogleFonts.poppins( // ✅ Poppins Font Applied
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

  // ✅ Detail Tile with Poppins Font
  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 13),
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
                  style: GoogleFonts.poppins( // ✅ Applied Poppins
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins( // ✅ Applied Poppins
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 2, // Prevents UI breaking with long text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildDecentButton(
    String label, IconData icon, Color color, VoidCallback onPressed) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(30.0),
    splashColor: color.withOpacity(0.2),
    highlightColor: color.withOpacity(0.1),
    child: Container(
      margin: EdgeInsets.only(top: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        color: Colors.white,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8.0),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class ApiService {

  Future<List<Flat>> fetchFlats() async {
    final response = await http.get(
      Uri.parse("$baseurl/reports/flat/available/date?date=2025-02-01"), // Update endpoint if necessary
      headers: {
        "Authorization": "Bearer $Company_Token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> flatsJson = data["data"];
      return flatsJson.map((json) => Flat.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch data. Status Code: ${response.statusCode}");
    }
  }
}

// Model Class
class Flat {
  final int id;
  final String name;
  final String? grossArea;
  final String buildingName;
  final String floorName;
  final String flatTypeName;
  final String areaName;
  final String stateName;
  final String countryName;
  final String createdAt;

  Flat({
    required this.id,
    required this.name,
    this.grossArea,
    required this.buildingName,
    required this.floorName,
    required this.flatTypeName,
    required this.areaName,
    required this.stateName,
    required this.countryName,
    required this.createdAt,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json["id"],
      name: json["name"],
      grossArea: json["gross_area_in_sqft"],
      buildingName: json["building"]["name"],
      floorName: json["floors"]["name"],
      flatTypeName: json["flat_type"]["name"],
      areaName: json["building"]["area"]["name"],
      stateName: json["building"]["area"]["state"]["name"],
      countryName: json["building"]["area"]["state"]["country"]["name"],
      createdAt: json["created_at"],
    );
  }
}
