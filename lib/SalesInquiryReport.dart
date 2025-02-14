import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cshrealestatemobile/CreateSalesInquiry.dart';
import 'package:cshrealestatemobile/FollowupSalesInquiry.dart';
import 'package:cshrealestatemobile/SalesInquiryTransfer.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'SalesDashboard.dart';
import 'Sidebar.dart';

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
    required this.minPrice,
    required this.maxPrice,
    required this.status,
    required this.preferredAreas,
    required this.preferredFlatTypes,
    required this.preferredAmenities,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'] ?? '';
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

    final assigned_to = (json['assigned_to_user'] as Map<String, dynamic>?)?['name'] ?? 'N/A';


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
      emirate: emirates,
      description: json['description'] ?? 'No description',
      contactNo: json['mobile_no'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      created_by: created_by ?? 'N/A',
      assigned_to: assigned_to ?? 'N/A',
      lastFollowupRemarks: lastFollowupRemarks,
      lastFollowupDate: lastFollowupDate ,
      // color: leadStatusColor,

      inquiryNo: json['id'].toString() ?? '',
      creationDate: formattedDate,
      leadStatusCategory: leadStatusCategory,

      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
      status: leadStatusName ?? 'In Progress',
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

  List<InquiryModel> salesinquiry = [
  ];

  List<InquiryModel> filteredInquiries = [];
  String searchQuery = "";

  List<bool> _expandedinquirys = [];

  List<InquiryStatus> inquirystatus_list = [];
  String? selectedStatus;
  bool isStatusLoading = true; // Track lead status loading

  List<dynamic> leadFollowupHistoryList = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLeadStatus();
  }

  Future<void> fetchLeadStatus() async {
    setState(() {
      isStatusLoading = true; // Start loading
    });

    inquirystatus_list.clear();

    final url = '$BASE_URL_config/v1/leadStatus';
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
                (status) => status.category == "Normal",
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                                item["lead"]["name"],
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  getCategoryIcon(item["status"]["category"]),
                                  SizedBox(width: 6),
                                  Text(
                                    item["status"]["name"],
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Date: ${formatDate(item["date"])}",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              if (item["remarks"] != null) ...[
                                SizedBox(height: 6),
                                Text(
                                  "Remarks: ${item["remarks"]}",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),

                              ],
                              if (nextFollowUpDate != null) ...[
                                SizedBox(height: 6),
                                Row(
                                  children: [

                                    Text(
                                      "Next Follow-up: ",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    Text(
                                      "${formatDate(nextFollowUpDate)}",
                                      style: TextStyle(
                                        color: followUpDateColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ],
                          ),
                        ),
                      )
                    );

                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<dynamic>> fetchLeadHistory(String id) async {

    leadFollowupHistoryList.clear();

    final url = '$BASE_URL_config/v1/leadFollowUp/?lead_id=$id';

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

    print('Fetching inquiries...');

    filteredInquiries.clear();
    salesinquiry.clear();
    _expandedinquirys.clear();

    final url = '$BASE_URL_config/v1/leads';
    String token = 'Bearer $Company_Token'; // Auth token


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        setState(() {
          print(response.body);
          final jsonResponse = json.decode(response.body);
          salesinquiry = parseInquiries(jsonResponse);
          _expandedinquirys = List.generate(salesinquiry.length, (index) => false);

          filterInquiries(); // ✅ Apply default filtering after fetching
        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }

    setState(() {
      isLoading = false;
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
      }).toList();
    });

    print("Total Filtered Inquiries: ${filteredInquiries.length}"); // ✅ Debugging
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
                      style: TextStyle(color: Colors.white, fontSize: 14),
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
              MaterialPageRoute(builder: (context) => SalesDashboard()),
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
          style: TextStyle(
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
        body:

        Container(
            color: Colors.white,
            child:
            Column(
              children: [
                // Status Filters (Loading Indicator)


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
                                            style: TextStyle(fontSize: 14, color: Colors.black87),
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
                                    style: TextStyle(
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),



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
                      child: Text(
                        "No data available",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredInquiries.length,
                      itemBuilder: (context, index) {
                        final inquiry = filteredInquiries[index];
                        return _buildinquiryCard(inquiry, index);
                      },
                    ),
                  ),
                ),
              ],
            ),
        ),

        floatingActionButton: Container(
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
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildinquiryCard(InquiryModel inquiry, int index) {
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [


                          if(inquiry.leadStatusCategory == 'Normal' )
                            Row(children: [

                              _buildDecentButton(
                                'Follow Up',
                                Icons.schedule,
                                Colors.blue,
                                    () {
                                  String name = inquiry.customerName;
                                  List<String> emiratesList = inquiry.emirate
                                      .split(',').map((e) => e.trim()).toList();
                                  List<String> areaList = inquiry.area.split(
                                      ',').map((e) => e.trim()).toList();
                                  List<String> unittype = inquiry.unitType
                                      .split(',').map((e) => e.trim()).toList();
                                  String contactno = inquiry.contactNo;
                                  String email = inquiry.email;
                                  String id = inquiry.inquiryNo;

                                  final RegExp regExp = RegExp(r"^\+\d{1,3}");

                                  // Remove the country code
                                  String processedNumber = contactno.replaceAll(
                                      regExp, "");

                                  // Print the result
                                  print(
                                      'number $processedNumber'); // Output: 9876543210

                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) =>
                                          FollowupSalesInquiry(id: id,
                                              name: name,
                                              unittype: unittype,
                                              existingAreaList: areaList,
                                              existingEmirateList: emiratesList,
                                              contactno: contactno,
                                              email: email)));
                                },
                              ),
                              SizedBox(width: 5),
                              _buildDecentButton(
                                'Transfer',
                                Icons.swap_horiz,
                                Colors.orange,
                                    () {
                                  String name = inquiry.customerName;
                                  String id = inquiry.inquiryNo;
                                  String email = inquiry.email;

                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) =>
                                          SalesInquiryTransfer(name: name,
                                            email: email,
                                            id: id,)));
                                },
                              ),
                              SizedBox(width: 5)
                            ],),

                          _buildDecentButton(
                            'View',
                            Icons.visibility,
                            Colors.black87,
                                () {
                                  _showPopup(context,inquiry.inquiryNo);
                            },
                          ),

                          /*_buildDecentButton(
                          'Delete',
                          Icons.delete,
                          Colors.red,
                              () {
                            // Delete action
                            // Add your delete functionality here
                          },
                        ),*/
                        ],
                      ),
                    )
                )
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
                        style: TextStyle(
                          color: Colors.black26,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        _expandedinquirys[index] ? Icons.expand_less : Icons
                            .expand_more,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(FontAwesomeIcons.userCircle, color: Colors.teal, size: 22.0),
            SizedBox(width: 8.0),
            Text(
              inquiry.customerName.toString(),
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        _getStatusBadge(inquiry.leadStatusCategory, inquiry.status),
      ],
    );
  }

  Widget _buildinquiryDetails(InquiryModel inquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.numbers, inquiry.inquiryNo),
        _buildInfoRow(FontAwesomeIcons.building, inquiry.unitType),
        // _buildInfoRow('Email:', inquiry.email),
         _buildInfoRow(FontAwesomeIcons.map, _formatAreasWithEmirates(inquiry.preferredAreas)),
        _buildInfoRow(FontAwesomeIcons.clock, DateFormat('dd-MMM-yyyy').format(DateTime.parse(inquiry.lastFollowupDate))),
        // _buildInfoRow('Created By (using for testing):', inquiry.created_by.toString()),

        //_buildInfoRow('Assigned To (using for testing):', inquiry.assigned_to.toString()),


      ],
    );
  }

  String _formatAreasWithEmirates(List<Map<String, dynamic>> preferredAreas) {
    if (preferredAreas.isEmpty) {
      return 'No areas specified';
    }

    return preferredAreas.map((area) {
      final areaName = area['area']['name'] ?? 'Unknown Area';
      final emirateName = area['area']['state']['name'] ?? 'Unknown Emirate';
      return '$areaName, $emirateName';
    }).join(' • '); // Using a bullet separator for clarity
  }

  Widget _buildInfoRow(IconData label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          FaIcon(label, color: appbar_color, size: 20.0),

          SizedBox(width: 8.0),
          Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.black87,
                  ),

                ),
              )
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
            style: TextStyle(
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
                  style: TextStyle(
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
        style: TextStyle(
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
              style: TextStyle(
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
