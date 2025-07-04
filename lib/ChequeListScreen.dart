import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/AdminDashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ChequeListScreen extends StatefulWidget {
  final String? statusFilter;

  const ChequeListScreen({Key? key, this.statusFilter}) : super(key: key); // <- Update constructor

  @override
  State<ChequeListScreen> createState() => _ChequeListScreenState();
}

class _ChequeListScreenState extends State<ChequeListScreen> {
  List<dynamic> allCheques = [];
  bool isLoading = true;

   DateTime? _startDate;
   DateTime? _endDate;
  List<dynamic> filteredCheques = [];

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

    if (startDateString != null && endDateString != null) {
      _startDate = DateTime.parse(startDateString);
      _endDate = DateTime.parse(endDateString);
    } else {
      // Fallback in case no dates are stored
      DateTime now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    }

    prefs.setString("startdate", _startDate!.toIso8601String());
    prefs.setString("enddate", _endDate!.toIso8601String());

    fetchCheques();
  }

  Future<void> _showChequeDetailsDialogFromCard(Map<String, dynamic> cheque) async {
    try {
      final payment = cheque['payment'];
      final rentalReceipt = payment['rental_payments']?['receipt'];
      final salesReceipt = payment['sales_payments']?['receipt'];
      final contract = rentalReceipt?['contract'] ?? salesReceipt?['contract'];
      final flats = contract?['flats'] ?? [];
      final flatNames = flats.map((f) => f['flat']['name']).join(', ');
      final buildingName = flats.isNotEmpty ? flats[0]['flat']['building']['name'] : '-';
      final areaName = flats.isNotEmpty ? flats[0]['flat']['building']['area']['name'] : '-';
      final emirateName = flats.isNotEmpty ? flats[0]['flat']['building']['area']['state']['name'] : '-';

      final isReceived = cheque['is_received'].toString().toLowerCase() == 'true';
      final isDeposited = cheque['is_deposited'].toString().toLowerCase() == 'true';

      final returnedOn = payment['returned_on'];
      final depositedOn = cheque['deposited_on'];
      final clearedOn = cheque['cleared_on'];
      final receivedOn = payment['received_date'];

      String statusLabel = '';
      String statusDate = '';

      if (returnedOn != null) {
        statusLabel = "Returned On";
        statusDate = formatDate(returnedOn);
      } else if (isReceived && isDeposited && clearedOn == null && depositedOn != null) {
        statusLabel = "Deposited On";
        statusDate = formatDate(depositedOn);
      } else if (isReceived && isDeposited && clearedOn != null) {
        statusLabel = "Cleared On";
        statusDate = formatDate(clearedOn);
      } else if (isReceived && receivedOn != null) {
        statusLabel = "Received On";
        statusDate = formatDate(receivedOn);
      }

      double screenHeight = MediaQuery.of(context).size.height;
      double maxDialogHeight = screenHeight * 0.8;

      showDialog(
        context: context,
        builder: (_) => Dialog(
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
                          Icon(Icons.receipt_long, color: Colors.white, size: 40),
                          SizedBox(height: 8),
                          Text(
                            "AED ${payment['amount_incl']}",
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

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDetailTile(Icons.credit_card, "Type", payment['payment_type'] ?? '-'),
                            if (statusLabel.isNotEmpty)
                              _buildDetailTile(Icons.calendar_today, statusLabel, statusDate),
                            _buildDetailTile(Icons.text_snippet, "Description", payment['description'] ?? '-'),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.home_work, color: appbar_color.shade200),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Unit(s)",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: flats.map<Widget>((f) {
                                            final flatName = f['flat']['name'];
                                            return Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                border: Border.all(color: appbar_color.withOpacity(0.4)),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                flatName,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: appbar_color.shade700,
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

                            _buildDetailTile(Icons.business, "Building", buildingName),
                            _buildDetailTile(Icons.location_on, "Location", "$areaName, $emirateName"),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 10),

                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
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
        ),
      );
    } catch (e) {
      print("Error showing cheque details: $e");
      return;
    }
  }


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

  Future<void> fetchCheques() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseurl/reports/admin/cheques'),
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        allCheques = data['data'] ?? [];
        _applyDateFilter();
      } else {
        allCheques = [];
      }
    } catch (e) {
      print("Error fetching cheques: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      prefs.setString("startdate", _startDate!.toIso8601String());
      prefs.setString("enddate", _endDate!.toIso8601String());
      _applyDateFilter(); // Step 2: Re-filter when user updates date
    }
  }

  String _getChequeStatus(Map<String, dynamic> cheque) {
    final payment = cheque['payment'];
    final isReceived = cheque['is_received'].toString().toLowerCase() == 'true';
    final isDeposited = cheque['is_deposited'].toString().toLowerCase() == 'true';
    final returnedOn = _parseDate(payment?['returned_on']);
    final depositedOn = _parseDate(cheque['deposited_on']);
    final clearedOn = _parseDate(cheque['cleared_on']);

    if (returnedOn != null) return 'Returned';
    if (isReceived && isDeposited && clearedOn != null) return 'Cleared';
    if (isReceived && isDeposited && clearedOn == null) return 'Deposited';
    if (isReceived && !isDeposited) return 'Received';
    return 'Pending';
  }


  void _applyDateFilter() {
    setState(() {
      filteredCheques = allCheques.where((cheque) {
        final payment = cheque['payment'];
        if (payment == null) return false;

        final status = _getChequeStatus(cheque);

        // Only include if status matches
        if (widget.statusFilter != null && widget.statusFilter!.isNotEmpty) {
          return status == widget.statusFilter;
        }
        return true;
      }).toList();

      // Sort by date
      filteredCheques.sort((a, b) {

        final dateA = _parseDate(a['date']) ?? DateTime(1900);
        final dateB = _parseDate(b['date']) ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    });
  }

  String _getStatusLabel(Map<String, dynamic> cheque) {
    DateTime? returnedOn = _parseDate(cheque['payment']?['returned_on']);
    DateTime? receivedOn = _parseDate(cheque['payment']?['received_date']);
    DateTime? clearedOn = _parseDate(cheque['cleared_on']);
    DateTime? depositedOn = _parseDate(cheque['deposited_on']);

    DateTime? chequeDate = _parseDate(cheque['date']);

    final isReceived = cheque['is_received'].toString().toLowerCase() == 'true';
    final isDeposited = cheque['is_deposited'].toString().toLowerCase() == 'true';

    // Normalize to remove time part
    DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    final start = normalize(_startDate!);
    final end = normalize(_endDate!);

    if (returnedOn != null &&
        !normalize(returnedOn).isBefore(start) &&
        !normalize(returnedOn).isAfter(end)) {
      return 'Returned';
    }

    if (isReceived && isDeposited && clearedOn == null &&
        depositedOn != null &&
        !depositedOn.isBefore(_startDate!) &&
        !depositedOn.isAfter(_endDate!)) {
      return 'Deposited';
    }

    if (isReceived && !isDeposited &&
        receivedOn != null &&
        !normalize(receivedOn).isBefore(start) &&
        !normalize(receivedOn).isAfter(end)) {
      return 'Received';
    }

    if (isReceived && isDeposited &&
        clearedOn != null &&
        !normalize(clearedOn).isBefore(start) &&
        !normalize(clearedOn).isAfter(end)) {
      return 'Cleared';
    }

    if (!isReceived && !isDeposited &&
        chequeDate != null &&
        !normalize(chequeDate).isBefore(start) &&
        !normalize(chequeDate).isAfter(end)) {
      return 'Pending';
    }

    return '';
  }

  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr.toString());
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      return DateFormat('dd-MMM-yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return "N/A";
    }
  }

  Widget buildStatusChip(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'Returned':
        icon = Icons.assignment_return;
        color = Colors.red.shade700;
        break;
      case 'Received':
        icon = Icons.check;
        color = Colors.green.shade700;
        break;
      case 'Deposited':
        icon = Icons.inventory_2;
        color = Colors.teal.shade600;
        break;
      case 'Cleared':
        icon = Icons.verified;
        color = appbar_color.shade400;
        break;
      case 'Pending':
        icon = Icons.access_time;
        color = Colors.orangeAccent.shade400;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(status, style: GoogleFonts.poppins(fontSize: 13, color: color,fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cheque(s)", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
        backgroundColor: appbar_color.withOpacity(0.9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => {
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(
          builder: (_) => AdminDashboard(),
          ),
          )
          }
        ),
      ),
      body: Container(
        color: Colors.white,
        child:  Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: appbar_color, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: appbar_color, size: 18),
                      SizedBox(width: 12),
                      Expanded(

                        child: _startDate != null && _endDate != null
                            ? Text(
                          "${DateFormat('dd-MMM-yyyy').format(_startDate!)} - ${DateFormat('dd-MMM-yyyy').format(_endDate!)}",
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                          textAlign: TextAlign.center,
                        )
                            : Center(child: CircularProgressIndicator()), // or SizedBox.shrink()
                      ),

                      Icon(Icons.calendar_today, color: appbar_color, size: 18),
                    ],
                  ),
                ),
              ),
            ),

              isLoading
                  ? Expanded(
                child: Center(
                  child: Platform.isIOS
                      ? const CupertinoActivityIndicator(radius: 18)
                      : CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
                  ),
                )
              )
                  : filteredCheques.isEmpty
                  ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        "No cheques found from ${DateFormat('dd-MMM-yyyy').format(_startDate!)} to ${DateFormat('dd-MMM-yyyy').format(_endDate!)}",
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
               : Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredCheques.length,
                  itemBuilder: (context, index) {
                    final cheque = filteredCheques[index];
                    final status = _getChequeStatus(cheque);

                    final payment = cheque['payment'];
                    final rentalReceipt = payment['rental_payments']?['receipt'];
                    final salesReceipt = payment['sales_payments']?['receipt'];
                    final contract = rentalReceipt?['contract'] ?? salesReceipt?['contract'];
                    final flats = contract?['flats'] ?? [];
                    final firstFlat = flats.isNotEmpty ? flats[0]['flat'] : null;
                    final building = firstFlat?['building'];
                    final area = building?['area'];
                    final state = area?['state'];

                    // Inside itemBuilder (before returning the card)
                    final isReceived = cheque['is_received'].toString().toLowerCase() == 'true';
                    final isDeposited = cheque['is_deposited'].toString().toLowerCase() == 'true';
                    final returnedOn = cheque['payment']?['returned_on'];
                    final clearedOn = cheque['cleared_on'];
                    final receivedOn = cheque['received_on'];
                    final depositedOn = cheque['deposited_on'];


                    String dateLabel = "Pending";
                    String dateValue = "-";

                    if (returnedOn != null) {
                      dateLabel = "Returned On";
                      dateValue = formatDate(returnedOn);
                    } if (isReceived && isDeposited && clearedOn != null) {
                      dateLabel = "Cleared On";
                      dateValue = formatDate(clearedOn);
                    }
                    else if (isReceived && isDeposited && clearedOn == null && depositedOn != null) {
                      dateLabel = "Deposited On";
                      dateValue = formatDate(depositedOn);
                    }
                    else if (isReceived && receivedOn != null) {
                      dateLabel = "Received On";
                      dateValue = formatDate(receivedOn);
                    }
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "AED ${payment['amount_incl']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              buildStatusChip(status.isNotEmpty ? status : 'Pending'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text("Type: ${payment['payment_type'] ?? 'N/A'}",
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800])),
                          if (payment['description'] != null) ...[
                            SizedBox(height: 4),
                            Text("Note: ${payment['description']}",
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                          ],
                          Divider(height: 20, color: Colors.grey.shade300),
                          Row(
                            children: [
                              Icon(Icons.apartment, size: 16, color: Colors.indigo),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${firstFlat?['name']} • ${building?['name']}",
                                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${area?['name']}, ${state?['name']}",
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),

                          if(dateLabel!='Pending')...[
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "$dateLabel: $dateValue",
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                          ],

                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.remove_red_eye_outlined, color: appbar_color),
                              tooltip: 'View Details',
                              onPressed: () => _showChequeDetailsDialogFromCard(cheque),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
