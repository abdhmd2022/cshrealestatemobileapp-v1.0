import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/MaintenanceTicketCreation.dart';
import 'package:cshrealestatemobile/MaintenanceTicketFollowUp.dart';
import 'package:cshrealestatemobile/MaintenanceTicketTransfer.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;

class MaintenanceTicketReport extends StatefulWidget {
  @override
  _MaintenanceTicketReportState createState() =>
      _MaintenanceTicketReportState();
}

class _MaintenanceTicketReportState extends State<MaintenanceTicketReport> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> tickets = [];
  List<Map<String, dynamic>> filteredTickets = [];
  List<bool> _expandedTickets = [];
  String searchQuery = "";
  bool isLoading = false;
  Map<int, double> ratings = {};
  Map<int, String> feedbacks = {};

  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1); // ✅ First day of current month
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0); // ✅ Last day of current month


  TextEditingController commentController = TextEditingController();

  Future<void> openCaller(String no) async {
    final Uri phoneUri = Uri(scheme: "tel", path: no);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $phoneUri');
    }
  }



  List<dynamic> commentHistoryList = [];

  List<dynamic> feedbackHistoryList = [];

  @override
  void initState() {
    super.initState();
    // Initialize all tickets to be collapsed by default

    fetchTickets();
  }

  void _showFeedbackDialog(int ticketId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Apply appbar_color to full
          title: Text("Feedback"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: ratings[ticketId] ?? 3,
                minRating: 1,
                maxRating: 5,
                direction: Axis.horizontal,

                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() {
                    ratings[ticketId] = rating;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "Write your feedback...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: appbar_color),
                      borderRadius: BorderRadius.circular(8)

                  ),
                ),

                onChanged: (text) {
                  setState(() {
                    feedbacks[ticketId] = text;
                  });
                },
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
              style: TextStyle(
                color: Colors.black
              ),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appbar_color,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                String feedbackText = feedbacks[ticketId] ?? "";
                num rating = ratings[ticketId] ?? 3;
                saveFeedback(ticketId,feedbackText,rating);
                print("Submitted Feedback for $ticketId: Rating=$rating, Feedback=${feedbacks[ticketId]}");
                Navigator.pop(context);
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> fetchCommentHistory(String id) async {

    commentHistoryList.clear();

    String url = is_admin
        ? '$BASE_URL_config/v1/maintenanceComments/?ticket_id=$id'
        : '$BASE_URL_config/v1/tenent/maintenanceComments/?ticket_id=$id';

    String token = 'Bearer $Company_Token'; // Auth token

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {

      commentHistoryList = jsonData["data"]["comments"];
      // Filter only where lead_id == 6

      return commentHistoryList;
    } else {
      String message = 'Code: ${response.statusCode}\nMessage: ${jsonData['message']}';
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print('Upload failed with status code: ${response.statusCode}');
      print('Upload failed with response: ${response.body}');
      return commentHistoryList;
    }
  }

  Future<List<dynamic>> fetchFeedbackHistory(String id) async {

    feedbackHistoryList.clear();

    List<dynamic> filteredFeedbacks = [];

    String url = is_admin
        ? '$BASE_URL_config/v1/maintenanceFeedback/?ticket_id=$id'
        : '$BASE_URL_config/v1/tenent/maintenanceFeedback/?ticket_id=$id';;

    String token = 'Bearer $Company_Token'; // Auth token

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {

      feedbackHistoryList = jsonData["data"]["feedbacks"];

      filteredFeedbacks = feedbackHistoryList
          .where((feedback) => feedback["ticket_id"] == int.parse(id))
          .toList();
      // Filter only where lead_id == 6

      return filteredFeedbacks;
    } else {
      String message = 'Code: ${response.statusCode}\nMessage: ${jsonData['message']}';
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print('Upload failed with status code: ${response.statusCode}');
      print('Upload failed with response: ${response.body}');
      return filteredFeedbacks;
    }
  }



  void _showViewCommentPopup(BuildContext context,String id) async {
    List<dynamic> filteredData = [];

    try {
      filteredData = await fetchCommentHistory(id);
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
                          "Comments History",
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
                            ? Center(child: Text("No Comments Found"))
                            : ListView.builder(
                            itemCount: filteredData.length,
                            itemBuilder: (context, index) {
                              var item = filteredData.reversed.toList()[index];
                              var username = item["created_user"]?["name"] ?? item["tenent"]["name"];
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
                                                  username,
                                                  style: TextStyle(
                                                      fontSize: 16, fontWeight: FontWeight.w600),
                                                ),
                                                SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text(
                                                      item["description"],
                                                      style: TextStyle(
                                                        color: Colors.grey.shade800,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  "Date: ${formatDate(item["created_at"])}",
                                                  style: TextStyle(color: Colors.grey.shade700),
                                                ),
                                                if (item["remarks"] != null) ...[
                                                  SizedBox(height: 6),
                                                  Text(
                                                    "Description: ${item["description"]}",
                                                    style: TextStyle(color: Colors.grey.shade700),
                                                  ),
                                                ],
                                                ]))));}))]));}
    );
  }

  void _showViewFeedbackPopup(BuildContext context,String id) async {
    List<dynamic> filteredData = [];

    try {
      filteredData = await fetchFeedbackHistory(id);

      /*print('feedlack list $filteredData');*/
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
                          "Feedback",
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
                            ? Center(child: Text("No Feedback Found"))
                            : ListView.builder(
                            itemCount: filteredData.length,
                            itemBuilder: (context, index) {
                              var item = filteredData.reversed.toList()[index];
                              return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12), // Rounded corners

                                  ),

                                  child: Column(
                                    children: [

                                      Card(
                                        elevation: 3,
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12), // Rounded corners

                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Tenant Icon
                                              CircleAvatar(
                                                backgroundColor: appbar_color,
                                                radius: 22,
                                                child: Icon(Icons.person, color: Colors.white),
                                              ),
                                              SizedBox(width: 10),

                                              // Tenant & Flat Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['ticket']["tenent_flat"]['tenent']['name'],
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold),
                                                    ),

                                                    if(item!['ticket']["tenent_flat"]['tenent']['mobile'].toString() =='!null' && item!['ticket']["tenent_flat"]['tenent']['mobile'].toString().isNotEmpty)

                                                      Column(

                                                        children: [

                                                          SizedBox(height: 3),

                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [

                                                              GestureDetector(
                                                                onTap: ()
                                                                {
                                                                  openCaller(item!['ticket']["tenent_flat"]['tenent']['mobile']);
                                                                  /*openCaller("+971588313352");*/
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                        FontAwesomeIcons.phone,
                                                                        color: Colors.green,
                                                                        size: 14),
                                                                    SizedBox(width: 4),
                                                                    Text(
                                                                      "${item!['ticket']["tenent_flat"]['tenent']['mobile']}",
                                                                      style: GoogleFonts.poppins(fontSize: 12),
                                                                    )]))]),
                                                      ],),

                                                    SizedBox(height: 4),
                                                    Row(
                                                        children: [
                                                          Icon(Icons.email,
                                                              size: 16, color: Colors.blue),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            "${item!['ticket']["tenent_flat"]['tenent']['email']}",
                                                            style: GoogleFonts.poppins(fontSize: 12),
                                                          ),
                                                         ]),
                                                   ]))])
                                        )
                                      ),

                                      Card(
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
                                              Row(
                                                children: [
                                                  // Star Rating Widget
                                                  for (int i = 0; i < (item["ratings"]); i++)
                                                    Icon(Icons.star, color: Colors.amber, size: 20),
                                                  for (int i = (item["ratings"]); i < 5; i++)
                                                    Icon(Icons.star_border, color: Colors.amber, size: 20),
                                                ],
                                              ),

                                              SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item["description"],
                                                      style: TextStyle(
                                                        color: Colors.grey.shade900,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ))]),
                                              SizedBox(height: 8),
                                              Text(
                                                "Date: ${formatDate(item["created_at"])}",
                                                style: TextStyle(color: Colors.grey.shade700),
                                              ),
                                              /*if (item["remarks"] != null) ...[
                                                SizedBox(height: 6),
                                                Text(
                                                  "Remarks: ${item["remarks"]}",
                                                  style: TextStyle(color: Colors.grey.shade700),
                                                ),
                                              ],*/
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                              );}))]));}
    );
  }

  Future<void> fetchTickets() async {
    setState(() {
      isLoading = true;
    });

    String url = is_admin
        ? "$baseurl/v1/maintenance"
        : "$BASE_URL_config/v1/tenent/maintenance?tenent_id=$user_id&flat_id=$flat_id";

    print('Fetching tickets from URL: $url');

    try {
      final Map<String, String> headers = {
        'Authorization': 'Bearer $Company_Token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          final List<dynamic> apiTickets = responseBody['data']['tickets'];

          final List<Map<String, dynamic>> formattedTickets = apiTickets.map((apiTicket) {
            return {
              'ticketNumber': apiTicket['id'].toString(),
              'unitNumber': apiTicket['tenent_flat']['flat']['name'].toString(),
              'buildingName': apiTicket['tenent_flat']['flat']['building']['name'].toString(),
              'emirate': apiTicket['tenent_flat']['flat']['building']['area']['state']['name'] ?? 'N/A',
              'status': 'N/A',
              'date': apiTicket['created_at']?.split('T')[0] ?? '',
              'maintenanceTypes': apiTicket['sub_tickets'].map((subTicket) {
                return {
                  'subTicketId': subTicket['id'].toString(),
                  'type': subTicket['type']['name'],
                  'category': subTicket['type']['category']
                };
              }).toList(),
              'description': apiTicket['description'] ?? '',
            };
          }).toList();

          setState(() {
            tickets = formattedTickets;
            filterTickets(); // Apply date filter after fetching tickets
          });
        } else {
          print("API returned success: false");
        }
      } else {
        print("Error fetching data: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  /*Future<void> fetchTickets() async {
    setState(() {
      isLoading = true;
    });

    String url = is_admin
        ? "$BASE_URL_config/v1/maintenance"
        : "$BASE_URL_config/v1/tenent/maintenance?tenent_id=$user_id&flat_id=$flat_id";

    *//*final String url = "$BASE_URL_config/v1/maintenance"; // will change it for tenant*//*

    print('url $url');

    try {
      final Map<String, String> headers = {
        'Authorization': 'Bearer $Company_Token', // Example of an Authorization header
        'Content-Type': 'application/json', // Example Content-Type header
        // Add other headers as required
      };
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          // Transform the API data to match your UI format
          final List<dynamic> apiTickets = responseBody['data']['tickets'];
          final List<Map<String, dynamic>> formattedTickets = apiTickets.map((apiTicket) {
            return {
              'ticketNumber': apiTicket['id'].toString(),
              'unitNumber': apiTicket['tenent_flat']['flat']['name'].toString(),
              'buildingName':  apiTicket['tenent_flat']['flat']['building']['name'].toString(),
              'emirate': apiTicket['tenent_flat']['flat']['building']['area']['state']['name'] ?? 'N/A',
              'status': 'N/A', // Update this based on actual data if available
              'date': apiTicket['created_at']?.split('T')[0] ?? '',
              'maintenanceTypes': apiTicket['sub_tickets'].map((subTicket) {
                return {
                  'subTicketId': subTicket['id'].toString(),
                  'type': subTicket['type']['name'],
                  'category': subTicket['type']['category']
                };
              }).toList(), // Stores sub-ticket ID, type, and category as a list of maps
              'description': apiTicket['description'] ?? '',
            };
          }).toList();

          setState(() {
            tickets = formattedTickets;
            filteredTickets = tickets; // Initially set to show all tickets
            _expandedTickets = List<bool>.filled(tickets.length, false);
          });
        } else {
          print("API returned success: false");
        }
      } else {
        print("Error fetching data: ${response.statusCode}");
        print("Error fetching data: ${response.body}");

      }
    } catch (e) {
      print("Error fetching data: $e");
    }
    setState(() {
      isLoading = false;
    });
  }*/

  Future<void> saveFeedback(int ticketId, String description, num rating) async {

    try {
      final String url = "$BASE_URL_config/v1/tenent/maintenanceFeedback";

      var uuid = Uuid();
      String uuidValue = uuid.v4();

      final Map<String, dynamic> requestBody = {
        "uuid": uuidValue,
        "ticket_id": ticketId, // Updated key from flat_masterid to flat_id
        "description": description,
        "ratings": rating.toInt(), // Converts the list of objects to a list of IDs
      };

      print('feedback body ${requestBody}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Company_Token",
        },
        body: jsonEncode(requestBody),
      );
      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        String message = responseData['message'];
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        ratings.clear();

      } else {

        String message = 'Code: ${response.statusCode}\nMessage: ${responseData['message']}';
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print('Upload failed with status code: ${response.statusCode}');
        print('Upload failed with response: ${response.body}');
      }
    } catch (e) {
      print('Error during upload: $e');
    }
  }

  Future<void> saveComment(int ticketId, String description) async {

    try {
      String url = is_admin
          ? "$BASE_URL_config/v1/maintenanceComments"
          : "$BASE_URL_config/v1/tenent/maintenanceComments";

      var uuid = Uuid();
      String uuidValue = uuid.v4();

      final Map<String, dynamic> requestBody = {
        "uuid": uuidValue,
        "ticket_id": ticketId, // Updated key from flat_masterid to flat_id
        "description": description,
      };

      print('comments body ${requestBody}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Company_Token",
        },
        body: jsonEncode(requestBody),
      );
      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        String message = responseData['message'];
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      else {
        String message = 'Code: ${response.statusCode}\nMessage: ${responseData['message']}';
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print('Upload failed with status code: ${response.statusCode}');
        print('Upload failed with response: ${response.body}');
      }
    } catch (e) {
      print('Error during upload: $e');
    }
  }

  /*void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredTickets = tickets
          .where((ticket) =>
      ticket['ticketNumber'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['unitNumber'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['buildingName'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['emirate'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['status'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['maintenanceType'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }*/

  void filterTickets() {
    print("Filtering tickets by date...");
    _applyFilters(); // ✅ This now applies BOTH filters
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
    _applyFilters(); // ✅ This now applies BOTH filters
  }

  void _applySearchFilter(List<Map<String, dynamic>> listToFilter) {
    setState(() {
      filteredTickets = listToFilter.where((ticket) {
        // Ensure 'maintenanceTypes' is a List before using `.any()`
        bool hasMatchingSubTicket = ticket['maintenanceTypes'] is List &&
            (ticket['maintenanceTypes'] as List).any((subTicket) =>
            subTicket is Map &&
                subTicket.containsKey('type') &&
                subTicket['type'] is String &&
                subTicket['type'].toLowerCase().contains(searchQuery.toLowerCase()));

        return ticket['ticketNumber'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            ticket['unitNumber'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            ticket['buildingName'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            ticket['emirate'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            ticket['status'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            hasMatchingSubTicket; // ✅ Uses the correct `any()` check
      }).toList();

      _expandedTickets = List<bool>.filled(filteredTickets.length, false);
    });

    print("Final Filtered Tickets Count: ${filteredTickets.length}");
  }

  void _applyFilters() {
    print("Applying both Date and Search Filters...");

    // 1️⃣ First, filter by date
    List<Map<String, dynamic>> dateFilteredTickets = tickets.where((ticket) {
      DateTime? ticketDate;
      try {
        ticketDate = DateTime.parse(ticket['date']);
      } catch (e) {
        print("Invalid Date: ${ticket['date']}");
        ticketDate = null;
      }

      bool withinDateRange = ticketDate != null &&
          (ticketDate.isAtSameMomentAs(startDate) || ticketDate.isAfter(startDate.subtract(Duration(days: 1)))) &&
          (ticketDate.isBefore(endDate.add(Duration(days: 1))) || ticketDate.isAtSameMomentAs(endDate));

      return withinDateRange;
    }).toList();

    _applySearchFilter(dateFilteredTickets);
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
                hintText: 'Search Ticket',
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
          onTap: ()
          {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),

        backgroundColor: appbar_color.withOpacity(0.9),
        centerTitle: true,
        title: Text(
          'Maintenance Tickets',
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
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
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
                        filterTickets(); // ✅ Apply date filter
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
                ],
              ),
            ),

            isLoading
                ? Expanded(child: Center(
              child: Platform.isIOS
                  ? CupertinoActivityIndicator(
                radius: 15.0, // Adjust size if needed
              )
                  : CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // Change color here
                strokeWidth: 4.0, // Adjust thickness if needed
              ),
            )
              ,)
                : filteredTickets.isEmpty
                ? Expanded(
              child:  Center(
                child: Text(
                  "No data available",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            )
              : Expanded(
              child: ListView.builder(
              itemCount: filteredTickets.length,
              itemBuilder: (context, index) {
                final ticket = filteredTickets[index];
                return _buildTicketCard(ticket, index);
              },
            ),
            )
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
              MaterialPageRoute(builder: (context) => MaintenanceTicketCreation()),
              );
          },
          label: Text(
            'New Ticket',
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

  Widget _buildTicketCard(Map<String, dynamic> ticket, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedTickets[index] = !_expandedTickets[index];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
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
            _buildTicketHeader(ticket),
            Divider(color: Colors.grey[300]),
            _buildTicketDetails(ticket),
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
                            Row(children: [

                              if(is_admin)
                              _buildDecentButton(
                                'Follow Up',
                                Icons.schedule,
                                Colors.orange,
                                    () {
                                      print('ticket : $ticket');
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => MaintenanceFollowUpScreen(ticketid: ticket['ticketNumber'],)),
                                      );
                                    }
                              ),
                              SizedBox(width: 5),
                              if(is_admin)
                              _buildDecentButton(
                                'Transfer',
                                Icons.swap_horiz,
                                Colors.purple,
                                    () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => MaintenanceTicketTransfer(/*name: ticket., id: id, email: email*/)),
                                      );
                                },
                              ),
                              SizedBox(width: 5),

                              _buildDecentButton(
                                'Comment',
                                Icons.comment,
                                Colors.green,
                                    () {
                                      commentController.clear();
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white, // Apply appbar_color to full
                                                title: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [

                                                    Text(
                                                      "Comment",
                                                      style: TextStyle(color: Colors.black),
                                                    ),


                                                    GestureDetector(
                                                      onTap: ()
                                                      {
                                                        _showViewCommentPopup(context,ticket['ticketNumber']);

                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: appbar_color, width: 1), // Border color and width
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        padding: EdgeInsets.all(8), // Padding for spacing inside the border
                                                        child: Icon(
                                                          Icons.remove_red_eye,
                                                          color: appbar_color,
                                                        ),
                                                      )
                                                    )

                                                  ],
                                                ),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Input field for the message
                                                    TextField(
                                                      controller: commentController,
                                                      maxLines: 3,
                                                      style: TextStyle(color: Colors.black),
                                                      decoration: InputDecoration(
                                                        hintText: "Enter your comment",
                                                        hintStyle: TextStyle(color: Colors.black54),
                                                        border: OutlineInputBorder(
                                                          borderSide: BorderSide(color: Colors.black),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: appbar_color),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      commentController.clear();
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                    child: Text("Cancel", style: TextStyle(color: appbar_color)),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: appbar_color,
                                                      foregroundColor: Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      String comment = commentController.text;
                                                      if (comment.isNotEmpty) {

                                                        Navigator.of(context).pop(); // Close the dialog

                                                        saveComment(int.parse(ticket['ticketNumber']),comment);

                                                      } else {
                                                        Fluttertoast.showToast(
                                                          msg: 'Enter Comment',
                                                          toastLength: Toast.LENGTH_SHORT, // or Toast.LENGTH_LONG
                                                          gravity: ToastGravity.BOTTOM, // Can be TOP, CENTER, or BOTTOM
                                                          backgroundColor: Colors.black,
                                                          textColor: Colors.white,
                                                          fontSize: 16.0,
                                                        );
                                                      }
                                                    },
                                                    child: Text("Submit"),
                                                  ),
                                                ]);});});}
                              ),
                              SizedBox(width: 5),

                              if(!is_admin)
                              _buildDecentButton(
                                'Feedback',
                                Icons.feedback,
                                Colors.blue,
                                    () {
                                      _showFeedbackDialog(int.parse(ticket['ticketNumber']));
                                    }
                              ),
                              if(is_admin)
                              _buildDecentButton(
                                  'Feedback',
                                  Icons.feedback,
                                  Colors.blue,
                                      () {
                                    _showViewFeedbackPopup(context,ticket['ticketNumber']);
                                  }
                              ),
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

            if (_expandedTickets[index]) _buildExpandedTicketView(ticket),
            SizedBox(height: 10), // Top space before the toggle
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedTickets[index] = !_expandedTickets[index];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expandedTickets[index] ? "View Less" : "View More",
                        style: TextStyle(
                          color: Colors.black26,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        _expandedTickets[index] ? Icons.expand_less : Icons.expand_more,
                        color: Colors.black26,
                        size: 16,
                      ),
                    ]))))])));
  }

  Widget _buildTicketHeader(Map<String, dynamic> ticket) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.confirmation_number, color: Colors.teal, size: 24.0),
            SizedBox(width: 8.0),
            Text(
              ticket['ticketNumber'],
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        _getStatusBadge(ticket['status']),
      ],
    );
  }

  Widget _buildTicketDetails(Map<String, dynamic> ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Unit:', ticket['unitNumber']),
        _buildInfoRow('Building:', '${ticket['buildingName']}, ${ticket['emirate']}'),
       /* _buildInfoRow('Emirate:', ticket['emirate']),*/
        _buildInfoRow_subtype(
          'Type:',
          (ticket['maintenanceTypes'] != null && ticket['maintenanceTypes'].isNotEmpty)
              ? ticket['maintenanceTypes'].map((type) => type['type'] ?? 'Unknown').join(', ')
              : 'N/A',
        ),
        _buildInfoRow('Date:', DateFormat('dd-MMM-yyyy').format(DateTime.parse(ticket['date']))),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow_subtype(String label, String? value) {
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
                value ?? 'N/A', // Ensure a fallback for null values
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'In Progress':
        color = Colors.orange;
        break;
      case 'Resolved':
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

  Widget _buildExpandedTicketView(Map<String, dynamic> ticket) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Description:', ticket['description']),
        ],
      ),
    );
  }
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

Widget _buildDecentButtonWithLabel(String label, IconData icon, Color color,
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



