import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/TenantComplaint.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'RequestCreation.dart';
import 'TenantDashboard.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({Key? key}) : super(key: key);

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  bool isLoading = true;
  List<dynamic> complaints = [];
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
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('$baseurl/tenant/complaint/?user_id = $user_id'),
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        final jsonData = json.decode(response.body);

        print('request : $jsonData');

        // Filter only requests with flat_id == 1
        final allRequests = jsonData['data']['complaints'] as List;

        setState(() {
          complaints= allRequests.reversed.toList();
          _filterComplaintsByDate(); // ✅ apply filter using default dates

          print("total length ${complaints.length}");



        });

      }
    } catch (e) {
      print("Error fetching complaints: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }


  void _filterComplaintsByDate() {
    if (_startDate == null || _endDate == null) {
      filteredComplaints = complaints;
      return;
    }

    filteredComplaints = complaints.where((comp) {
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
        title: Text("Complaints/Suggestions", style: GoogleFonts.poppins(fontWeight: FontWeight.normal,
            color:Colors.white)),
        backgroundColor: appbarColor.withOpacity(0.9),
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => TenantDashboard()),
            );
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
                MaterialPageRoute(builder: (_) => TenantComplaint()),
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
        child: isLoading
            ? Center(
          child: Platform.isIOS
              ? const CupertinoActivityIndicator(radius: 18)
              : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(appbarColor),
          ),
        )

            : Column(
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
                        fetchComplaints(); // ✅ Apply date filter
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

            filteredComplaints.isEmpty
                ? Expanded(
                child:  Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // center inside column

                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        "No complaints/suggestions found",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
            ):

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom:12,left:12,right:12),
                itemCount: filteredComplaints.length,
                itemBuilder: (context, index) {
                  final comp = filteredComplaints[index];
                  final comp_id = comp["id"];
                  final type = comp["type"];
                  final description = comp['description'];
                  final created_at = comp['created_at'];

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
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Top: Type + Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  type == 'Complaint' ? "C - $comp_id" : "S - $comp_id",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,

                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              _getRequestStatusBadge(type),
                            ],
                          ),

                          SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade300),
                          SizedBox(height: 12),


                          Row(
                            children: [
                              Icon(Icons.calendar_month, size: 16, color: Colors.blueAccent),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  formatDate(created_at),
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 6),

                          // 📝 Description
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes, size: 16, color: Colors.black),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  description,
                                  style: GoogleFonts.poppins(fontSize: 13.2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );


                },
              ),
            )
            ,
          ],
        ),

      ),

    );
  }
}
Widget _getRequestStatusBadge(dynamic type) {
  String status;
  Color color;

  if (type == null) {
    status = "N/A";
    color = Colors.orange;
  } else if (type == "Suggestion") {
    status = type;
    color = Colors.orange;
  } else {
    status = type;
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

