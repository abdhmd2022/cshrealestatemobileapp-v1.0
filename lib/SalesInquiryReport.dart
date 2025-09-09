import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cshrealestatemobile/CreateSalesInquiry.dart';
import 'package:cshrealestatemobile/FollowupSalesInquiry.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'AdminDashboard.dart';
import 'AvailableUnitsReport.dart';
import 'Sidebar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'dart:async' show unawaited;


class SalesInquiryReport extends StatefulWidget {
  @override
  _SalesInquiryReportState createState() => _SalesInquiryReportState();
}

class InquiryModel {
  final String customerName;
  final String unitType;
  final String area;
  final String emirate;
  final String description;
  final String contactNo;
  final String whatsapp_no;
  final String email;
  final String inquiryNo;
  final String creationDate;
  final double minPrice;
  final String created_by;
  final String assigned_to;
  final double maxPrice;
  final String status;
  final String leadStatusCategory;
  final String lastFollowupRemarks;
  final String interest_type;
  final String lastFollowupDate;
  // final String color;
  final List<Map<String, dynamic>> preferredAreas;
  final List<Map<String, dynamic>> preferredFlatTypes;
  final List<Map<String, dynamic>> preferredAmenities;

  InquiryModel({
    required this.customerName,
    required this.unitType,
    required this.area,
    required this.emirate,
    required this.created_by,
    required this.assigned_to,
    required this.description,
    //required this.color,
    required this.lastFollowupRemarks,
    required this.lastFollowupDate,
    required this.contactNo,
    required this.email,
    required this.inquiryNo,
    required this.leadStatusCategory,
    required this.creationDate,
    required this.interest_type,

    required this.minPrice,
    required this.maxPrice,
    required this.status,
    required this.preferredAreas,
    required this.preferredFlatTypes,
    required this.preferredAmenities,
    required this.whatsapp_no,

  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'] ?? '';
    final interest_type = json['interest_type'] ?? '';

    final formattedDate = _formatDate(rawDate);
    final areas = (json['preferred_areas'] as List<dynamic>?)
        ?.map((area) => area['area']['name'])
        .join(', ') ??
        'No areas specified';

    // Fetch and concatenate emirates
    final emirates = (json['preferred_areas'] as List<dynamic>?)
        ?.map((area) => area['area']['state']['name'].toString())
        .toSet() // Use a Set to ensure uniqueness
        .join(', ') ??
        'No emirates specified';


    final flatTypes = (json['preferred_flat_types'] as List<dynamic>?)
        ?.map((flatType) => flatType['type']['name'])

        .join(', ') ??
        'No unit type specified';

    final List<dynamic>? leadsFollowup = json['followups'];

    String leadStatusName= '';// Extract the last follow-up and its lead status name
    String leadStatusCategory= '';
    // String leadStatusColor= '';
    String lastFollowupRemarks = 'No remarks available';
    String lastFollowupDate = 'No follow-up date';

    final created_by = (json['created_user'] as Map<String, dynamic>?)?['name'] ?? 'N/A';

    final assigned_to = (json['assigned_to_user'] as Map<String, dynamic>?)?['name'] ?? '';

    if (leadsFollowup != null && leadsFollowup.isNotEmpty) {

      leadsFollowup.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      final lastFollowup = leadsFollowup.first;
      leadStatusName = lastFollowup['status']?['name'] ?? 'Unknown';
      leadStatusCategory = lastFollowup['status']?['category'] ?? 'Unknown';
      //leadStatusColor = lastFollowup['lead_status']?['color'] ?? 'Unknown';
      lastFollowupRemarks = lastFollowup['remarks'] ?? 'null';
      lastFollowupDate = _formatDate(lastFollowup['date'] ?? '');

      print('Last Lead Status Name: $leadStatusName');
    } else {
      print('No follow-up records found.');
    }

    return InquiryModel(
      customerName: json['name'] ?? 'Unknown',
      unitType: flatTypes,
      area: areas,
      interest_type: interest_type,
      emirate: emirates,
      description: json['description'] ?? 'No description',
      contactNo: json['mobile_no'] ?? 'N/A',
      whatsapp_no : json['whatsapp_no'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      created_by: created_by ?? '',
      assigned_to: assigned_to ?? '',
      lastFollowupRemarks: lastFollowupRemarks,
      lastFollowupDate: lastFollowupDate ,
      // color: leadStatusColor,

      inquiryNo: json['id'].toString(),
      creationDate: formattedDate,
      leadStatusCategory: leadStatusCategory,

      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
      status: leadStatusName ,
      preferredAreas: (json['preferred_areas'] as List<dynamic>?)
          ?.map((area) => area as Map<String, dynamic>)
          .toList() ??
          [],
      preferredFlatTypes: (json['preferred_flat_types'] as List<dynamic>?)
          ?.map((flatType) => flatType as Map<String, dynamic>)
          .toList() ??
          [],
      preferredAmenities: (json['preferred_amenities'] as List<dynamic>?)
          ?.map((amenity) => amenity as Map<String, dynamic>)
          .toList() ??
          [],
    );
  }








  /// Helper method to safely extract nested values
  static String _formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return rawDate; // Return the raw date if parsing fails
    }
  }
}

