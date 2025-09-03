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
  String selectedCategory = 'All'; // 'All' | 'Rent' | 'Sale'


// NEW: 'Rent' | 'Sale'
  String selectedMode = 'Rent';

  @override
  void initState() {
    super.initState();
    print('building data -> ${widget.building}');
  }

  bool _truthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }
  String _statusOf(Map f) => (f['status']?.toString().trim().toLowerCase()) ?? '';

  Widget _buildUnitTile({
    required BuildContext context,
    required Map flat,
    required String category,     // 'Sale' or 'Rent'
    required Color badgeColor,
    required bool isAvailable,    // true = Available, false = Occupied
    required int? loadingFlatId,
    required Future<void> Function(int flatId, String category) onTapFetch,
  }) {
    final int flatId = flat['id'] ?? -1;
    final isLoading = loadingFlatId == flatId;

    print('isLoading -> ${isLoading}');

    final flatName = flat['name']?.toString() ?? 'N/A';
    final flatType = flat['flat_type']?['name']?.toString() ?? 'N/A';

    final String availText  = isAvailable ? 'Available' : 'Occupied';
    final Color  availColor = isAvailable ? Colors.green : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: GestureDetector(
        onTap: () => onTapFetch(flatId, category),   // 👈 send both
        child: isLoading
            ? ListTile(
          subtitle: Center(
            child: Platform.isIOS
                ? const CupertinoActivityIndicator(radius: 18)
                : CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(appbar_color)),
          ),
        )
            : ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: badgeColor.withOpacity(0.15)),
            child: Icon(Icons.home_outlined, color: badgeColor, size: 24),
          ),
          title: Text('Unit $flatName', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: Text('Type: $flatType',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: availColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(availText, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: availColor)),
          ),
        ),
      ),
    );
  }

  Future<void> _onTapFetchFlat(int flatId, String category) async {
    setState(() => loadingTileIndex = flatId);

    final response = await http.get(
      Uri.parse('$baseurl/master/flat/$flatId'),
      headers: {"Authorization": "Bearer $Company_Token", "Content-Type": "application/json"},
    );

    setState(() => loadingTileIndex = null);

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      final flat = data['data']['flat'];

      final unitno       = flat['name'] ?? 'N/A';
      final buildingName = flat['building']?['name'] ?? 'N/A';
      final area         = flat['building']?['area']?['name'] ?? 'N/A';
      final emirate      = flat['building']?['area']?['state']?['name'] ?? 'N/A';
      final unittype     = flat['flat_type']?['name'] ?? 'N/A';

      final parkingCount = ((flat['parkings'] as List?) ?? []).length;
      final parking      = parkingCount.toString();

      final balcony      = 'N/A';
      final bathrooms    = flat['no_of_bathrooms']?.toString() ?? 'N/A';
      final ownership    = flat['ownership'] ?? 'N/A';
      final basicRent      = flat['basic_rent']?.toString() ?? 'N/A';
      final basicSaleValue = flat['basic_sale_value']?.toString() ?? 'N/A';
      final isExempt       = flat['is_exempt']?.toString() ?? 'false';

      // 👇 category decides which price to show
      final String priceLabel = category == 'Sale' ? 'Price' : 'Rent';
      final String priceValue = category == 'Sale' ? basicSaleValue : basicRent;

      final amenities = ((flat['amenities'] as List?) ?? [])
          .map<String>((a) => a?['amenity']?['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      showDialog(
        context: context,
        builder: (context) => AvailableUnitsDialog(
          unitno: unitno,
          area: area,
          building_name: buildingName,
          emirate: emirate,
          unittype: unittype,
          priceLabel: priceLabel,
          price: priceValue,
          parking: parking,
          balcony: balcony,
          bathrooms: bathrooms,
          ownership: ownership,
          basicRent: basicRent,
          basicSaleValue: basicSaleValue,
          isExempt: isExempt,
          amenities: amenities,
        ),
      );
    } else {
      final errorMessage = data['message'] ?? 'Unknown error occurred';
      showErrorSnackbar(context, errorMessage);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _sectionHeader(String text, Color dotColor) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 6),
    child: Row(children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(text, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600)),
    ]),
  );

  void _openMaps() async {
    final String companyName = company_name ?? '';
    final String companyAddress = address ?? '';

    print('company name -> $companyName');
    print('company Address -> $companyAddress');

    // Combine company name and address for a more accurate map query
    final String query = Uri.encodeComponent('$companyName $companyAddress');

    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$query";
    final String appleMapsUrl = "https://maps.apple.com/?q=$query";
    final String wazeUrl = "waze://?q=$query";

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (await canLaunch(appleMapsUrl)) {
        await launch(appleMapsUrl);
      } else if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not open map app';
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else if (await canLaunch(wazeUrl)) {
        await launch(wazeUrl);
      } else {
        throw 'Could not open map app';
      }
    } else {
      throw 'Platform not supported';
    }
  }

  @override
  Widget build(BuildContext context) {
    final building = widget.building;
    final flats = (building['flats'] as List?)?.cast<Map>() ?? [];



// Category partitions
    final rentUnitsAll = flats.where((f) => _truthy(f['forRent'])).toList();
    final saleUnitsAll = flats.where((f) => _truthy(f['forSales'])).toList();

    final int availableRent = (building['availableFlatsForRent'] ?? 0) as int;
    final int availableSale = (building['availableFlatsForSale'] ?? 0) as int;

    late int available;
    late int occupied;

    if (selectedCategory == 'Rent') {
      final int rentTotal = flats.where((f) => _statusOf(f) == 'rent' || _truthy(f['forRent'])).length;
      available = availableRent;
      occupied  = (rentTotal - availableRent).clamp(0, rentTotal);
    } else if (selectedCategory == 'Sale') {
      final int saleTotal = flats.where((f) => _statusOf(f) == 'buy' || _truthy(f['forSales'])).length;
      available = availableSale;
      occupied  = (saleTotal - availableSale).clamp(0, saleTotal);
    } else {
      final int totalFlats = flats.length;
      available = availableRent + availableSale;
      occupied  = (totalFlats - available).clamp(0, totalFlats);
    }

// Per-unit availability heuristic
    bool isUnitAvailable(Map f) => _truthy(f['forRent']) || _truthy(f['forSales']);

// Buckets for the LIST, respecting selectedCategory and selectedFilter
    final bool wantAvail = selectedFilter == 'Available' || selectedFilter == 'All';
    final bool wantOcc   = selectedFilter == 'Occupied'  || selectedFilter == 'All';

    List<Map> listSaleAvail   = [];
    List<Map> listRentAvail   = [];
    List<Map> listSaleOcc     = [];
    List<Map> listRentOcc     = [];

    if (selectedCategory == 'Rent' || selectedCategory == 'All') {
      if (wantAvail) listRentAvail = flats.where((f) => isUnitAvailable(f) && _truthy(f['forRent'])).toList();
      if (wantOcc)   listRentOcc   = flats.where((f) => !isUnitAvailable(f) && _statusOf(f) == 'rent').toList();
    }
    if (selectedCategory == 'Sale' || selectedCategory == 'All') {
      if (wantAvail) listSaleAvail = flats.where((f) => isUnitAvailable(f) && _truthy(f['forSales'])).toList();
      if (wantOcc)   listSaleOcc   = flats.where((f) => !isUnitAvailable(f) && _statusOf(f) == 'buy').toList();
    }

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
         child: (building['flats'] as List).isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.domain_disabled, color: Colors.grey, size: 64),
            SizedBox(height: 12),
            Text(
              'No unit(s) data available',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          :Stack(
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
                      Container(
                        height: 350, // was 400
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12), // tighter padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top row: Chips (left) + Toggle (right)
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.start,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      ChoiceChip(
                                        avatar: Icon(Icons.all_inclusive,
                                            size: 16,
                                            color: selectedCategory == 'All'
                                                ? Colors.white
                                                : Colors.grey.shade600),
                                        label: Text('All'),
                                        selected: selectedCategory == 'All',
                                        onSelected: (_) => setState(() {
                                          selectedCategory = 'All';
                                          selectedFilter = 'All';
                                        }),
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selectedCategory == 'All' ? Colors.white : Colors.black87,
                                        ),
                                        selectedColor: appbar_color, // main brand color
                                        backgroundColor: Colors.grey.shade100,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        elevation: selectedCategory == 'All' ? 3 : 0,
                                        pressElevation: 1,
                                      ),
                                      ChoiceChip(
                                        avatar: Icon(Icons.key,
                                            size: 16,
                                            color: selectedCategory == 'Rent'
                                                ? Colors.white
                                                : Colors.teal.shade600),
                                        label: Text('Rent'),
                                        selected: selectedCategory == 'Rent',
                                        onSelected: (_) => setState(() {
                                          selectedCategory = 'Rent';
                                          selectedFilter = 'All';
                                        }),
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selectedCategory == 'Rent' ? Colors.white : Colors.black87,
                                        ),
                                        selectedColor: Colors.teal,
                                        backgroundColor: Colors.teal.shade50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        elevation: selectedCategory == 'Rent' ? 3 : 0,
                                        pressElevation: 1,
                                      ),
                                      ChoiceChip(
                                        avatar: Icon(Icons.shopping_bag,
                                            size: 16,
                                            color: selectedCategory == 'Sale'
                                                ? Colors.white
                                                : Colors.blue.shade600),
                                        label: Text('Sale'),
                                        selected: selectedCategory == 'Sale',
                                        onSelected: (_) => setState(() {
                                          selectedCategory = 'Sale';
                                          selectedFilter = 'All';
                                        }),
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selectedCategory == 'Sale' ? Colors.white : Colors.black87,
                                        ),
                                        selectedColor: Colors.blue,
                                        backgroundColor: Colors.blue.shade50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        elevation: selectedCategory == 'Sale' ? 3 : 0,
                                        pressElevation: 1,
                                      ),
                                    ],
                                  ),
                                ),

                                // Toggle button (pie <-> bar)
                                Tooltip(
                                  message: showPieChart ? 'Switch to Bar' : 'Switch to Pie',
                                  child: InkWell(
                                    onTap: () => setState(() => showPieChart = !showPieChart),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [appbar_color.withOpacity(0.8), appbar_color],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: appbar_color.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        transitionBuilder: (child, anim) =>
                                            RotationTransition(turns: anim, child: child),
                                        child: Icon(
                                          showPieChart ? Icons.pie_chart : Icons.bar_chart,
                                          key: ValueKey(showPieChart),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),


                            const SizedBox(height: 16),

                            // Chart area
                            Expanded(
                              child: (available + occupied) == 0
                                  ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.insert_chart_outlined, color: Colors.grey, size: 64),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No data available',
                                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              )
                                  : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  final fade = Tween<double>(begin: 0, end: 1).animate(animation);
                                  final scale = Tween<double>(begin: 0.97, end: 1).animate(animation);
                                  return FadeTransition(
                                    opacity: fade,
                                    child: ScaleTransition(scale: scale, child: child),
                                  );
                                },
                                child: showPieChart
                                    ? PieChartGraph(
                                  key: const ValueKey('pie'),
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
                                  key: const ValueKey('bar'),
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

                            const SizedBox(height: 6),

                            // Compact legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text('Occupied', style: GoogleFonts.poppins(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Row(
                                  children: [
                                    Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green.withOpacity(0.9), shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text('Available', style: GoogleFonts.poppins(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),


                  SizedBox(height: 10,),

                  if (listSaleAvail.isEmpty &&
                      listRentAvail.isEmpty &&
                      listSaleOcc.isEmpty &&
                      listRentOcc.isEmpty) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.domain_disabled, color: Colors.grey, size: 60),
                          const SizedBox(height: 8),
                          Text(
                            'No units data available',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],


                  // ===== AVAILABLE =====
                  if (wantAvail && (listSaleAvail.isNotEmpty || listRentAvail.isNotEmpty)) ...[
                    if (listSaleAvail.isNotEmpty) ...[
                      _sectionHeader('Sale Units (Available) (${listSaleAvail.length})', Colors.blue),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listSaleAvail.length,
                        itemBuilder: (context, i) => _buildUnitTile(
                          context: context,
                          flat: listSaleAvail[i],
                          category: 'Sale',
                          badgeColor: Colors.blue,
                          isAvailable: true,
                          loadingFlatId: loadingTileIndex,
                          onTapFetch: _onTapFetchFlat,
                        ),
                      ),
                    ],
                    if (listRentAvail.isNotEmpty) ...[
                      _sectionHeader('Rent Units (Available) (${listRentAvail.length})', Colors.teal),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listRentAvail.length,
                        itemBuilder: (context, i) => _buildUnitTile(
                          context: context,

                          flat: listRentAvail[i],
                          category: 'Rent',
                          badgeColor: Colors.teal,
                          isAvailable: true,
                          loadingFlatId: loadingTileIndex,
                          onTapFetch: _onTapFetchFlat,
                        ),
                      ),
                    ],
                  ],

