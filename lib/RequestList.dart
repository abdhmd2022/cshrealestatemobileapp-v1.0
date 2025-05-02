import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'RequestCreation.dart';
import 'TenantDashboard.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({Key? key}) : super(key: key);

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  bool isLoading = true;
  List<dynamic> requests = [];
  DateTime? _startDate;
  DateTime? _endDate;
  List<dynamic> filteredComplaints = [];

  final Color appbarColor = appbar_color;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    List<dynamic> allRequests = [];
    int page = 1;
    bool hasMore = true;

    setState(() => isLoading = true);

    try {
      while (hasMore) {
        final response = await http.get(
          Uri.parse('$baseurl/tenant/request?page=$page'),
          headers: {
            'Authorization': 'Bearer $Company_Token',
            'Content-Type': 'application/json',
          },
        );

        final data = json.decode(response.body);

        if (data['success'] == true) {
          final requestsPage = data['data']['requests'] as List;
          final meta = data['meta'];

          // Append filtered requests only (where flat_id matches)
          final filteredPage = requestsPage.where((req) => req['flat_id'] == flat_id).toList();
          allRequests.addAll(filteredPage);

          int currentPage = meta['page'];
          int pageSize = meta['size'];
          int totalCount = meta['totalCount'];
          int totalPages = (totalCount / pageSize).ceil();

          hasMore = currentPage < totalPages;
          page++;
        } else {
          hasMore = false;
        }
      }

      setState(() {
        requests = allRequests.reversed.toList();
        _filterComplaintsByDate(); // ✅ if you're using this for filtering
      });
    } catch (e) {
      print("Error fetching requests: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
  void _filterComplaintsByDate() {
    if (_startDate == null || _endDate == null) {
      filteredComplaints = requests;
      return;
    }

    filteredComplaints = requests.where((comp) {
      final createdAt = DateTime.tryParse(comp['created_at'] ?? '');
      if (createdAt == null) return false;
      return createdAt.isAfter(_startDate!.subtract(Duration(days: 0))) &&
          createdAt.isBefore(_endDate!.add(Duration(days: 1)));
    }).toList();

    print("filtered length ${filteredComplaints.length}");

    setState(() {});
  }


  Widget buildStatusChip(dynamic isApproved) {
    String statusText;
    Color chipColor;
    IconData iconData;

    if (isApproved == null) {
      statusText = 'Pending';
      chipColor = Colors.orange.shade100;
      iconData = Icons.access_time;
    } else if (isApproved == true) {
      statusText = 'Approved';
      chipColor = Colors.green.shade100;
      iconData = Icons.check_circle_outline;
    } else {
      statusText = 'Rejected';
      chipColor = Colors.red.shade100;
      iconData = Icons.cancel_outlined;
    }

    return Chip(
      avatar: Icon(iconData, size: 16, color: Colors.black54),
      label: Text(statusText, style: GoogleFonts.poppins(fontSize: 12)),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Requests", style: GoogleFonts.poppins(fontWeight: FontWeight.normal,
        color:Colors.white)),
        backgroundColor: appbarColor.withOpacity(0.9),
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton:Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0, bottom: 20.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [appbarColor.withOpacity(0.85), appbarColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => SpecialRequestScreen()),
              ),
              backgroundColor: Colors.transparent,
              elevation: 30,
              child: Icon(Icons.add_rounded, size: 28, color: Colors.white),
            ),
          ),
        ),
      ),

      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0,right:12),
              margin: const EdgeInsets.only(bottom:12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
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
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                        fetchRequests(); // ✅ Apply date filter
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
                                  "${DateFormat('dd-MMM-yyyy').format(_startDate!)} - ${DateFormat('dd-MMM-yyyy').format(_endDate!)}",
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
                ],
              ),
            ),
            isLoading
                ? Expanded(
              child: Center(
                child: Platform.isIOS
                    ? const CupertinoActivityIndicator(radius: 18)
                    : CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(appbarColor),
                ),
              )
            )
                : filteredComplaints.isEmpty
                ? Expanded(
                child:  Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // center inside column

                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        "No request found",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
            )
                : Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom:12,left:12,right:12),
                itemCount: filteredComplaints.length,
                itemBuilder: (context, index) {
                  final req = filteredComplaints[index];
                  final req_id = req["id"];
                  final flat = req['contract_flat']['flat'];
                  final building = flat['building'];
                  final area = building['area'];
                  final state = area['state'];
                  final approved_by = req['approved_by'];

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 8),
                    color:Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.only(bottom:18.0,left:18,right:18,top:18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Top: Type + Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  '${req['type']['name'].toString()}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              _getRequestStatusBadge(req['status']?['name'] ?? 'Pending', req['status']?['category'] ?? null),
                            ],
                          ),

                          SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade300),
                          SizedBox(height: 12),

                          // 📍 Location
                          Row(
                            children: [
                              Icon(Icons.apartment, size: 16, color: Colors.blue),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${flat['name']} • ${building['name']}, ${state['name']}",
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
                                  "${area['name']}, ${state['name']}",
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                            ],
                          ),

                          // 📝 Approved user
                          /*if(approved_by!=null)...[

                      SizedBox(height: 6),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.checklist_rounded, size: 16, color: Colors.green),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              req['approved_user']['name'],
                              style: GoogleFonts.poppins(fontSize: 13.2),
                            ),
                          ),
                        ],
                      ),
                    ],*/

                          // creation date
                          SizedBox(height: 6),

                          // 📝 Description
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.calendar_month, size: 16, color: Colors.black),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  formatDate(req['created_at']),
                                  style: GoogleFonts.poppins(fontSize: 13.2),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 6),

                          // 📝 Description
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes, size: 16, color: Colors.grey),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  req['description'],
                                  style: GoogleFonts.poppins(fontSize: 13.2),
                                ),
                              )
                            ])])));}))])));}}

  Widget _getRequestStatusBadge(dynamic name,dynamic category) {
    String status;
    Color color;

    if (category == "Hold" || category == null) {
      status = name;
      color = Colors.orange;
    } else if (category == "Approved") {
      status = name;
      color = Colors.green;
    } else {
      status = name;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