class _SalesInquiryReportState extends State<SalesInquiryReport> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<InquiryModel> salesinquiry = [];

  List<InquiryModel> filteredInquiries = [];
  String searchQuery = "";

  List<bool> _expandedinquirys = [];

  List<InquiryStatus> inquirystatus_list = [];
  String? selectedStatus;
  bool isStatusLoading = true; // Track lead status loading

  List<dynamic> leadFollowupHistoryList = [];

  bool isLoading = false;

  int inquiryCurrentPage = 1;
  int totalInquiryPages = 1;
  bool isFetchingMoreInquiries = false;

  @override
  void initState() {
    super.initState();
    fetchLeadStatus();
  }

  Future<void> _sendTicketEmailSMTP({
    required String toEmail,
    required String toName,
    required String subject,
    required String htmlBody,
  }) async {
    if (kIsWeb) {
      Fluttertoast.showToast(
        msg: 'SMTP email is not supported on Web (use server-side).',
        backgroundColor: Colors.black, textColor: Colors.white,
      );
      return;
    }

    final smtpServer = SmtpServer(
      kSmtpHost,
      port: kSmtpPort,
      ssl: kSmtpUseSsl,
      username: kSmtpUsername,
      password: kSmtpPassword,
    );

    final message = Message()
      ..from = Address(kFromEmail, kFromName)
      ..recipients.add(Address(toEmail, toName))
      ..subject = subject
      ..html = htmlBody;

    /*final message = Message()
      ..from = Address(kFromEmail, kFromName)
      ..recipients.add(Address("anish@ca-eim.com","Anish"))
      ..subject = subject
      ..html = htmlBody;*/

    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('SMTP error: $e');
    }
  }


  void _showTransferDialog(BuildContext context, InquiryModel inquiry) {
    String? selectedUserId;
    List<Map<String, dynamic>> users = [];
    bool isLoading = true;

    // Fetch User List
    Future<void> fetchUsers(StateSetter setState) async {
      try {
        final response = await http.get(
          Uri.parse("$baseurl/user"),
          headers: {
            'Authorization': 'Bearer $Company_Token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final List<dynamic> usersJson = data['data']['users'];

            users = usersJson
                .where((user) => user['id'] != user_id) // 👈 Exclude current user
                .map((userJson) {
              return {
                'id': userJson['id'].toString(),
                'name': userJson['name'],
                'email': userJson['email'] as String? ?? '', // <-- add this

              };
            }).toList();
          }
        }
      } catch (e) {
        print("Error fetching users: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }

    // Show Dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Fetch only once after first build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isLoading) fetchUsers(setState);
            });

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              title: Text(
                "Transfer Inquiry",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    Center(
                      child: Platform.isIOS
                          ? CupertinoActivityIndicator(radius: 15)
                          : CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(appbar_color),
                      ),
                    )
                  else if (users.isEmpty)
                    Text(
                      "No users available.",
                      style: GoogleFonts.poppins(color: Colors.black87),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedUserId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Select User",
                        labelStyle: GoogleFonts.poppins(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: appbar_color, width: 1),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.black87),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      items: users.map<DropdownMenuItem<String>>((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'].toString(),
                          child: Text(
                            user['name'],
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedUserId = newValue;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(
                        color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedUserId == null) {
                      Fluttertoast.showToast(msg: "Please select user!");
                      return;
                    }
                    final selectedUser = users.firstWhere((u) => u['id'] == selectedUserId);
                    _submitTransfer(
                      inquiry,
                      selectedUserId!,
                      selectedUser['email'] ?? '',
                      selectedUser['name'] ?? '',
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    elevation: 3,
                  ),
                  child: Text(
                    "Submit",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int? _priceByStatus(Flat u, String status) {
    final s = status.trim().toLowerCase();
    if (s == 'buy') return u.basicSaleValue;
    // default to rent
    return u.basicRent;
  }


  Future<List<Flat>> _fetchAvailableUnits({
    required String status,         // "Rent" or "Buy"
    required List<String> unitTypes, // e.g. ["1BHK","2BHK"]
    required double minPrice,
    required double maxPrice,
  }) async {
    final List<Flat> result = [];

    int page = 1;
    int totalPages = 1;

    final headers = {
      'Authorization': 'Bearer $Company_Token',
      'Content-Type': 'application/json',
    };

    while (page <= totalPages) {
      final url =
          "$baseurl/reports/flat/available/date""?date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}"
          "&status=$status"
          "&page=$page";

      final resp = await http.get(Uri.parse(url), headers: headers);
      if (resp.statusCode != 200) {
        // If any page fails, stop gracefully
        break;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic> flatsJson = data["data"]?["flats"] ?? [];

      // Map to Flat
      final pageFlats = flatsJson.map<Flat>((j) => Flat.fromJson(j as Map<String, dynamic>)).toList();

      // Filter: same unit type + price within range
      for (final f in pageFlats) {
        // Unit type match (exact string; if your types differ, adjust matcher)
        final matchesType = unitTypes.contains(f.flatTypeName);
        if (!matchesType) continue;

        final price = _priceByStatus(f, status);
        if (price == null) continue;

        if (price >= minPrice && price <= maxPrice) {
          result.add(f);
        }
      }

      // read meta for pagination
      final meta = data["meta"];
      if (meta != null) {
        final totalCount = (meta["totalCount"] ?? 0) as int;
        int size = (meta["size"] ?? 1) as int;
        if (size == 0) size = 1;
        totalPages = (totalCount / size).ceil();
      } else {
        totalPages = 1;
      }
      page++;
    }

    return result;
  }


  Future<void> _submitTransfer(InquiryModel inquiry, String userId,String recipientEmail, String recipientName) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseurl/lead/${inquiry.inquiryNo}"),
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'assigned_to': userId,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {


        String successMessage = data['message'] ?? "Transfer successful!"; // Extract message

        // Show toast with the response message
        Fluttertoast.showToast(
          msg: successMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: appbar_color,
          textColor: Colors.white,
        );

        fetchInquiries();

        final String customerName   = inquiry.customerName.isEmpty
            ? 'Customer' : inquiry.customerName;
        final String interestType   = inquiry.interest_type;
        final String propertyType   = (inquiry.unitType ?? '').toString();
        final String priceRange     = _formatCurrencyRange(
          inquiry.minPrice.round(),
          inquiry.maxPrice.round(),
        );

        // minimal email HTML
        final html = _buildInquiryTransferEmailHtmlMinimal(
          assigneeName: recipientName.isEmpty ? 'Teammate' : recipientName,
          assignedBy: (user_name.isNotEmpty ? user_name : 'Admin'),
          customerName: customerName,
          interestType: interestType,
          propertyType: propertyType,
          priceRange: priceRange,
        );

        // fire-and-forget (no UI delay)
        if (recipientEmail.isNotEmpty) {
          unawaited(
            _sendTicketEmailSMTP(
              toEmail: recipientEmail,
              toName: recipientName.isEmpty ? 'Teammate' : recipientName,
              subject: 'New Inquiry Assigned - #${inquiry.inquiryNo}',
              htmlBody: html,
            ).catchError((e, st) => debugPrint('Transfer email error: $e')),
          );
        }




      } else {
        String successMessage = data['message'] ?? "Transfer successful!"; // Extract message

        // Show toast with the response message
        Fluttertoast.showToast(
          msg: successMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: appbar_color,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<void> fetchLeadStatus() async {
    setState(() {
      isStatusLoading = true; // Start loading
    });

    inquirystatus_list.clear();

    final url = '$baseurl/lead/status';
    String token = 'Bearer $Company_Token'; // Auth token

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          List<dynamic> leadStatusList = data['data']['leadStatus'];

          for (var status in leadStatusList) {
            InquiryStatus followUpStatus = InquiryStatus.fromJson(status);
            inquirystatus_list.add(followUpStatus);
          }

          // ✅ Add hardcoded "All" option at the beginning
          inquirystatus_list.insert(0, InquiryStatus(id: 0, name: "All", category: "All"));

          // ✅ Automatically select first "Normal" category status, fallback to "All"
          InquiryStatus? firstNormalStatus = inquirystatus_list.firstWhere(
                (status) => status.category == "All",

            orElse: () => inquirystatus_list.first, // Defaults to "All" if none found
          );

          selectedStatus = firstNormalStatus.name; // ✅ Set first "Normal" category status


          isStatusLoading = false; // Stop loading
        });

        // ✅ Fetch inquiries after lead statuses are loaded
        fetchInquiries();
      } else {
        throw Exception('Failed to load lead statuses');
      }
    } catch (e) {
      print('Error fetching lead status: $e');
      setState(() {
        isStatusLoading = false;
      });
    }
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case "Normal":
        return Colors.green;
      case "Drop":
        return Colors.red;

      case "Close":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Icon getCategoryIcon(String category) {
    switch (category) {
      case "Drop":
        return Icon(Icons.cancel, size: 16, color: Colors.red);
      case "Close":
        return Icon(Icons.check_circle, size: 16, color: Colors.green);
      case "Normal":
        return Icon(Icons.check_circle, size: 16, color: Colors.green);
      default:
        return Icon(Icons.help_outline, size: 16, color: Colors.grey);
    }
  }

  Color getFollowUpDateColor(String? followUpDate) {
    if (followUpDate == null) return Colors.grey;

    DateTime followUp = DateTime.parse(followUpDate);
    DateTime today = DateTime.now();

    if (followUp.isBefore(today.subtract(Duration(days: 1)))) {
      return Colors.red; // Show red if next follow-up date is before today
    } else {
      return Colors.grey.shade600; // Show blue for today and future dates
    }
  }

  void _showPopup(BuildContext context,String id) async {
    List<dynamic> filteredData = [];

    try {
      filteredData = await fetchLeadHistory(id);
    } catch (e) {
      print('Error fetching data: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          height: MediaQuery.of(context).size.height * 0.6,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lead Follow-ups",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              // Content
              Expanded(
                child: filteredData.isEmpty
                    ? Center(child: Text("No Follow-ups Found"))
                    : ListView.builder(
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    var item = filteredData.reversed.toList()[index];
                    String category = item["status"]["category"];
                    Color statusColor = getCategoryColor(category);
                    String? nextFollowUpDate = item["next_followup_date"];
                    Color followUpDateColor = getFollowUpDateColor(nextFollowUpDate);
                    String followup_type = item["followup_type"]?['name']?? "" ;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                        child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                          ),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["created_user"]["name"],
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  getCategoryIcon(item["status"]["category"]),
                                  SizedBox(width: 6),
                                  Text(
                                    item["status"]["name"],
                                    style: GoogleFonts.poppins(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              if (followup_type.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(
                                  "Follow-up Type: ${followup_type}",
                                  style: GoogleFonts.poppins(color: Colors.grey.shade700),
                                ),
                              ],
                              SizedBox(height: 8),
                              Text(
                                "Date: ${formatDate(item["date"])}",
                                style: GoogleFonts.poppins(color: Colors.grey.shade700),
                              ),

                              if (item["remarks"] != null) ...[
                                SizedBox(height: 6),
                                Text(
                                  "Remarks: ${item["remarks"]}",
                                  style: GoogleFonts.poppins(color: Colors.grey.shade700),
                                ),
                              ],
                              if (nextFollowUpDate != null) ...[
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "Next Follow-up: ",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "${formatDate(nextFollowUpDate)}",
                                      style: GoogleFonts.poppins(
                                        color: followUpDateColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )])]]))));}))]));
      });
  }

  bool shouldRestrictAction(InquiryModel inquiry) {
    if (is_admin && is_admin_from_api) return false; // Superadmin can always act

    final createdBy = inquiry.created_by.trim().toLowerCase();
    final assignedTo = inquiry.assigned_to.trim().toLowerCase();
    final current = user_name.trim().toLowerCase();

    return createdBy == current && assignedTo != current && assignedTo.isNotEmpty;
  }

  Future<List<dynamic>> fetchLeadHistory(String id) async {

    leadFollowupHistoryList.clear();

    final url = '$baseurl/lead/followup/?lead_id=$id';

    String token = 'Bearer $Company_Token'; // Auth token

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      leadFollowupHistoryList = jsonData["data"]["leadFollowUps"];
      // Filter only where lead_id == 6

      return leadFollowupHistoryList;
    } else {
      throw Exception('Failed to load lead statuses');
    }
  }

  List<InquiryModel> parseInquiries(Map<String, dynamic> jsonResponse) {
    final leads = jsonResponse['data']?['leads'] as List<dynamic>? ?? [];
    return leads.map((lead) => InquiryModel.fromJson(lead)).toList();
  }
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1); // ✅ First day of current month
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0); // ✅ Last day of current month
  bool showFilters = false; // ✅ Toggle filter visibility

  Future<void> fetchInquiries() async {
    setState(() {
      isLoading = true;
    });

    List<InquiryModel> allInquiries = [];
    int currentPage = 1;
    int totalPages = 1; // default to 1, will update after first call

    String token = 'Bearer $Company_Token';
    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    try {
      while (currentPage <= totalPages) {
        print('Fetching inquiries page $currentPage...');
        final url = '$baseurl/lead?page=$currentPage';

        final response = await http.get(Uri.parse(url), headers: headers);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          final List<dynamic> leads = jsonResponse['data']['leads'] ?? [];

          List<dynamic> filteredLeads = leads;
          if (is_admin && !is_admin_from_api) {
            filteredLeads = leads.where((lead) {
              final assignedTo = lead['assigned_to'];
              final createdBy = lead['created_by'];
              return assignedTo == user_id || createdBy == user_id;
            }).toList();
          }

          final parsedLeads = filteredLeads
              .map<InquiryModel>((lead) => InquiryModel.fromJson(lead))
              .toList();

          allInquiries.addAll(parsedLeads);

          // set totalPages from meta only once
          if (currentPage == 1 && jsonResponse.containsKey('meta')) {
            final meta = jsonResponse['meta'];
            totalPages = (meta['totalCount'] / meta['size']).ceil();
          }

          currentPage++;
        } else {
          throw Exception('Failed to load page $currentPage');
        }
      }

      // Reverse once after all data is collected
      salesinquiry = allInquiries;
      _expandedinquirys = List.generate(salesinquiry.length, (index) => false);

      filterInquiries();
    } catch (e) {
      print('Error fetching inquiries: $e');
    }

    setState(() {
      isLoading = false;
      isFetchingMoreInquiries = false;
    });
  }

  String validationMessage = ""; // ✅ Holds the "No results found" message

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      validationMessage = ""; // ✅ Reset validation message

      if (query.isEmpty) {
        // ✅ If search is cleared, restore the last valid filtered inquiries
        filterInquiries();
      } else {
        // ✅ Keep a temporary list for search results
        List<InquiryModel> tempSearchResults = filteredInquiries
            .where((inquiry) =>
        inquiry.customerName.toLowerCase().contains(query.toLowerCase()) ||
            inquiry.unitType.toLowerCase().contains(query.toLowerCase()) ||
            inquiry.area.toLowerCase().contains(query.toLowerCase()) ||
            inquiry.emirate.toLowerCase().contains(query.toLowerCase()) ||
            inquiry.status.toLowerCase().contains(query.toLowerCase()) ||
            inquiry.inquiryNo.toString().toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (tempSearchResults.isNotEmpty) {
          // ✅ Only update `filteredInquiries` if search returns results
          filteredInquiries = tempSearchResults;
        } else {
          // ✅ If no results, show validation message but do not erase filtered list
          validationMessage = "No results found for \"$query\"";
        }
      }
    });
  }

  void filterInquiries() {
    print("Filtering inquiries...");
    print("Selected Date Range: ${DateFormat('dd MMM, yyyy').format(startDate)} - ${DateFormat('dd MMM, yyyy').format(endDate)}");

    setState(() {
      filteredInquiries = salesinquiry.where((inquiry) {
        // ✅ Convert `lastFollowupDate` to DateTime
        DateTime? followupDate;
        try {
          followupDate = DateTime.parse(inquiry.lastFollowupDate);
        } catch (e) {
          print("Invalid Date: ${inquiry.lastFollowupDate}"); // ✅ Debugging
          followupDate = null;
        }

        // ✅ Debug: Print Each Inquiry's Date
        print("Inquiry ID: ${inquiry.inquiryNo}, Last Follow-up Date: ${inquiry.lastFollowupDate}");

        // ✅ Apply date range filter
        bool withinDateRange = followupDate != null &&
            followupDate.isAtSameMomentAs(startDate) || followupDate!.isAfter(startDate.subtract(Duration(days: 1))) &&
            followupDate.isBefore(endDate.add(Duration(days: 1))) || followupDate.isAtSameMomentAs(endDate);

        // ✅ Apply status filter
        bool statusMatches = selectedStatus == null || selectedStatus == "All" || inquiry.status == selectedStatus;

        return withinDateRange && statusMatches;
      }).toList().reversed.toList();
    });

    print("Total Filtered Inquiries: ${filteredInquiries.length}"); // ✅ Debugging
  }

  void _openPotentialMatchesSheet(InquiryModel inquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // so rounded corners look clean
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.7, // 👈 half screen
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                // your sheet content
                Expanded(
                  child: _PotentialMatchesSheet(
                    inquiry: inquiry,
                    fetcher: _fetchAvailableUnits,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: _updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search Inquiries',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                // ✅ Show Validation Message if No Results Found
                if (validationMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      validationMessage,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
            );
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),

        backgroundColor: appbar_color.withOpacity(0.9),
        centerTitle: true,
        title: Text(
          'Inquiries',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            fontSize: 20.0,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Sidebar(
        isDashEnable: true,
        isRolesVisible: true,
        isRolesEnable: true,
        isUserEnable: true,
        isUserVisible: true,
      ),
        body: Container(
            color: Colors.white,
            child:
            Column(
              children: [
                // Status Filters (Loading Indicator)

                if(hasPermission('canViewInquiry'))...[
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Date Range Picker Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final DateTimeRange? picked = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                        initialDateRange: DateTimeRange(start: startDate, end: endDate),
                                        builder: (context, child) {
                                          return Theme(
                                            data: ThemeData.light().copyWith(
                                              primaryColor: appbar_color, // ✅ Header & buttons color
                                              scaffoldBackgroundColor: Colors.white,
                                              colorScheme: ColorScheme.light(
                                                primary: appbar_color, // ✅ Start & End date circle color
                                                onPrimary: Colors.white, // ✅ Text inside Start & End date
                                                secondary: appbar_color.withOpacity(0.6), // ✅ In-Between date highlight color
                                                onSecondary: Colors.white, // ✅ Text color inside In-Between dates
                                                surface: Colors.white, // ✅ Background color
                                                onSurface: Colors.black, // ✅ Default text color
                                              ),
                                              dialogBackgroundColor: Colors.white,
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );

                                      if (picked != null) {
                                        setState(() {
                                          startDate = picked.start;
                                          endDate = picked.end;
                                        });
                                        filterInquiries(); // ✅ Apply date filter
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: appbar_color, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.calendar_today, color: appbar_color, size: 18),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "${DateFormat('dd-MMM-yyyy').format(startDate)} - ${DateFormat('dd-MMM-yyyy').format(endDate)}",
                                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.calendar_today, color: appbar_color, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),


                                /*SizedBox(width: 10),

                      // 🔹 Filter Toggle Button
                      IconButton(
                        icon: Icon(Icons.filter_list, color: Colors.blue, size: 28),
                        onPressed: () {
                          setState(() {
                            showFilters = !showFilters; // ✅ Toggle filter visibility
                          });
                        },
                      ),*/
                              ],
                            ),

                            SizedBox(height: 5), // Space before filters

                            // 🔹 Show/Hide Filters
                            /*if (showFilters)*/
                            Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: isStatusLoading
                                    ? Center(
                                  child: Platform.isIOS
                                      ? CupertinoActivityIndicator(radius: 15.0)
                                      : CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
                                    strokeWidth: 4.0,
                                  ),
                                )
                                    : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: inquirystatus_list.map((InquiryStatus status) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: ChoiceChip(
                                            label: Text(
                                              status.name,
                                              style: GoogleFonts.poppins(
                                                color: selectedStatus == status.name ? Colors.white : Colors.black,
                                              ),
                                            ),
                                            selected: selectedStatus == status.name,
                                            onSelected: (bool selected) {
                                              setState(() {
                                                selectedStatus = selected ? status.name : null;
                                              });
                                              filterInquiries();
                                            },
                                            selectedColor: appbar_color.withOpacity(0.9),
                                            backgroundColor: Colors.grey[100],
                                            showCheckmark: false,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20.0),
                                              side: BorderSide(
                                                color: selectedStatus == status.name ? appbar_color : Colors.grey,
                                                width: 1.0,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )))])),

                  // Inquiry List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: isLoading
                          ? Center(
                        child: Platform.isIOS
                            ? CupertinoActivityIndicator(radius: 15.0)
                            : CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
                          strokeWidth: 4.0,
                        ),
                      )
                          : filteredInquiries.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // center inside column
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(
                              "No Inquiry Found",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ) : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!isFetchingMoreInquiries &&
                              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 50 &&
                              inquiryCurrentPage < totalInquiryPages) {
                            inquiryCurrentPage++;
                            fetchInquiries();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: filteredInquiries.length + (isFetchingMoreInquiries ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (isFetchingMoreInquiries && index == filteredInquiries.length) {
                              return Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Center(
                                  child: Platform.isAndroid
                                      ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  )
                                      : CupertinoActivityIndicator(radius: 15),
                                ),
                              );
                            }

                            final inquiry = filteredInquiries[index];
                            return _buildinquiryCard(inquiry, index);
                          },
                        ),
                      ),
                    ),
                  ),
                ]
                else ...[
                Expanded(
                child: Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                "Access Denied",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                "You don’t have permission to view inquiries.",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
                ),
                ],
                ),
                ),
                ),
                ]
                ]
            ),
        ),

        floatingActionButton: hasPermission('canCreateInquiry') ? Container(
        decoration: BoxDecoration(
          color: appbar_color.withOpacity(1.0),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CreateSalesInquiry()),
            );
          },
          label: Text(
            'New Inquiry',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 8,
        ),
      ) : null
    );
  }

  Widget _buildinquiryCard(InquiryModel inquiry, int index) {

    final String createdBy = inquiry.created_by.trim().toLowerCase();
    final String assignedTo = inquiry.assigned_to.trim().toLowerCase();
    final String currentUser = user_name.trim().toLowerCase();

    final bool shouldDisableActions =
    // ✅ Super admin: full access, no disabling
    !(is_admin && is_admin_from_api) &&
        // 🔒 Admin with restrictions: apply filter
        is_admin && !is_admin_from_api &&
        createdBy == currentUser &&
        assignedTo.isNotEmpty &&
        assignedTo != currentUser;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedinquirys[index] = !_expandedinquirys[index];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10.0,
              offset: Offset(0, 5),
            )]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildinquiryHeader(inquiry),
            Divider(color: Colors.grey[300]),
            _buildinquiryDetails(inquiry),
            Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Show Follow Up and Transfer only if lead is Normal AND action is allowed
                          if (inquiry.leadStatusCategory == 'Normal' && !shouldRestrictAction(inquiry)) ...[

                            if(hasPermission('canFollowUpInquiry') )...[
                              _buildDecentButton(
                                'Follow Up',
                                Icons.schedule,
                                Colors.blue,
                                    () {
                                  String name = inquiry.customerName;
                                  List<String> emiratesList = inquiry.emirate.split(',').map((e) => e.trim()).toList();
                                  List<String> areaList = inquiry.area.split(',').map((e) => e.trim()).toList();
                                  List<String> unittype = inquiry.unitType.split(',').map((e) => e.trim()).toList();
                                  String contactno = inquiry.contactNo;
                                  String whatsapp_no = inquiry.whatsapp_no;
                                  String email = inquiry.email;
                                  String id = inquiry.inquiryNo;

                                  final RegExp regExp = RegExp(r"^\+\d{1,3}");
                                  String processedNumber = contactno.replaceAll(regExp, "");

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FollowupSalesInquiry(
                                        id: id,
                                        name: name,
                                        unittype: unittype,
                                        existingAreaList: areaList,
                                        existingEmirateList: emiratesList,
                                        contactno: contactno,
                                        whatsapp_no: whatsapp_no,
                                        email: email,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 5),

                            ],

                            if(hasPermission('canInquiryTransfer'))...[
                              _buildDecentButton(
                                'Transfer',
                                Icons.swap_horiz,
                                Colors.orange,
                                    () => _showTransferDialog(context, inquiry),
                              ),
                              SizedBox(width: 5),
                            ]

                          ],

                          // View is always visible
                          if(hasPermission('canViewLeadFollowUps'))...[
                            _buildDecentButton(
                              'View',
                              Icons.visibility,
                              Colors.black87,
                                  () => _showPopup(context, inquiry.inquiryNo),
                            ),
                          ],


                        ],
                      )
                    )
                )
            ),

            SizedBox(height:12),

            // 🔎 Potential matches
            BlinkingChip(
              onTap: () => _openPotentialMatchesSheet(inquiry),
            ),

            if (_expandedinquirys[index])
              _buildExpandedinquiryView(inquiry),

            SizedBox(height: 30), // Top space before the toggle
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedinquirys[index] = !_expandedinquirys[index];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 0.0, horizontal: 20.0),
                  decoration: BoxDecoration(
                      color: Colors.transparent

                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expandedinquirys[index] ? "View Less" : "View More",
                        style: GoogleFonts.poppins(
                          color: Colors.black26,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        _expandedinquirys[index] ? Icons.expand_less : Icons.expand_more,
                        color: Colors.black26,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildinquiryHeader(InquiryModel inquiry) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text and icon to the top
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.userCircle, color: Colors.teal, size: 22.0),
              SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  inquiry.customerName.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        _getStatusBadge(inquiry.leadStatusCategory, inquiry.status),
      ],
    );
  }

  void _showInfoPopover(BuildContext context, String assignedToName) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true, // ✅ ensures full height if needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Colors.redAccent, size: 28),
                SizedBox(height: 12),
                Text(
                  "Restricted Actions",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "You created this lead but it's assigned to $assignedToName.\n\nOnly the assigned person can take actions like follow-up or transfer.",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.check_circle_outline),
                  label: Text("Got it"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildinquiryDetails(InquiryModel inquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _buildInfoRow("Inquiry No:", "", inquiry.inquiryNo,Colors.orange),
        _buildInfoRow("Interest Type:", "", inquiry.interest_type,Colors.red),
        _buildInfoRowChip("Unit(s):", "", Wrap(
          spacing: 6,
          runSpacing: 6,
          children: formatUnitsAsChips(inquiry.unitType),
        ),Colors.deepPurple),
        _buildInfoRowChip("Area(s):", "",  Wrap(
          spacing: 6,
          runSpacing: 6,
          children: formatAreasAsChips(inquiry.preferredAreas),
        ),Colors.green),
        _buildInfoRow("Last Followup:", "", DateFormat('dd-MMM-yyyy').format(DateTime.parse(inquiry.lastFollowupDate)),Colors.blue),

        // 👇 Case 1: Superadmin → show both
        if (is_admin && is_admin_from_api) ...[
          SizedBox(height: 10),
          _buildCreatedAssignedCard(inquiry.created_by, inquiry.assigned_to),
        ]

        // 👇 Case 2: Restricted admin → created = current, assigned ≠ current → show only assigned
        else if (is_admin && !is_admin_from_api &&
            inquiry.created_by.trim().toLowerCase() == user_name.trim().toLowerCase() &&
            inquiry.assigned_to.trim().isNotEmpty &&
            inquiry.assigned_to.trim().toLowerCase() != user_name.trim().toLowerCase()) ...[
          SizedBox(height: 10),
          _buildCreatedAssignedCard(null, inquiry.assigned_to, showInfoIcon: true),
        ]

        // 👇 Case 3: created ≠ current, assigned = current → show only created
        else if (is_admin && !is_admin_from_api &&
              inquiry.created_by.trim().toLowerCase() != user_name.trim().toLowerCase() &&
              inquiry.assigned_to.trim().toLowerCase() == user_name.trim().toLowerCase()) ...[
            SizedBox(height: 10),
            _buildCreatedAssignedCard(inquiry.created_by, ''), // assigned hidden
          ]
      ],
    );
  }

  Widget _buildCreatedAssignedCard(String? createdBy, String assignedTo, {bool showInfoIcon = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      margin: EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(1),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 5,
        children: [
          if (createdBy != null && createdBy.trim().isNotEmpty)
            _buildUserInfoBadge(
              icon: Icons.person_outline,
              label: "Created by",
              value: createdBy,
              bgColor: Colors.blue.shade50,
              textColor: Colors.blue.shade800,
              iconColor: Colors.blue,
            ),

          if (assignedTo != null && assignedTo.trim().isNotEmpty)
            if (assignedTo.trim().isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUserInfoBadge(
                    icon: Icons.assignment_ind_outlined,
                    label: "Assigned to",
                    value: assignedTo,
                    bgColor: Colors.green.shade50,
                    textColor: Colors.green.shade800,
                    iconColor: Colors.green,
                  ),
                  if (showInfoIcon)
                    GestureDetector(
                      onTap: () => _showInfoPopover(context, assignedTo),
                      child: Container(
                        margin: EdgeInsets.only(left: 6),
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade50,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                        child: Icon(Icons.info_outline_rounded, size: 16, color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildUserInfoBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                SizedBox(width: 6),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "$label: ",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        TextSpan(
                          text: value,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> formatAreasAsChips(List<Map<String, dynamic>> preferredAreas) {
    if (preferredAreas.isEmpty) {
      return [
        Chip(
          label: Text('No areas specified'),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(color: Colors.black54),
        ),
      ];
    }

    return preferredAreas.map((area) {
      final areaName = area['area']['name'] ?? 'Unknown Area';
      final emirateName = area['area']['state']['name'] ?? 'Unknown Emirate';
      final label = '$areaName, $emirateName';

      return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.deepOrangeAccent.withOpacity(0.1),

            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [


                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child:
                  Icon(Icons.area_chart, color:Colors.deepOrangeAccent, size: 14),
                ),
              Text(
                label ?? 'Unknown',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.deepOrangeAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),

            ],
          ),
        );
      
    }).toList();
  }

  List<Widget> formatUnitsAsChips(String unitTypeString) {
    if (unitTypeString.trim().isEmpty) {
      return [
        Chip(
          label: Text('No unit types specified'),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(color: Colors.black54),
        ),
      ];
    }

    // Split the string by comma, trim each unit
    final unitList = unitTypeString.split(',').map((e) => e.trim()).toList();

    return unitList.map((unit) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: EdgeInsets.only(right: 0),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work, color: Colors.teal, size: 14),
            SizedBox(width: 6),
            Text(
              unit,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.teal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInfoRow(String label,String heading, String value,Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8.0),
          Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      heading,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,

                      ),
                    ),
                    SizedBox(width: 2,),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                      ),
                    )
                  ],
                )))]));
  }

  Widget _buildInfoRowChip(String label, String heading, Widget valueWidget, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (heading.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        heading,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  valueWidget
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowExpandedView(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8.0),
          Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                  ),

                ),
              )
          ),
        ],
      ),
    );
  }

  /*  Color parseColor(String hexColor) {
    if (hexColor.length == 4) {
      final r = hexColor[1] * 2;
      final g = hexColor[2] * 2;
      final b = hexColor[3] * 2;
      hexColor = "#$r$g$b";
    }
    return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
  }*/

  Widget _getStatusBadge(String category, String status) {
    Color color;
    switch (category) {
      case 'Normal':
        color = Colors.green;
        break;
      case 'Drop':
        color = Colors.red;
        break;
      case 'Close':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExpandedinquiryView(InquiryModel inquiry) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRowExpandedView('Description:', inquiry.description),
          if(inquiry.lastFollowupRemarks != 'null')
            _buildInfoRowExpandedView('Follow-Up Remarks:', inquiry.lastFollowupRemarks),


        ],
      ),
    );
  }

  Widget _buildDecentButton(String label, IconData icon, Color color,
      VoidCallback onPressed) {
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
            /*SizedBox(width: 8.0),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}

class _PotentialMatchesSheet extends StatefulWidget {
  final InquiryModel inquiry;
  final Future<List<Flat>> Function({
  required String status,
  required List<String> unitTypes,
  required double minPrice,
  required double maxPrice,
  }) fetcher;

  const _PotentialMatchesSheet({
    Key? key,
    required this.inquiry,
    required this.fetcher,
  }) : super(key: key);

  @override
  State<_PotentialMatchesSheet> createState() => _PotentialMatchesSheetState();
}

class _PotentialMatchesSheetState extends State<_PotentialMatchesSheet> {
  late Future<List<Flat>> _future;
  late final String _status;             // "Rent" | "Buy" (from inquiry)
  late final List<String> _unitTypes;    // from inquiry.unitType string
  late final double _min;
  late final double _max;

  // Search state
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();

    _status = (widget.inquiry.interest_type.isNotEmpty)
        ? widget.inquiry.interest_type
        : 'Rent';

    _unitTypes = widget.inquiry.unitType.trim().isEmpty
        ? <String>[]
        : widget.inquiry.unitType
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Safety: if API stores zeros, widen a bit
    final minP = widget.inquiry.minPrice <= 0 ? 0.0 : widget.inquiry.minPrice;
    final maxP = (widget.inquiry.maxPrice <= 0 || widget.inquiry.maxPrice < minP)
        ? (minP + 9999999) // big cap
        : widget.inquiry.maxPrice;

    _min = minP;
    _max = maxP;

    _future = widget.fetcher(
      status: _status,
      unitTypes: _unitTypes.isEmpty ? <String>[] : _unitTypes,
      minPrice: _min,
      maxPrice: _max,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  // Search ONLY by: unit type, building, area
  List<Flat> _filterResults(List<Flat> all) {
    if (_query.isEmpty) return all;

    // multi-word queries -> AND match across tokens
    final tokens = _query
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    bool matches(Flat u) {
      final unitType = (u.flatTypeName ?? '').toLowerCase();
      final building = (u.buildingName ?? '').toLowerCase();
      final area     = (u.areaName ?? '').toLowerCase();

      final haystack = '$unitType $building $area';
      return tokens.every((t) => haystack.contains(t));
    }

    return all.where(matches).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [


            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_work_outlined, color: appbar_color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Potential Matches",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: appbar_color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appbar_color.withOpacity(0.2)),
                  ),
                  child: Text(
                    "${_unitTypes.join(', ')}  |  $_status  |  $_min – $_max",
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: appbar_color.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),


            // Search field
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by unit type, building, or area...',
                  fillColor: Colors.white,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: (_query.isNotEmpty)
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onQueryChanged('');
                    },
                  )
                      : null,
                ),
                style: GoogleFonts.poppins(fontSize: 14.0),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: FutureBuilder<List<Flat>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      //////////
                      child: SizedBox(
                        height: 28, width: 28,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
                        ),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        "Failed to load matches",
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    );
                  }
                  final data = snap.data ?? [];
                  final filtered = _filterResults(data);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            _query.isEmpty
                                ? "No matching units found"
                                : "No results for \"$_query\"",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final u = filtered[i];
                      final price = _status.toLowerCase() == 'buy' ? u.basicSaleValue : u.basicRent;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          title: Text(
                            "${u.flatTypeName} • ${u.buildingName}",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${u.areaName}, ${u.stateName}",
                                  style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset('assets/dirham.png', width: 14, height: 14, fit: BoxFit.contain),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${price ?? 'N/A'}",
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (u.noOfBathrooms > 0)
                                      _smallBadge(Icons.bathtub, "${u.noOfBathrooms}"),
                                    if (u.noOfParking > 0)
                                      _smallBadge(Icons.local_parking, "${u.noOfParking}"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (_status.toLowerCase() == 'buy'
                                  ? Colors.blue
                                  : Colors.green)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _status.toLowerCase() == 'buy'
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                            ),
                            child: Text(
                              u.status ?? _status,
                              style: GoogleFonts.poppins(
                                color: _status.toLowerCase() == 'buy'
                                    ? Colors.blue
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AvailableUnitsDialog(
                                unitno: u.name,
                                area: u.areaName,
                                building_name: u.buildingName,
                                emirate: u.stateName,
                                unittype: u.flatTypeName,
                                parking: u.noOfParking.toString(),
                                balcony: (u.amenities ?? const <String>[])
                                    .contains("Balcony")
                                    ? "Yes"
                                    : "No",
                                bathrooms: u.noOfBathrooms.toString(),
                                status: _status,
                                ownership: u.ownership ?? "N/A",
                                basicRent: u.basicRent?.toString() ?? "N/A",
                                basicSaleValue: u.basicSaleValue?.toString() ?? "N/A",
                                isExempt: u.isExempt ? "true" : "false",
                                amenities: u.amenities,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBadge(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.poppins(fontSize: 12.5)),
        ],
      ),
    );
  }
}

class BlinkingChip extends StatefulWidget {
  final VoidCallback onTap;
  const BlinkingChip({Key? key, required this.onTap}) : super(key: key);

  @override
  _BlinkingChipState createState() => _BlinkingChipState();
}

class _BlinkingChipState extends State<BlinkingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: ActionChip(
          avatar: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
          label: Text(
            "Potential Matches",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.teal,
          onPressed: widget.onTap,
        ),
      ),
    );
  }
}


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
  final int noOfBathrooms;
  final int noOfParking;
  final String? status;

  // New fields
  final String? ownership;
  final int? basicRent;
  final int? basicSaleValue;
  final bool isExempt;
  final int? companyId;
  final int? buildingId;
  final int? floorId;
  final int? flatTypeId;

  final List<String> amenities;

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
    required this.noOfBathrooms,
    required this.noOfParking,
    this.ownership,
    this.status,

    this.basicRent,
    this.basicSaleValue,
    required this.isExempt,
    this.companyId,
    this.buildingId,
    this.floorId,
    this.flatTypeId,
    required this.amenities,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json["id"],
      name: json["name"],
      grossArea: json["gross_area_in_sqft"]?.toString(),
      buildingName: json["building"]["name"],
      floorName: json["floors"]["name"],
      flatTypeName: json["flat_type"]["name"],
      areaName: json["building"]["area"]["name"],
      stateName: json["building"]["area"]["state"]["name"],
      countryName: json["building"]["area"]["state"]["country"]["name"],
      createdAt: json["created_at"],
      status :json['status'] ?? "",


      ownership: json["ownership"],
      basicRent: json["basic_rent"],
      basicSaleValue: json["basic_sale_value"],
      isExempt: json["is_exempt"]?.toString() == "true",
      noOfBathrooms: json["no_of_bathrooms"] ?? 0,
      noOfParking: json["no_of_parkings"] ?? 0,
      companyId: json["company_id"],
      buildingId: json["building_id"],
      floorId: json["floor_id"],
      flatTypeId: json["flat_type_id"],

      amenities: (json["amenities"] as List<dynamic>?)
          ?.map((e) => e["amenity"]["name"].toString())
          .toList() ??
          [],
    );
  }
}

String _brandHex(Color c) {
  // Converts a Color to #RRGGBB (ignore alpha)
  return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

String _buildInquiryTransferEmailHtmlMinimal({
  required String assigneeName,   // new user
  required String assignedBy,     // current user
  required String customerName,
  required String interestType,
  required String propertyType,
  required String priceRange,
}) {
  final brand = _brandHex(appbar_color);
  const subtle = '#f6f9fc';
  const muted  = '#6b7280';

  return '''
  <!doctype html>
  <html>
  <head>
    <meta name="viewport" content="width=device-width"/>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <title>New Inquiry Assigned</title>
  </head>
  <body style="margin:0;padding:0;background:${subtle};font-family:Inter,Segoe UI,Roboto,Arial,sans-serif;color:#111827;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${subtle};padding:24px 0;">
      <tr><td align="center">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:12px;box-shadow:0 4px 16px rgba(0,0,0,0.08);overflow:hidden;">
          <tr>
            <td style="background:${brand};padding:20px;text-align:center;color:#fff;">
              <h2 style="margin:0;font-size:18px;">New Inquiry Assigned</h2>
            </td>
          </tr>
          <tr><td style="padding:24px;">
            <p style="margin:0 0 12px;font-size:15px;">
              Hi <strong>$assigneeName</strong>, an inquiry was transferred to you by <strong>$assignedBy</strong>.
            </p>
            <div style="border:1px solid #eee;border-radius:10px;padding:16px;background:#fafafa;">
              <p style="margin:0 0 6px;font-size:14px;"><strong>Customer:</strong> $customerName</p>
              <p style="margin:0 0 6px;font-size:14px;"><strong>Interest:</strong> $interestType</p>
              <p style="margin:0 0 6px;font-size:14px;"><strong>Property Type:</strong> $propertyType</p>
              <p style="margin:0;font-size:14px;"><strong>Budget:</strong> $priceRange</p>
            </div>
            <p style="margin:16px 0 0;font-size:12px;color:$muted;">Please follow up accordingly.</p>
          </td></tr>
          <tr>
            <td style="background:#fafafa;padding:12px;text-align:center;font-size:12px;color:$muted;">
              © ${DateTime.now().year} CSH Real Estate
            </td>
          </tr>
        </table>
      </td></tr>
    </table>
  </body>
  </html>
  ''';
}

String _formatCurrencyRange(num start, num end) {
  // e.g., AED 50,000 – 120,000
  final f = NumberFormat.decimalPattern(); // 50,000 style
  return 'AED ${f.format(start)} – AED ${f.format(end)}';
}




