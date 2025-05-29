import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/Announcements.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cshrealestatemobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'TenantProfile.dart';
import 'AvailableUnitsReport.dart';
import 'ComplaintList.dart';
import 'KYCUpdate.dart';
import 'MaintenanceTicketReport.dart';
import 'RequestList.dart';

class TenantDashboard extends StatefulWidget {
  @override
  _SalesDashboardScreenState createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<TenantDashboard> {
  bool isLoading = true;
  int selectedContractIndex = 0;
  List<Map<String, dynamic>> contracts = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int announcementCount = 0;


  @override
  void initState() {
    super.initState();
    loadAnnouncementCount();
    fetchDashboardData();

  }
  void loadAnnouncementCount() async {
    List<dynamic> announcements = await fetchAllValidAnnouncements();
    setState(() {
      announcementCount = announcements.length;
    });
  }


  Future<void> fetchDashboardData() async {

    final response = await http.get(
      Uri.parse('$baseurl/reports/tenant/cheques/$user_id'),
      headers: {"Authorization": "Bearer $Company_Token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> cheques = jsonDecode(response.body)['data']['tenant']['cheques'];

      Map<String, Map<String, dynamic>> groupedContracts = {};

      for (var cheque in cheques) {
        final payment = cheque['payment'];
        final contract = payment['contract'];
        final contractNo = contract['contract_no'];
        final contractId = contract['id'];

        if (!groupedContracts.containsKey(contractNo)) {
          groupedContracts[contractNo] = {
            'contract_no': contractNo,
            'contract_id': contractId,
            'flats': contract['flats'].map((f) => f['flat']).toList(),
            'cheques': [],
            'invoices': {},
          };
        }

        groupedContracts[contractNo]!['cheques'].add(cheque);

        final month = (payment['received_date'] ?? '').substring(0, 7);
        groupedContracts[contractNo]!['invoices'][month] =
            (groupedContracts[contractNo]!['invoices'][month] ?? 0.0) + (payment['amount_incl']?.toDouble() ?? 0.0);
      }

      setState(() {
        contracts = groupedContracts.values.toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('Failed to load data: ${response.body}');
    }

  }

  String _monthAbbr(int month) {
    const List<String> months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool isEditing = false;


  @override
  Widget build(BuildContext context) {
    /*if (contracts.isEmpty) {
      return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: appbar_color.withOpacity(0.9),
            title: Text('Dashboard', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState!.openDrawer(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: InkWell(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TenantProfile())),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [appbar_color.shade200, appbar_color.shade700], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: Offset(0, 2))],
                    ),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          drawer: Sidebar(isDashEnable: false, isRolesVisible: true, isRolesEnable: true, isUserEnable: true, isUserVisible: true),

          body: Center(
          child: Platform.isIOS
              ? const CupertinoActivityIndicator(radius: 18)
              : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
          ),
        )
      );
    }*/
    Map<String, dynamic> selected = {};
    List cheques = [];
    Map<String, double> invoices = {};
    List flats = [];
    int cleared = 0;
    int pending = 0;

    if (selectedContractIndex >= 0 && selectedContractIndex < contracts.length) {
      selected = contracts[selectedContractIndex] ?? {};
      cheques = selected['cheques'] ?? [];
      flats = selected['flats'] ?? [];

      final rawInvoices = selected['invoices'] ?? {};
      invoices = rawInvoices.map<String, double>((key, value) {
        return MapEntry(key.toString(), (value as num).toDouble());
      });

      cleared = cheques.where((c) => c['is_received'] == 'true').length;
      pending = cheques.length - cleared;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        title: Text('Dashboard', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        actions: [
          // 📢 Announcement Icon with count badge
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementScreen()));

                },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(Icons.campaign_outlined, color: Colors.white),
                  ),

                  // 🔴 Count Badge
                  if (announcementCount > 0)
                    Positioned(
                      top: -8,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$announcementCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 🔔 Notification Icon (existing)
          // Padding(
          //   padding: const EdgeInsets.only(right: 12.0),
          //   child: InkWell(
          //     onTap: () {
          //       // Navigate to notifications screen
          //     },
          //     child: Container(
          //       width: 40,
          //       height: 40,
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         gradient: LinearGradient(
          //           colors: [appbar_color.shade200, appbar_color.shade700],
          //           begin: Alignment.topCenter,
          //           end: Alignment.bottomCenter,
          //         ),
          //         boxShadow: [
          //           BoxShadow(
          //             color: Colors.black.withOpacity(0.2),
          //             blurRadius: 5,
          //             offset: const Offset(0, 2),
          //           )
          //         ],
          //       ),
          //       child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
          //     ),
          //   ),
          // ),
        ],


      ),
      drawer: Sidebar(isDashEnable: true, isRolesVisible: true, isRolesEnable: true, isUserEnable: true, isUserVisible: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            isLoading
                ? Center(
              child: Column(
            children: [

              Platform.isIOS
                  ? const CupertinoActivityIndicator(radius: 18)
                  : CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
              ),
              SizedBox(height: 20),

            ],
            )
            )
                : contracts.isEmpty ?

            Column(
              children: [ Container(

                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(

                      colors: [Colors.white, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child:  Center(
                    child:
                    Column(
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No contracts found",
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
              ),
              SizedBox(height: 10,)],
            )
           :


               Column(
              children: [
                Container(

                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Contract",
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                          ),
                          if (!isEditing)
                            InkWell(
                              onTap: () => setState(() => isEditing = true),
                              child: Icon(Icons.edit, size: 20, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),

                      if (!isEditing) ...[
                        Text(
                          contracts[selectedContractIndex]['contract_no'],
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Unit(s)",
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (contracts[selectedContractIndex]['flats'] as List).map<Widget>((f) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey.shade100],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.home_work_rounded, size: 14, color: appbar_color),
                                  SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f['name'], // Flat name
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      Text(
                                        '${f['building']['name']}, ${f['building']['area']['state']['name']}', // Building name
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  )

                                ],
                              ),
                            );

                          }).toList(),
                        ),
                      ] else ...[
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedContractIndex,
                            isExpanded: true,
                            onChanged: (val) {
                              setState(() {
                                selectedContractIndex = val!;
                                isEditing = false;
                              });
                            },
                            items: List.generate(contracts.length, (index) {
                              final contract = contracts[index];
                              final flatsText = (contract['flats'] as List).map((f) => f['name']).join(' • ');
                              return DropdownMenuItem(
                                  value: index,
                                  child:RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
                                      children: [
                                        TextSpan(
                                          text: contract['contract_no'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(text: "  •  "), // subtle separator
                                        TextSpan(
                                          text: "Flats: ",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: flatsText,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: appbar_color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )

                              );
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 10),

                Container(
                    height: 280,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cheque Summary", style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold)),
                        SizedBox(height: 15),

                        Expanded(
                            child: SizedBox(
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow & shadow effect
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [Colors.white, Colors.grey.shade200],
                                        center: Alignment(-0.1, -0.1),
                                        radius: 0.95,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 8),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: PieChart(
                                        PieChartData(
                                          centerSpaceRadius: 30,
                                          startDegreeOffset: -45,
                                          sectionsSpace: 3,
                                          centerSpaceColor: Colors.grey.shade50,
                                          sections: [
                                            PieChartSectionData(
                                              value: cleared.toDouble(),
                                              title: '$cleared\nCleared',
                                              radius: 75,
                                              titleStyle: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.teal.shade700,
                                                  Colors.teal.shade400,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            PieChartSectionData(
                                              value: pending.toDouble(),
                                              title: '$pending\nPending',
                                              radius: 75,
                                              titleStyle: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.orange.shade700,
                                                  Colors.orange.shade300,
                                                ],
                                                begin: Alignment.bottomLeft,
                                                end: Alignment.topRight,
                                              ),
                                            ),
                                          ],

                                        ),
                                      ),
                                    ),
                                  ),
                                  // Center total label
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Total",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "${cleared + pending}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black12,
                                              blurRadius: 2,
                                              offset: Offset(0.5, 0.5),
                                            ),
                                          ],
                                        ),
                                      ),

                                    ],
                                  )
                                ],
                              ),
                            )
                        )
                      ],
                    )
                ),
                SizedBox(height: 10),

               // invoice summary bar chart
               /* Container(
                    height: 275,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                    child:Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Monthly Invoice Summary",
                          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 26),

                        Expanded(
                          child:  BarChart(
                            BarChartData(
                              barGroups: invoices.entries.toList().asMap().entries.map((entry) {
                                int x = entry.key;
                                String month = entry.value.key;
                                double amount = entry.value.value;
                                return BarChartGroupData(
                                  x: x,
                                  barRods: [
                                    BarChartRodData(toY: amount, color: appbar_color, width: 30, borderRadius: BorderRadius.circular(6)),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      int idx = value.toInt();
                                      if (idx >= invoices.length) return SizedBox.shrink();

                                      String monthKey = invoices.keys.elementAt(idx); // e.g. "2025-02"
                                      DateTime date = DateTime.parse("$monthKey-01");
                                      String label = "${_monthAbbr(date.month)}-${date.year % 100}";


                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(label, style: GoogleFonts.poppins(fontSize: 10)),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (value, meta) => SideTitleWidget(
                                      child: Text(
                                        value >= 1000 ? "${(value / 1000).toStringAsFixed(1)}K" : value.toStringAsFixed(0),
                                        style: GoogleFonts.poppins(fontSize: 12),
                                      ),
                                      axisSide: meta.axisSide,
                                    ),
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (value, meta) => SideTitleWidget(
                                      child: Text(
                                        value >= 1000 ? "${(value / 1000).toStringAsFixed(1)}K" : value.toStringAsFixed(0),
                                        style: GoogleFonts.poppins(fontSize: 12),
                                      ),
                                      axisSide: meta.axisSide,
                                    ),
                                  ),
                                ),
                              ),

                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),

                      ],
                    )
                ),
                SizedBox(height: 10),*/
              ],
            ),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildDashboardButton(Icons.build, 'Maintenance', appbar_color, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceTicketReport()))),
            ]),
            SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildDashboardButton(Icons.credit_card, 'Request', Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestListScreen()))),
              _buildDashboardButton(Icons.home, 'Available Units', Colors.orangeAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AvailableUnitsReport()))),
            ]),
            SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildDashboardButton(Icons.upload_file, 'KYC Update', Colors.tealAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DecentTenantKYCForm()))),
              _buildDashboardButton(Icons.info_outline, 'Complaints/Suggestions', Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintListScreen()))),
            ]),

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
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
  Future<List<dynamic>> fetchAllValidAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userBuildingName = prefs.getString('building'); // your key

    if (userBuildingName == null || userBuildingName.isEmpty) {
      print('No building name found in SharedPreferences');
      return [];
    }

    String url = '$baseurl/master/Announcement';
    final String token = '$Company_Token';

    int currentPage = 1;
    int totalPages = 1;
    List<dynamic> validAnnouncements = [];

    try {
      while (currentPage <= totalPages) {
        final response = await http.get(
          Uri.parse('$url?page=$currentPage'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final List<dynamic> announcements = json['data']?['announcements'] ?? [];

          final now = DateTime.now();

          for (var a in announcements) {
            final expiry = a['expiry'];
            final buildingName = a['building']?['name'] ?? '';

            // Expiry date check
            if (expiry != null && buildingName == userBuildingName) {
              final expiryDate = DateTime.parse(expiry);
              final endOfExpiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day, 23, 59, 59);

              if (endOfExpiry.isAfter(now)) {
                validAnnouncements.add(a);
              }
            }
          }

          final meta = json['meta'];
          if (meta != null && meta['totalCount'] != null && meta['size'] != null) {
            final int totalCount = meta['totalCount'];
            final int pageSize = meta['size'];
            totalPages = (totalCount / pageSize).ceil();
          }

          currentPage++;
        } else {
          print('Failed to fetch page $currentPage: ${response.statusCode}');
          break;
        }
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }

    return validAnnouncements;
  }

}