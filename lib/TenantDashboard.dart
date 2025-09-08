import 'dart:async';
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
  int? loadingTileIndex;

  Map<String, dynamic> user = {
    "name": "",
    "email": "",
    "id": 0,
  };

  @override
  void initState() {
    super.initState();
    setState(() {
      user['name'] = user_name ?? 'Guest';
      user['email'] = user_email ?? '-';
      user['id'] = user_id ?? 0;
    });
    loadAnnouncementCount();
    fetchDashboardData();

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
      final String priceLabel = category == 'Buy' ? 'Price' : 'Rent';
      final String priceValue = category == 'Buy' ? basicSaleValue : basicRent;

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


  void loadAnnouncementCount() async {
    List<dynamic> announcements = await fetchAllValidAnnouncements();
    setState(() {
      announcementCount = announcements.length;
    });
  }

  void _showUnitsPopup(BuildContext context, String buildingName) {
    final units = contracts
        .expand((contract) => contract['flats'] as List)
        .where((flat) => flat['building']?['name'] == buildingName)
        .toList();


    print('Units for $buildingName: $units');

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), // ⬅️ reduced bottom padding
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 👈 This makes the height wrap content
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                          // Avatar + Name + Email (Centered vertically)
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.orange,
                                child: Text(
                                  buildingName.isNotEmpty
                                      ? buildingName[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                buildingName ?? 'N/A',
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${units.length.toString()} Unit(s)' ?? '-',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Divider(),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: units.length,
                          itemBuilder: (context, i) => _buildUnitTile(
                            context: context,
                            flat: units[i],
                            badgeColor: Colors.blue,
                            loadingFlatId: loadingTileIndex,
                            onTapFetch: _onTapFetchFlat,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Close Icon (top-right)
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  // new dashboard function
  Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);

    try {
      final url = is_landlord
          ? '$baseurl/landlord/$user_id'
          : '$baseurl/tenant/$user_id';

      print('Dashboard URL -> $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $Company_Token"},
      );

      if (response.statusCode != 200) {
        print('Non-200 response: ${response.statusCode}');
        setState(() => isLoading = false);
        return;
      }

      final data = jsonDecode(response.body);
      print('Dashboard data -> $data');

      if (is_landlord) {
        _processLandlordData(data['data']['landlord']);
      } else {
        _processTenantData(data['data']['tenant']);
      }

    } catch (e) {
      print('Error in fetchDashboardData: $e');
      setState(() => isLoading = false);
    }
  }

  void _processTenantData(Map<String, dynamic> tenant) {
    final contractsList = tenant['contracts'] ?? [];
    Map<String, Map<String, dynamic>> groupedContracts = {};

    for (var contract in contractsList) {
      final contractNo = contract['contract_no'];
      final contractId = contract['id'];
      if (contractNo == null) continue;

      groupedContracts[contractNo] = {
        'contract_no': contractNo,
        'contract_id': contractId,
        'contract_type': 'rental',
        'expiry_date': contract['to_date'],  // ✅ Extract to_date as expiry date
        'flats': [],
        'cheques': [],
        'invoices': {},
      };

      final flatLinks = contract['flats'] ?? [];
      for (var link in flatLinks) {
        final flat = link['flat'];
        if (flat != null) {
          groupedContracts[contractNo]!['flats'].add(flat);
        }
      }

      final receipts = contract['receipts'] ?? [];
      for (var receipt in receipts) {
        final payments = receipt['payments'] ?? [];
        for (var paymentObj in payments) {
          final payment = paymentObj['payment'];
          final cheque = payment['cheque'];

          if (cheque != null) {
            groupedContracts[contractNo]!['cheques'].add({
              'payment': payment,
              'date': cheque['date'],
              'is_received': cheque['is_received'] == 'true',
              'is_deposited': cheque['is_deposited'] == 'true',
              'returned_on': payment['returned_on'],
            });

            final dateStr = cheque['date'] ?? '';
            final month = dateStr.isNotEmpty ? dateStr.substring(0, 7) : 'Unknown';

            groupedContracts[contractNo]!['invoices'][month] =
                (groupedContracts[contractNo]!['invoices'][month] ?? 0.0) +
                    (payment['amount_incl']?.toDouble() ?? 0.0);
          }
        }
      }
    }

    setState(() {
      contracts = groupedContracts.values.toList();
      if (contracts.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showContractExpiryNotice(context, contracts[0]);
        });
      }
      isLoading = false;
    });
  }

  void _processLandlordData(Map<String, dynamic> landlord) {
    final boughtContracts = landlord['bought_contracts'] ?? [];
    final soldContracts = landlord['sold_contracts'] ?? [];
    final rentalContracts = landlord['rental_contracts'] ?? [];  // ✅ Handle rental contracts

    buildingFlatCount.clear();
    List<Map<String, dynamic>> allContracts = [];

    for (var contract in boughtContracts) {
      allContracts.add(_extractLandlordContract(contract, 'bought'));
    }

    for (var contract in soldContracts) {
      allContracts.add(_extractLandlordContract(contract, 'sold'));
    }

    for (var contract in rentalContracts) {
      allContracts.add(_extractLandlordContract(contract, 'rental'));  // ✅ Process rental contracts
    }

    setState(() {
      contracts = allContracts;
      if (contracts.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showContractExpiryNotice(context, contracts[0]);
        });

      }
      isLoading = false;
    });
  }

  Map<String, dynamic> _extractLandlordContract(Map<String, dynamic> contract, String type) {
    final contractNo = contract['contract_no'];
    final contractId = contract['id'];
    final flatLinks = contract['flats'] ?? [];
    List<dynamic> extractedFlats = [];

    for (var link in flatLinks) {
      final flat = link['flat'];
      if (flat != null) {
        extractedFlats.add(flat);
        final buildingName = flat['building']?['name'] ?? 'Unknown';
        buildingFlatCount[buildingName] = (buildingFlatCount[buildingName] ?? 0) + 1;
      }
    }

    return {
      'contract_no': contractNo,
      'contract_id': contractId,
      'contract_type': type,
      'expiry_date': contract['to_date'],  // ✅ Include to_date as expiry date
      'flats': extractedFlats,
    };
  }


