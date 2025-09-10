import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/TenantComplaint.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
    List<dynamic> allComplaints = [];
    int page = 1;
    bool hasMore = true;


    setState(() => isLoading = true);

    try {
      while (hasMore) {
        final url = is_landlord
            ? "$baseurl/tenant/complaint/?landlord_id=$user_id&page=$page"
            : "$baseurl/tenant/complaint/?tenant_id=$user_id&page=$page";

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $Company_Token',
            'Content-Type': 'application/json',
          },
        );


        final data = json.decode(response.body);

        if (data['success'] == true) {
          final complaintsPage = data['data']['complaints'] as List;
          final meta = data['meta'];

          allComplaints.addAll(complaintsPage);

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
        complaints = allComplaints.reversed.toList();
        _filterComplaintsByDate();
        print("Total complaints fetched: ${complaints.length}");
      });
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

    print('complaint ->${filteredComplaints}');

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Complaints/Suggestions", style: GoogleFonts.poppins(fontWeight: FontWeight.normal,
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
      floatingActionButton: hasPermission('canCreateComplaintSuggestion') ? Align(
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
      ):null,

      body: Container(
        color: Colors.white,
        child: isLoading
            ? Center(
          child: Platform.isIOS
              ? const CupertinoActivityIndicator(radius: 18)
              : CircularProgressIndicator.adaptive(
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

                  return _buildEntryCard(
                    context: context,
                    entry: comp,
                    appColor: comp["type"] == "Complaint" ? Colors.red : Colors.teal,

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
    color = Colors.teal;
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
Widget _buildEntryCard({
  required BuildContext context,
  required Map<String, dynamic> entry,
  required Color appColor,
}) {
  final type = (entry['type'] ?? 'Unknown').toString();
  final tenantName = entry['tenant']?['name']?.toString() ?? entry['landlord_id'].toString() ?? 'Unknown';
  final desc = (entry['description'] ?? 'No description').toString();
  final createdAt = DateTime.tryParse(entry['created_at'] ?? '') ?? DateTime.now();
  final dateLabel = DateFormat('dd-MMM-yyyy • hh:mm a').format(createdAt);

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
      border: Border.all(color: Colors.grey.shade200),
    ),
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Row: Avatar • Name/Date • Status ────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: appColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: appColor,
                child: Text(
                  getInitials(tenantName).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenantName,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            _statusChip(entry['status']), // 👈 status at top-right
          ],
        ),

        const SizedBox(height: 10),

        // ── Description ────────────────────────────────
        Text(
          desc,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.35,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 10),

        // ── Footer Row: Type (Complaint/Suggestion) + Chevron ──────
        Row(
          children: [
            _typeChip(type),
            /*const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),*/
          ],
        ),
      ],
    ),
  );
}
String getInitials(String name) {
  final parts = name.trim().split(" ");
  return parts.length > 1
      ? "${parts[0][0]}${parts[1][0]}"
      : name.isNotEmpty ? name[0] : "?";
}

Widget _statusChip(dynamic status) {
  // status may be null → show Pending
  final bool has = status != null;
  final String label = has ? (status['name']?.toString() ?? 'Unknown') : 'Pending';
  final _StatusStyle s = _statusStyle(has ? status['category']?.toString() : null);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: s.color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: s.color.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(s.icon, size: 14, color: s.color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: s.color),
        ),
      ],
    ),
  );
}

class _StatusStyle {
  final Color color;
  final IconData icon;
  const _StatusStyle(this.color, this.icon);
}

_StatusStyle _statusStyle(String? category) {
  final cat = (category ?? '').toLowerCase();

  if (cat  == 'normal') return _StatusStyle(Colors.orange, Icons.sync);
  if (cat  == 'close') return _StatusStyle(Colors.green, Icons.check_circle);

  // fallback/unknown
  return _StatusStyle(Colors.orange, Icons.info_outline);
}

Widget _typeChip(String type) {
  final bool isSuggestion = type == 'Suggestion';
  final color = isSuggestion ? Colors.teal : Colors.redAccent;
  final icon  = isSuggestion ? Icons.lightbulb_outline : Icons.report_problem_outlined;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          type,
          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    ),
  );
}
