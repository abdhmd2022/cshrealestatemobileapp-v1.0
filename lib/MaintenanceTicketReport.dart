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
import 'package:intl/intl.dart';
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

  TextEditingController commentController = TextEditingController();

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

  Future<void> fetchTickets() async {
    setState(() {
      isLoading = true;
    });

    String url = is_admin
        ? "$BASE_URL_config/v1/maintenance"
        : "$BASE_URL_config/v1/tenent/maintenance?tenent_id=$user_id&flat_id=$flat_id";

    /*final String url = "$BASE_URL_config/v1/maintenance"; // will change it for tenant*/

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
              'ticketNumber': apiTicket['id'].toString() ?? '',
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
  }

  Future<void> saveFeedback(int ticketId, String description, num ratings) async {

    try {
      final String url = "$BASE_URL_config/v1/tenent/maintenanceFeedback";

      var uuid = Uuid();
      String uuidValue = uuid.v4();

      final Map<String, dynamic> requestBody = {
        "uuid": uuidValue,
        "ticket_id": ticketId, // Updated key from flat_masterid to flat_id
        "description": description,
        "ratings": ratings.toInt(), // Converts the list of objects to a list of IDs
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
      final String url = "$BASE_URL_config/v1/tenent/maintenanceComments";

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

  void _updateSearchQuery(String query) {
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
        child: isLoading
            ? Center(
          child: Platform.isIOS
              ? CupertinoActivityIndicator(
            radius: 15.0, // Adjust size if needed
          )
              : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // Change color here
            strokeWidth: 4.0, // Adjust thickness if needed
          ),
        )
            : filteredTickets.isEmpty
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
          itemCount: filteredTickets.length,
          itemBuilder: (context, index) {
            final ticket = filteredTickets[index];
            return _buildTicketCard(ticket, index);
          },
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
                                                title: Text(
                                                  "Comment",
                                                  style: TextStyle(color: Colors.black),
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

                              _buildDecentButton(
                                'Feedback',
                                Icons.feedback,
                                Colors.blue,
                                    () {
                                      _showFeedbackDialog(int.parse(ticket['ticketNumber']));
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