// old dashboard function

  /*Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);

    try {
      final flatContractUrl = '$baseurl/reports/admin/contracts/$user_id?is_tenant=${!is_landlord}';
      print('contract url -> $flatContractUrl');

      final flatContractResponse = await http.get(
        Uri.parse(flatContractUrl),
        headers: {"Authorization": "Bearer $Company_Token"},
      );

      final data = jsonDecode(flatContractResponse.body);

      print('data -> $data');

      if (flatContractResponse.statusCode == 200) {
        final partyKey = is_landlord ? 'landlord' : 'tenant';

        if (!is_landlord) {
          final tenant = data['data']['tenant'];
          final List<dynamic> rentalContracts = tenant['rental_contracts'] ?? [];

          Map<String, Map<String, dynamic>> groupedContracts = {};

          for (var contract in rentalContracts) {
            final contractNo = contract['contract_no'];
            final contractId = contract['id'];
            if (contractNo == null) continue;

            // Initialize group
            groupedContracts[contractNo] = {
              'contract_no': contractNo,
              'contract_id': contractId,
              'flats': [],
              'cheques': [],
              'invoices': {},
            };

            // Extract flats
            final List<dynamic> flatLinks = contract['flats'] ?? [];
            for (var link in flatLinks) {
              final flat = link['flat'];
              if (flat != null) {
                groupedContracts[contractNo]!['flats'].add(flat);
              }
            }

            // Extract cheques from receipts → payments → cheque
            final List<dynamic> receipts = contract['receipts'] ?? [];
            for (var receipt in receipts) {
              final List<dynamic> payments = receipt['payments'] ?? [];
              for (var paymentObj in payments) {
                final payment = paymentObj['payment'];
                final cheque = payment['cheque'];
                if (cheque != null) {
                  groupedContracts[contractNo]!['cheques'].add({
                    'payment': payment,
                    'date': cheque['date'],
                    'is_received': cheque['is_received'],
                    'is_deposited': cheque['is_deposited'],
                    'returned_on': payment['returned_on'],
                  });

                  final month = (cheque['date'] ?? '').substring(0, 7);
                  groupedContracts[contractNo]!['invoices'][month] =
                      (groupedContracts[contractNo]!['invoices'][month] ?? 0.0) +
                          (payment['amount_incl']?.toDouble() ?? 0.0);
                }
              }
            }
          }

          setState(() {
            contracts = groupedContracts.values.toList();
            isLoading = false;
          });
        }
        else {
          // 🧑‍💼 Landlord Case
          final landlord = data['data']['landlord'];
          final List<dynamic> boughtContracts = landlord['bought_contracts'] ?? [];
          final List<dynamic> rentalContracts = landlord['rental_contracts'] ?? [];

          buildingFlatCount.clear();
          List<Map<String, dynamic>> allContracts = [];

          void processContract(Map<String, dynamic> contract, String type) {
            final contractNo = contract['contract_no'];
            final contractId = contract['id'];
            if (contractNo == null) return;

            final List<dynamic> flatLinks = contract['flats'] ?? [];
            List<dynamic> extractedFlats = [];

            for (var link in flatLinks) {
              final flat = link['flat'];
              if (flat != null) {
                extractedFlats.add(flat);

                final buildingName = flat['building']?['name'] ?? 'Unknown';
                buildingFlatCount[buildingName] = (buildingFlatCount[buildingName] ?? 0) + 1;
              }
            }

            allContracts.add({
              'contract_no': contractNo,
              'contract_id': contractId,
              'contract_type': type,
              'flats': extractedFlats,
            });
          }

          for (var contract in boughtContracts) {
            processContract(contract, 'bought');
          }

          for (var contract in rentalContracts) {
            processContract(contract, 'rental');
          }

          setState(() {
            contracts = allContracts;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error in fetchDashboardData: $e");
      setState(() => isLoading = false);
    }
  }*/
  String _formatDateToDDMMMYYYY(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = monthNames[date.month - 1];
    final year = date.year;
    return "$day-$month-$year";
  }

  bool isEditing = false;
  Map<String, int> buildingFlatCount = {};

  void _showContractExpiryNotice(BuildContext context, Map<String, dynamic> contract) {
    if (contract['contract_type'] != 'rental' || contract['expiry_date'] == null) return;

    dynamic expiryDate = DateTime.tryParse(contract['expiry_date']);
     // dynamic expiryDate = DateTime.tryParse("2025-08-05");
     expiryDate = expiryDate != null
        ? DateTime(expiryDate.year, expiryDate.month, expiryDate.day, 23, 59, 59, 999)
        : null;
    if (expiryDate == null) return;

    dynamic  now = DateTime.now();
    now = now != null
        ? DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
        : null;
    dynamic daysLeft = expiryDate.difference(now).inDays;
    final formattedDate = _formatDateToDDMMMYYYY(expiryDate);


    if (!(daysLeft < 0 || daysLeft == 0 || daysLeft <= 3 || daysLeft <= 300)) return;

    String expiryText = '';
    if (daysLeft < 0) {
      expiryText = 'This contract expired on $formattedDate';
    } else if (daysLeft == 0) {
      expiryText = 'This contract is expiring today ($formattedDate)';
    } else {
      expiryText = 'Expiring in ${daysLeft} day${daysLeft == 1 ? '' : 's'} on $formattedDate';
    }

    final contractNo = contract['contract_no'] ?? 'N/A';
    final flats = contract['flats'] as List;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AnimatedReminderDialog(
          contractNo: contractNo,
          expiryText: expiryText,
          daysLeft: daysLeft,
          flats: flats,
        );
      },
    );
  }
  int? lastNotifiedIndex;

  void _maybeNotify(BuildContext context, int index) {
    if (lastNotifiedIndex != index) {
      lastNotifiedIndex = index;
      _showContractExpiryNotice(context, contracts[index]);
    }
  }


  @override
  Widget build(BuildContext context) {

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
          if(hasPermission('canViewAnnouncement'))...[
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
                            style:GoogleFonts.poppins(
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
          ]


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

            GestureDetector(
              onTap: () => _showUserProfileBottomSheet(context),
              child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child:Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal,
                        child: Text(
                          user['name'] != null && user['name'].isNotEmpty
                              ? user['name'][0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // User Name & Welcome Message
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Name
                            Text(
                              "Welcome!",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Welcome Text
                            Text(
                              user['name'] ?? 'User',

                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Subtitle
                            Text(
                              "Tap to view your profile",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
              )
            ),

            isLoading
                ? Center(
              child: Column(
            children: [

              Platform.isIOS
                  ? const CupertinoActivityIndicator(radius: 18,color: appbar_color)
                  : CircularProgressIndicator.adaptive(
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
           : Column(
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
                        Text(
                          contracts[selectedContractIndex]['contract_type'] == 'bought'
                              ? "Buy Contract"
                              : "Rental Contract",
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Builder(builder: (context) {
                          final contract = contracts[selectedContractIndex];
                          final contractType = contract['contract_type'];
                          final expiryStr = contract['expiry_date'];

                          if (contractType != 'rental' || expiryStr == null) return SizedBox.shrink();

                          final expiryDate = DateTime.tryParse(expiryStr);
                          if (expiryDate == null) return SizedBox.shrink();

                          final now = DateTime.now();
                          final daysLeft = expiryDate.difference(now).inDays;
                          Color badgeColor = Colors.green;
                          String expiryText = '';
                          final formattedDate = _formatDateToDDMMMYYYY(expiryDate);

                          if (daysLeft < 0) {
                            badgeColor = Colors.red;
                            expiryText = 'Expired on $formattedDate';
                          } else if (daysLeft <= 3) {
                            badgeColor = Colors.red;
                            expiryText = 'Expiring in $daysLeft day${daysLeft == 1 ? '' : 's'} on $formattedDate';
                          } else if (daysLeft <= 30) {
                            badgeColor = Colors.yellow.shade700;
                            expiryText = 'Expiring in $daysLeft day${daysLeft == 1 ? '' : 's'} on $formattedDate';
                          } else {

                            badgeColor = Colors.green;
                            expiryText = 'Expiring in $daysLeft day${daysLeft == 1 ? '' : 's'} on $formattedDate';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: badgeColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 14, color: badgeColor),
                                  SizedBox(width: 6),
                                  Text(
                                    expiryText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: badgeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),



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
                                _maybeNotify(context, selectedContractIndex);

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
                                          text: "Unit: ",
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

                if (!is_landlord) ...[
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
                ],

                if (is_landlord && buildingFlatCount.isNotEmpty) ...[
                  Container(
                    height: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Unit(s)",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (buildingFlatCount.values.reduce((a, b) => a > b ? a : b)).toDouble(), // for headroom
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchCallback: (event, response) {
                                  if (event is FlTapUpEvent && response != null && response.spot != null)
                                    {
                                      final index = response.spot!.touchedBarGroupIndex;
                                      final buildingName = buildingFlatCount.keys.elementAt(index!);

                                      _showUnitsPopup(context, buildingName);
                                    }


                                },
                              ),

                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      final label = value % 1 == 0 ? value.toInt().toString() : '';
                                      return SideTitleWidget(
                                        meta:meta,
                                        child: Text(label, style: GoogleFonts.poppins(fontSize: 11)),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= buildingFlatCount.length) return const SizedBox.shrink();
                                      final label = buildingFlatCount.keys.elementAt(index);
                                      return SideTitleWidget(
                                        meta:meta,
                                        child: Text(
                                          label,
                                          style: GoogleFonts.poppins(fontSize: 10),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                    reservedSize: 60,
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                checkToShowHorizontalLine: (value) => value % 1 == 0,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: buildingFlatCount.entries.toList().asMap().entries.map((entry) {
                                final index = entry.key;
                                final label = entry.value.key;
                                final count = entry.value.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: count.toDouble(),
                                      width: 20,
                                      borderRadius: BorderRadius.circular(8),
                                      color: appbar_color,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                ],

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

            if(hasPermissionInCategory('Maintenance'))...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _buildDashboardButton(Icons.build, 'Maintenance', appbar_color, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceTicketReport()))),
              ]),
              SizedBox(height: 10),
            ],

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if(hasPermissionInCategory('Request'))...[
                _buildDashboardButton(Icons.credit_card, 'Request', Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestListScreen()))),

              ],
              if(hasPermissionInCategory('Available Units'))...[
                _buildDashboardButton(Icons.home, 'Available Units', Colors.orangeAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AvailableUnitsReport()))),
              ]
            ]),
            SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildDashboardButton(Icons.upload_file, 'KYC Update', Colors.tealAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DecentTenantKYCForm()))),

            if(hasPermission('canCreateComplaintSuggestion') || hasPermission('canViewComplaintSuggestions'))...[
              _buildDashboardButton(Icons.info_outline, 'Complaints/Suggestions', Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintListScreen()))),

              ]
            ]),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  Future<Map<String, dynamic>> fetchUserDetails({required bool isLandlord}) async {
    final String apiUrl = isLandlord
        ? '$baseurl/landlord/$user_id'
        : '$baseurl/tenant/$user_id';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Accept': 'application/json',
        }
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);


        // ✅ Adjust parsing based on landlord/tenant
        if (isLandlord) {
          return data['data']?['landlord'] ?? {};
        } else {
          return data['data']?['tenant'] ?? {};
        }
      } else {
        throw Exception('Failed to fetch profile. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return {};
    }
  }

  void _showUserProfileBottomSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
        builder: (context) {
          return FutureBuilder<Map<String, dynamic>>(
            future: fetchUserDetails(isLandlord: is_landlord),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final user = snapshot.data!;
              String mobile = user['mobile_no'] ?? user['phone_no'] ?? '-';


              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), // ⬅️ reduced bottom padding
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // 👈 This makes the height wrap content
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            // Avatar & Name
                            // Avatar + Name + Email (Centered vertically)
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.orange,
                                    child: Text(
                                      user['name']?.isNotEmpty == true
                                          ? user['name'][0].toUpperCase()
                                          : '?',
                                      style:  GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    user['name'] ?? 'N/A',
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user['email'] ?? '-',
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),


                            const SizedBox(height: 16),
                            Divider(),

                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.withOpacity(1.0),

                                child: Icon(Icons.phone, color: Colors.white),
                              ),
                              title: Text(
                                "Mobile No",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              subtitle: Text(
                                mobile,
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              ),
                            ),

                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(1.0),

                                child: Icon(Icons.badge, color: Colors.white),
                              ),
                              title: Text(
                                "Emirates ID",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              subtitle: Text(
                                user['emirates_id']?? "N/A",
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              ),
                            ),

                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.brown.withOpacity(1.0),

                                child: Icon(Icons.airplane_ticket, color: Colors.white),
                              ),
                              title: Text(
                                "Passport No",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              subtitle: Text(
                                user['passport_no']?? 'N/A',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              ),
                            ),

                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withOpacity(1.0),

                                child: Icon(Icons.language, color: Colors.white),
                              ),
                              title: Text(
                                "Nationality",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              subtitle: Text(
                                user['nationality']?? "N/A",
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Close Icon (top-right)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty) return SizedBox.shrink();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: appbar_color.withOpacity(1.0),

        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
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
class _AnimatedReminderDialog extends StatefulWidget {
  final String contractNo;
  final String expiryText;
  final int daysLeft;
  final List flats;

  const _AnimatedReminderDialog({
    required this.contractNo,
    required this.expiryText,
    required this.daysLeft,
    required this.flats,
  });

  @override
  State<_AnimatedReminderDialog> createState() => _AnimatedReminderDialogState();
}

class _AnimatedReminderDialogState extends State<_AnimatedReminderDialog> {
  bool flash = true;
  double opacity = 0.0;
  int secondsLeft = 10;

  Timer? _flashTimer;
  Timer? _fadeTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    // Fade in
    Future.delayed(Duration.zero, () {
      setState(() {
        opacity = 1.0;
      });
    });

    // Flashing icon/text
    _flashTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          flash = !flash;
        });
      }
    });

    // Countdown and fade out
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          secondsLeft--;
        });

        if (secondsLeft <= 0) {
          _startFadeOutAndClose();
          timer.cancel();
        }
      }
    });
  }

  void _startFadeOutAndClose() {
    setState(() {
      opacity = 0.0;
    });
    _fadeTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _fadeTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final daysLeft = widget.daysLeft;

    return AnimatedOpacity(
      opacity: opacity,
      duration: Duration(milliseconds: 500),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.all(20),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: flash ? Colors.amber.shade700 : Colors.amber.shade300,
                      size: 24,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reminder',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: flash ? Colors.amber.shade700 : Colors.amber.shade300,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: daysLeft < 0 || daysLeft <= 3
                        ? Colors.red.shade50
                        : Colors.yellow.shade50,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    daysLeft < 0 || daysLeft <= 3
                        ? Icons.error_outline
                        : Icons.access_time,
                    size: 48,
                    color: daysLeft < 0 || daysLeft <= 3
                        ? Colors.redAccent
                        : Colors.amber.shade700,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Contract: ${widget.contractNo}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  widget.expiryText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: daysLeft < 0 || daysLeft <= 3
                        ? Colors.redAccent
                        : Colors.amber.shade700,
                  ),
                ),
                SizedBox(height: 12),
                Divider(color: Colors.grey.shade300),
                ...widget.flats.map((flat) {
                  final flatName = flat['name'] ?? 'N/A';
                  final buildingName = flat['building']?['name'] ?? 'N/A';
                  final areaName = flat['building']?['area']?['name'] ?? 'N/A';
                  final stateName = flat['building']?['area']?['state']?['name'] ?? 'N/A';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      'Unit: $flatName • $buildingName ($areaName, $stateName)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  );
                }).toList(),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Please review this contract and take necessary action.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _countdownTimer?.cancel();
                    _startFadeOutAndClose();
                  },
                  icon: Icon(Icons.check_circle_outline, size: 18),
                  label: Text('Got it (${secondsLeft}s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
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

Widget _buildUnitTile({
  required BuildContext context,
  required Map flat,
  required Color badgeColor,
  required int? loadingFlatId,
  required Future<void> Function(int flatId, String category) onTapFetch,
}) {
  final int flatId = flat['id'] ?? -1;
  final isLoading = loadingFlatId == flatId;

  final flatName = flat['name']?.toString() ?? 'N/A';
  final flatType = flat['flat_type']?['name']?.toString() ?? 'N/A';

  final String category = flat['status'] ?? "";

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: GestureDetector(
      onTap: () => onTapFetch(flatId, category),   // 👈 send both
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: badgeColor.withOpacity(0.15)),
          child: Icon(Icons.home_outlined, color: badgeColor, size: 24),
        ),
        title: Text('Unit $flatName', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text('Type: $flatType',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),

      ),

    ),
  );
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