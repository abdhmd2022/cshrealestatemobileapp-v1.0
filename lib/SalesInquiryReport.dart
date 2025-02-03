import 'dart:convert';
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
  _SalesInquiryReportState createState() =>
      _SalesInquiryReportState();
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
  final String color;
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
    required this.color,
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
        ?.map((area) => area['areas']['area_name'])
        .join(', ') ??
        'No areas specified';

    // Fetch and concatenate emirates
    final emirates = (json['preferred_areas'] as List<dynamic>?)
        ?.map((area) => area['areas']['emirates']['state_name'].toString())
        .toSet() // Use a Set to ensure uniqueness
        .join(', ') ??
        'No emirates specified';

    final flatTypes = (json['preferred_flat_types'] as List<dynamic>?)
        ?.map((flatType) => flatType['flat_types']['flat_type'])
        .join(', ') ??
        'No unit type specified';

    final List<dynamic>? leadsFollowup = json['leads_followup'];

    String leadStatusName= '';// Extract the last follow-up and its lead status name
    String leadStatusCategory= '';
    String leadStatusColor= '';


    final created_by = (json['created_user'] as Map<String, dynamic>?)?['name'] ?? 'N/A';

    final assigned_to = (json['assigned_to_user'] as Map<String, dynamic>?)?['name'] ?? 'N/A';


    if (leadsFollowup != null && leadsFollowup.isNotEmpty) {

      final lastFollowup = leadsFollowup.first;
      leadStatusName = lastFollowup['lead_status']?['name'] ?? 'Unknown';
      leadStatusCategory = lastFollowup['lead_status']?['category'] ?? 'Unknown';
      leadStatusColor = lastFollowup['lead_status']?['color'] ?? 'Unknown';

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
      color: leadStatusColor,

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
  static T _getNestedValue<T>(
      Map<String, dynamic> json, List<dynamic> keys, T defaultValue) {
    dynamic value = json;
    for (var key in keys) {
      if (value is Map<String, dynamic> && value.containsKey(key)) {
        value = value[key];
      } else if (value is List && key is int && key < value.length) {
        value = value[key];
      } else {
        return defaultValue;
      }
    }
    return value as T? ?? defaultValue;
  }
  static String _formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('dd-MMM-yyyy').format(parsedDate);
    } catch (e) {
      return rawDate; // Return the raw date if parsing fails
    }
  }
}

class _SalesInquiryReportState
    extends State<SalesInquiryReport> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<InquiryModel> salesinquiry = [
  ];

  List<InquiryModel> filteredInquiries = [];
  String searchQuery = "";


  List<bool> _expandedinquirys = [];

  @override
  void initState() {
    super.initState();
    fetchInquiries();
  }

  List<InquiryModel> parseInquiries(Map<String, dynamic> jsonResponse) {
    final leads = jsonResponse['data']?['leads'] as List<dynamic>? ?? [];
    return leads.map((lead) => InquiryModel.fromJson(lead)).toList();
  }

  Future<void> fetchInquiries() async {
    print('fetching inquiries');

    filteredInquiries.clear();
    salesinquiry.clear();
    _expandedinquirys.clear();

    final url = '$BASE_URL_config/v1/leads'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {
        setState(() {
          print(response.body);
          final jsonResponse = json.decode(response.body);
          salesinquiry = parseInquiries(jsonResponse);
          _expandedinquirys =
              List.generate(salesinquiry.length, (index) => false);

          filteredInquiries = salesinquiry;
        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredInquiries = salesinquiry
          .where((inquiry) =>
      inquiry.customerName.toLowerCase().contains(query.toLowerCase()) ||
          inquiry.unitType.toLowerCase().contains(query.toLowerCase()) ||
          inquiry.area.toLowerCase().contains(query.toLowerCase()) ||
          inquiry.emirate.toLowerCase().contains(query.toLowerCase()) ||
          inquiry.status.toLowerCase().contains(query.toLowerCase()) ||
          inquiry.inquiryNo.toString().toLowerCase().contains(
              query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: filteredInquiries.isEmpty
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

      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: appbar_color.withOpacity(0.9),

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
            ),
          ],
        ),
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
            Icon(Icons.label_important, color: Colors.teal, size: 24.0),
            SizedBox(width: 8.0),
            Text(
              inquiry.inquiryNo.toString(),
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
        _buildInfoRow('Name:', inquiry.customerName),
        _buildInfoRow('Unit Type:', inquiry.unitType),
        _buildInfoRow('Email:', inquiry.email),
        _buildInfoRow('Area:', '${inquiry.area}, ${inquiry.emirate}'),
        _buildInfoRow('Date:', inquiry.creationDate),
        // _buildInfoRow('Created By (using for testing):', inquiry.created_by.toString()),
        //_buildInfoRow('Assigned To (using for testing):', inquiry.assigned_to.toString()),


      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
          _buildInfoRow('Description:', inquiry.description),

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
            SizedBox(width: 8.0),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