// ===== OCCUPIED =====
                  if (wantOcc && (listSaleOcc.isNotEmpty || listRentOcc.isNotEmpty)) ...[
                    if (listSaleOcc.isNotEmpty) ...[
                      _sectionHeader('Sale Units (Occupied) (${listSaleOcc.length})', Colors.indigo),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listSaleOcc.length,
                        itemBuilder: (context, i) => _buildUnitTile(
                          context: context,
                          flat: listSaleOcc[i],
                          category: 'Sale',
                          badgeColor: Colors.indigo,
                          isAvailable: false,
                          loadingFlatId: loadingTileIndex,
                          onTapFetch: _onTapFetchFlat,
                        ),
                      ),
                    ],
                    if (listRentOcc.isNotEmpty) ...[
                      _sectionHeader('Rent Units (Occupied) (${listRentOcc.length})', Colors.deepOrange),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listRentOcc.length,
                        itemBuilder: (context, i) => _buildUnitTile(
                          context: context,
                          flat: listRentOcc[i],
                          category: 'Rent',
                          badgeColor: Colors.deepOrange,
                          isAvailable: false,
                          loadingFlatId: loadingTileIndex,
                          onTapFetch: _onTapFetchFlat,
                        ),
                      ),
                    ],
                  ],


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
                    child: GestureDetector(
                      onTap: _openMaps, // This triggers the map open logic
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
                    colors: [Colors.redAccent.withOpacity(0.5),Colors.redAccent.withOpacity(0.9), Colors.redAccent.withOpacity(0.9)], // Gradient background
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
                    colors: [Colors.green.withOpacity(0.5),Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.8)], // Gradient background
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
                    colors: [Colors.redAccent.withOpacity(0.9),Colors.redAccent.withOpacity(0.8), Colors.redAccent.withOpacity(0.8)], // Gradient background
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
                    colors: [Colors.green.withOpacity(0.5),Colors.green.withOpacity(0.7), Colors.green.withOpacity(0.9)], // Gradient background
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
  final String price;        // renamed from 'rent'
  final String priceLabel;   // new
  final String parking;
  final String balcony;
  final String bathrooms;

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
    required this.price,        // renamed
    required this.priceLabel,   // new
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
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Icon(Icons.attach_money, color: appbar_color.shade200),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      priceLabel, // "Rent" or "Sale"
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,


                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Image.asset('assets/dirham.png', width: 14, height: 14, fit: BoxFit.contain),
                                        const SizedBox(width: 6),
                                        Text(
                                          price,
                                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // _buildDetailTile(Icons.attach_money, "Price", rent),
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



