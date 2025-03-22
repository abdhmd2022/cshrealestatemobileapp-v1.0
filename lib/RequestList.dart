import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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

  final Color appbarColor = appbar_color;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseurl/tenant/request'),
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
        final allRequests = jsonData['data']['requests'] as List;
        final filteredRequests = allRequests.where((req) => req['flat_id'] == flat_id).toList();

        setState(() {
          requests= filteredRequests.reversed.toList();


        });

      }
    } catch (e) {
      print("Error fetching requests: $e");
    } finally {
      setState(() => isLoading = false);
    }
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
        backgroundColor: appbarColor,
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
                MaterialPageRoute(builder: (_) => SpecialRequestScreen()),
              ),
              backgroundColor: Colors.transparent,
              elevation: 30,
              child: Icon(Icons.add_rounded, size: 28, color: Colors.white),

            ),
          ),
        ),
      ),

      body: isLoading
          ? Center(
        child: Platform.isIOS
            ? const CupertinoActivityIndicator(radius: 18)
            : CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(appbarColor),
        ),
      )
          : requests.isEmpty
          ? Center(
        child: Text("No requests found", style: GoogleFonts.poppins()),
      )
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          final req_id = req["id"];
          final flat = req['contract_flat']['flat'];
          final building = flat['building'];
          final area = building['area'];
          final state = area['state'];

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
                      _getRequestStatusBadge(req['is_approved']),
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
                          "${flat['name']} • ${building['name']}",
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );


        },
      ),
    );
  }
}
Widget _getRequestStatusBadge(dynamic isApproved) {
  String status;
  Color color;

  if (isApproved == null) {
    status = "Pending";
    color = Colors.orange;
  } else if (isApproved == "true") {
    status = "Approved";
    color = Colors.green;
  } else {
    status = "Rejected";
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

