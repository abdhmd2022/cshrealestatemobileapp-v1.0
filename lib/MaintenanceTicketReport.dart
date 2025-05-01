import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/MaintenanceTicketCreation.dart';
import 'package:cshrealestatemobile/MaintenanceTicketFollowUp.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  String getFormattedDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return "Today";
    } else if (messageDate == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('dd-MMM-yyyy').format(date); // 👈 Uses MMM format
    }
  }


  @override
  void initState() {
    super.initState();
    // Initialize all tickets to be collapsed by default
    fetchAllTickets();
  }


  void _showFeedbackDialog(int ticketId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Apply appbar_color to full
          title: Text("Feedback",
          style: GoogleFonts.poppins(),),
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
              style: GoogleFonts.poppins(
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
              child: Text("Submit",style: GoogleFonts.poppins(),),
            ),
          ]);});}

  Future<Map<String, dynamic>> fetchCommentHistory(String id, {int page = 1}) async {
    // ✅ Don't clear list here, let popup manage list updates
    String url = '$baseurl/maintenance/comment/?ticket_id=$id&page=$page'; // 🔥 Added page=$page

    print('url comment $url');
    String token = 'Bearer $Company_Token'; // Auth token

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json",
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return jsonData; // 🔥 Return full response (comments + meta info)
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<List<dynamic>> fetchFeedbackHistory(String id) async {

    feedbackHistoryList.clear();


    print('ticket id for feedback : $id');

    String url = '$baseurl/maintenance/feedback/?ticket_id=$id';

    String token = 'Bearer $Company_Token'; // Auth token

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {

      feedbackHistoryList = jsonData["data"]["feedbacks"];

      print('feeback length = ${feedbackHistoryList.length}');

      if(feedbackHistoryList.isEmpty)
        {
          Fluttertoast.showToast(
            msg: "No Feedback Found",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }



      return feedbackHistoryList;
    } else {
      String message = '${jsonData['message']}';
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
      return feedbackHistoryList;
    }
  }

  void _showViewCommentPopup(BuildContext contextt, String id, String currentScope,String status) async {
    List<dynamic> filteredData = [];
    TextEditingController commentController = TextEditingController();
    ScrollController scrollController = ScrollController();
    bool isSubmitting = false;

    int currentPage = 1;
    bool isLoadingMore = false;
    bool hasMoreData = true;
    bool scrollListenerAdded = false;
    bool initialScrollDone = false; // ✅ To scroll once on open

    Future<void> fetchComments({bool loadMore = false}) async {
      try {
        var response = await fetchCommentHistory(id, page: currentPage);
        List<dynamic> newComments = response['data']['comments'] ?? [];
        var meta = response['meta'];

        if (loadMore) {
          filteredData.addAll(newComments);
        } else {
          filteredData = newComments.toList();
        }

        if (newComments.isNotEmpty) {
          currentPage++;
        }

        hasMoreData = (filteredData.length < meta['totalCount']);
      } catch (e) {
        print('Error fetching comments: $e');
      }
    }

    await fetchComments(); // 🔥 Load first page initially

    showModalBottomSheet(
      context: contextt,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (contextt) {
        return StatefulBuilder(
          builder: (contextt, setState) {
            if (!scrollListenerAdded) {
              scrollController.addListener(() async {
                if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 100 &&
                    !isLoadingMore &&
                    hasMoreData) {
                  setState(() => isLoadingMore = true);

                  await fetchComments(loadMore: true);

                  setState(() => isLoadingMore = false);
                }
              });
              scrollListenerAdded = true;
            }

            // 🔥 Auto-scroll to bottom once after popup open
            if (!initialScrollDone && filteredData.isNotEmpty) {
              Future.delayed(Duration(milliseconds: 100), () {
                if (scrollController.hasClients) {
                  scrollController.jumpTo(scrollController.position.maxScrollExtent);
                  initialScrollDone = true;
                }
              });
            }

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              height: MediaQuery.of(contextt).size.height * 0.7,
              color: Colors.white,
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Comments",
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(contextt),
                      ),
                    ],
                  ),
                  Divider(),

                  // Comments List
                  Expanded(
                    child: filteredData.isEmpty
                        ? Center(child: Text("No Comments Found", style: GoogleFonts.poppins()))
                        : ListView.builder(
                      controller: scrollController,
                      itemCount: filteredData.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (contextt, index) {
                          if (isLoadingMore && index == filteredData.length) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          var item = filteredData[index];

                          bool isCurrentUserComment = false;

                          if (currentScope == 'user') {
                            isCurrentUserComment = item['created_by'] != null;
                          } else if (currentScope == 'tenant') {
                            isCurrentUserComment = item['tenant_id'] != null;
                          }

                          String username = item['tenant_id'] != null
                              ? (item["tenant"] != null ? (item["tenant"]["name"] ?? "Tenant") : "Tenant")
                              : (item["created_user"] != null ? (item["created_user"]["name"] ?? "Admin") : "Admin");

                          // Get current message date (only date part)
                          DateTime messageDate = DateTime.parse(item["created_at"]).toLocal();
                          String messageDateString = "${messageDate.year}-${messageDate.month}-${messageDate.day}";

                          // Check if we need to show a date separator
                          bool showDateSeparator = false;
                          if (index == 0) {
                            showDateSeparator = true;
                          } else {
                            var previousItem = filteredData[index - 1];
                            DateTime previousDate = DateTime.parse(previousItem["created_at"]).toLocal();
                            String previousDateString = "${previousDate.year}-${previousDate.month}-${previousDate.day}";
                            if (messageDateString != previousDateString) {
                              showDateSeparator = true;
                            }
                          }

                          List<Widget> widgets = [];

                          if (showDateSeparator) {
                            widgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      getFormattedDateLabel(messageDate),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),

                                  ),
                                ),
                              ),
                            );
                          }

                          widgets.add(
                            Container(
                              alignment: isCurrentUserComment ? Alignment.centerRight : Alignment.centerLeft,
                              margin: EdgeInsets.symmetric(vertical: 6),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(contextt).size.width * 0.7,
                                ),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCurrentUserComment ? appbar_color.withOpacity(0.9) : Colors.grey.shade300,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: isCurrentUserComment ? Radius.circular(16) : Radius.circular(0),
                                    bottomRight: isCurrentUserComment ? Radius.circular(0) : Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: isCurrentUserComment ? Colors.white70 : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      item["description"] ?? "",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: isCurrentUserComment ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      formatDate(item["created_at"]),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: isCurrentUserComment ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          return Column(
                            children: widgets,
                          );
                        }

                    ),
                  ),

                  if(status!='Close')...[
                    SizedBox(height: 10),

                    // Comment input area
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            maxLines: null,

                            style: GoogleFonts.poppins(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: "Type your message...",
                              hintStyle: GoogleFonts.poppins(color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade400),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: appbar_color),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: isSubmitting
                              ? null
                              : () async {
                            if (commentController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(contextt).showSnackBar(
                                SnackBar(
                                  content: Text("Please enter a comment!", style: GoogleFonts.poppins()),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() => isSubmitting = true);

                            bool success = await saveComment(id, commentController.text.trim());

                            if (success) {
                              setState(() {
                                filteredData.add({
                                  "description": commentController.text.trim(),
                                  "created_at": DateTime.now().toIso8601String(),
                                  currentScope == 'user' ? "created_by" : "tenant_id": 1,
                                  "tenant": currentScope == 'tenant' ? {"name": "You"} : null,
                                  "created_user": currentScope == 'user' ? {"name": "You"} : null,
                                });
                                commentController.clear();
                              });

                              // 🔥 Smooth scroll to bottom after sending
                              Future.delayed(Duration(milliseconds: 100), () {
                                if (scrollController.hasClients) {
                                  scrollController.animateTo(
                                    scrollController.position.maxScrollExtent,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });
                            }

                            setState(() => isSubmitting = false);
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: appbar_color,
                            child: isSubmitting
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                                : Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],


                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
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
    if(filteredData.isNotEmpty)
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
                            ? Center(child: Text("No Feedback Found",style: GoogleFonts.poppins(),))
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

                                      /*Card(
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
                                                   *//* Text(
                                                      item['ticket']["tenent_flat"]['tenent']['name'],
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold),
                                                    ),*//*

                                                    *//*if(item!['ticket']["tenent_flat"]['tenent']['mobile'].toString() =='!null' && item!['ticket']["tenent_flat"]['tenent']['mobile'].toString().isNotEmpty)

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
                                                                  *//**//*openCaller("+971588313352");*//**//*
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
                                                         ]),*//*
                                                   ]))])
                                        )
                                      ),*/

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
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.grey.shade900,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ))]),
                                              SizedBox(height: 8),
                                              Text(
                                                "Date: ${formatDate(item["created_at"])}",
                                                style: GoogleFonts.poppins(color: Colors.grey.shade700),
                                              ),
                                              /*if (item["remarks"] != null) ...[
                                                SizedBox(height: 6),
                                                Text(
                                                  "Remarks: ${item["remarks"]}",
                                                  style: GoogleFonts.poppins(color: Colors.grey.shade700),
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

  int currentPage = 1;
  int totalPages = 1;
  bool isFetchingMore = false;

  Future<void> fetchAllTickets() async {
    List<Map<String, dynamic>> allFormattedTickets = [];
    int page = 1;
    bool hasMore = true;

    setState(() {
      isLoading = true;
      isFetchingMore = false;
    });

    try {
      while (hasMore) {
        String url = is_admin
            ? "$baseurl/maintenance/ticket?page=$page"
            : "$baseurl/maintenance/ticket/?tenant_id=$user_id&flat_id=$flat_id&page=$page";

        final response = await http.get(Uri.parse(url), headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        });

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseBody = json.decode(response.body);

          if (responseBody['success'] == true) {
            final List<dynamic> apiTickets = responseBody['data']['tickets'];

            final List<Map<String, dynamic>> formattedTickets = apiTickets.map((apiTicket) {
              final contractFlat = apiTicket['contract_flat'];
              final flat = contractFlat['flat'];
              final building = flat['building'];
              final area = building['area'];
              final state = area['state'];

              return {
                'ticketNumber': "${apiTicket['id']}",
                'unitNumber': flat['name'] ?? 'N/A',
                'buildingName': building['name'] ?? 'N/A',
                'emirate': state['name'] ?? 'N/A',
                /*'status': apiTicket['sub_tickets'].isNotEmpty
                    ? apiTicket['sub_tickets'][0]['followps'].isNotEmpty
                    ? apiTicket['sub_tickets'][0]['followps'][0]['status']['name']
                    : 'N/A'
                    : 'N/A',*/
                'status': (() {
                  final subTickets = apiTicket['sub_tickets'] as List<dynamic>;
                  if (subTickets.isEmpty) return null;

                  bool allFollowupsMissing = true;
                  bool allClosed = true;

                  for (var sub in subTickets) {
                    final followUps = sub['followps'] as List<dynamic>;

                    if (followUps.isEmpty) {
                      allClosed = false;
                      continue;
                    }

                    allFollowupsMissing = false;

                    final lastFollowUp = followUps.last;
                    final category = lastFollowUp['status']['category'];

                    if (category != "Close") {
                      allClosed = false;
                    }
                  }

                  if (allFollowupsMissing) return "Pending";
                  return allClosed ? "Close" : "Normal";
                })(),



                'date': apiTicket['created_at']?.split('T')[0] ?? '',
                'maintenanceTypes': (apiTicket['sub_tickets'] as List<dynamic>).map((subTicket) {
                  final type = subTicket['type'];
                  return {
                    'subTicketId': subTicket['id'].toString(),
                    'type': type['name'],
                    'category': type['category'] ?? 'N/A',
                  };
                }).toList(),
                'description': apiTicket['description'] ?? '',
              };
            }).toList();

            allFormattedTickets.addAll(formattedTickets);

            final meta = responseBody['meta'];
            final currentPage = meta['page'];
            final totalPages = (meta['totalCount'] / meta['size']).ceil();

            hasMore = currentPage < totalPages;
            page++;
          } else {
            hasMore = false;
          }
        } else {
          hasMore = false;
          print("Error: ${response.statusCode}, ${response.body}");
        }
      }

      setState(() {
        tickets = allFormattedTickets;
        filterTickets(); // optional if you’re filtering
      });
    } catch (e) {
      print("Error fetching all tickets: $e");
    } finally {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
    }
  }


  // updated on 18 mar 2025
  /*Future<void> fetchTickets() async {
    setState(() {
      isLoading = true;
    });


    String url = is_admin
        ? "$baseurl/maintenance/ticket"
        : "$baseurl/maintenance/ticket"; *//*"$baseurl/maintenance/?tenent_id=$user_id&flat_id=$flat_id";*//*


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

        // to display error message and error status code
        Map<String, dynamic> data = json.decode(response.body);
        String error = '';

        if (data.containsKey('message')) {
          setState(() {
            error = 'Code: ${response.statusCode} , Message: ${data['message']}';
          });
        }
        else
        {
          error = 'Something went wrong!!!';
        }
        Fluttertoast.showToast(msg: error);

        print("Error fetching data: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }*/

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
      final String url = "$baseurl/maintenance/feedback";

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

  Future<bool> saveComment(String ticketId, String description) async {
    try {
      String url = "$baseurl/maintenance/comment";

      var uuid = Uuid();
      String uuidValue = uuid.v4();

      final Map<String, dynamic> requestBody = {
        "uuid": uuidValue,
        "ticket_id": ticketId,
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
        /*Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );*/
        print(message);
        return true; // ✅ Return true on success
      } else {
        String message = 'Code: ${response.statusCode}\nMessage: ${responseData['message']}';
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print('Upload failed with status code: ${response.statusCode}');
        print('Upload failed with response: ${response.body}');
        return false; // ✅ Return false on failure
      }
    } catch (e) {
      print('Error during upload: $e');
      return false; // ✅ Return false if there's an error
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
      }).toList().reversed.toList();

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
                labelStyle: GoogleFonts.poppins(),
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
                ? Expanded(child: Center(
              child: Platform.isIOS
                  ? CupertinoActivityIndicator(
                radius: 15.0, // Adjust size if needed
              )
                  : CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(appbar_color), // Change color here
                strokeWidth: 4.0, // Adjust thickness if needed
              ),
            )
              ,)
                : filteredTickets.isEmpty
                ? Expanded(
              child:  Center(
                child: Text(
                  "No data available",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ) :
            Expanded(
              child: ListView.builder(
                itemCount: filteredTickets.length + (isFetchingMore ? 1 : 0), // 🔥 Corrected
                itemBuilder: (context, index) {
                  if (isFetchingMore && index == filteredTickets.length) {
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
            style: GoogleFonts.poppins(
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
            // List subtickets with transfer button
            Column(
              children: [
                // Other buttons (Follow-up, Comment, Feedback)

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (is_admin && ticket['status'] != 'Close')
                      _buildDecentButton(
                        'Follow Up',
                        Icons.schedule,
                        Colors.orange,
                            () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MaintenanceFollowUpScreen(
                                ticketid: ticket['ticketNumber'],
                              ),
                            ),
                          );
                        },
                      ),
                    SizedBox(width: 5),

                    if (ticket['status'] == 'Close' && is_admin) ...[
                      _buildDecentButton(
                        'Comment',
                        Icons.comment,
                        Colors.green,
                            () {
                          commentController.clear();
                          _showViewCommentPopup(context, ticket['ticketNumber'], scope, ticket['status']);
                        },
                      ),
                      SizedBox(width: 5),
                    ] else if (ticket['status'] != 'Close') ...[
                      _buildDecentButton(
                        'Comment',
                        Icons.comment,
                        Colors.green,
                            () {
                          commentController.clear();
                          _showViewCommentPopup(context, ticket['ticketNumber'], scope, ticket['status']);
                        },
                      ),
                      SizedBox(width: 5),
                    ],



                    if (!is_admin)...[
                      if(ticket['status']=='Close')
                      _buildDecentButton(
                        'Feedback',
                        Icons.feedback,
                        Colors.blue,
                            () {
                          _showFeedbackDialog(int.parse(ticket['ticketNumber'])); // Existing Feedback Section
                        },
                      ),
                    ],

                    if (is_admin)...[
                      if(ticket['status']=='Close')
                      _buildDecentButton(
                        'Feedback',
                        Icons.feedback,
                        Colors.blue,
                            () {
                          _showViewFeedbackPopup(context, ticket['ticketNumber']); // Admin View Feedback
                        },
                      ),
                    ]
                  ],
                ),
                SizedBox(height: 10,),
                // Subtickets list (Each with only "Transfer" button)
            if(is_admin && ticket['status']!='Close')
            Column(
            children: ticket['maintenanceTypes'].map<Widget>((subTicket) {
      return Container(
      margin: EdgeInsets.symmetric(vertical: 3, horizontal: 0),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
      BoxShadow(
      color: Colors.black.withOpacity(0.07),
      blurRadius: 5,
      spreadRadius: 4,
      offset: Offset(0, 4),
      ),
      ],
      ),
      child: Row(
      children: [
      // Left Side: Subticket Info
      Expanded(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(
      subTicket['type'],
      style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      ),
      overflow: TextOverflow.ellipsis,
      ),

      ],
      ),
      ),

      // Transfer Button with Gradient Effect
      InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
      _showTransferDialog(context, subTicket['subTicketId']);
      },
      child:

      Container(
        margin: EdgeInsets.only(top: 0.0),
        padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          color: Colors.white,
          border: Border.all(
            color: Colors.redAccent.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.1),
              blurRadius: 8.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.swap_horiz, color: Colors.redAccent),
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







      ),
      ],
      ),
      );
      }).toList(),
    ),
              ],
            ),

            if (_expandedTickets[index]) _buildExpandedTicketView(ticket),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedTickets[index] = !_expandedTickets[index];
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expandedTickets[index] ? "View Less" : "View More",
                      style: GoogleFonts.poppins(
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              "MT-${ticket['ticketNumber']} - ${ticket['status']}",
              style: GoogleFonts.poppins(
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
                value ?? 'N/A', // Ensure a fallback for null values
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(String category) {
    String label;
    Color color;

    switch (category) {
      case 'Close':
        label = 'Closed';
        color = Colors.green;
        break;
      case 'Normal':
        label = 'In Progress';
        color = Colors.orange;
        break;
      case 'null':
      case '':
      case 'N/A':
      case 'Pending':
        label = 'Pending';
        color = Colors.orange;
        break;
      default:
        label = category;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
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

void _showTransferDialog(BuildContext context, String subTicketId) {
  String? selectedTechnicianId;
  List<Map<String, dynamic>> technicians = []; // List to store fetched technicians
  bool isLoading = true;

  // Fetch Technician List
  Future<void> fetchTechnicians(StateSetter setState) async {
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

          technicians = usersJson
              .where((user) => user['id'] != user_id) // Fixed comparison
              .map((userJson) {
            return {
              'id': userJson['id'].toString(),
              'name': userJson['name'],
            };
          }).toList();

          print('technicians: ${technicians}');
        }
      }
    } catch (e) {
      print("Error fetching technicians: $e");
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
          // 👇 Only call fetchTechnicians ONCE after the first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isLoading) fetchTechnicians(setState);
          });

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            title: Text(
              "Transfer Job",
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
                else if (technicians.isEmpty)
                  Text(
                    "No technicians available.",
                    style: GoogleFonts.poppins(color: Colors.black87),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedTechnicianId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "Select Person",
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
                    items: technicians.map<DropdownMenuItem<String>>((tech) {
                      return DropdownMenuItem<String>(
                        value: tech['id'].toString(),
                        child: Text(
                          tech['name'],
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTechnicianId = newValue;
                        print('technician id : $selectedTechnicianId');
                      });
                    },
                  ),
                SizedBox(height: 10),
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
                  if (selectedTechnicianId == null) {
                    Fluttertoast.showToast(msg: "Please select!");
                    return;
                  }
                  _transferSubTicket(subTicketId, selectedTechnicianId!);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appbar_color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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

Future<void> _transferSubTicket(String subTicketId, String technicianId) async {
  String url = "$baseurl/maintenance/subticket/$subTicketId";

  try {
    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $Company_Token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'assigned_to': technicianId, // Selected technician ID
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
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
    } else {
      final data = json.decode(response.body);
      String errorMessage = data['message'] ?? "Something went wrong!";
      Fluttertoast.showToast(
        msg: "Error: $errorMessage",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  } catch (e) {
    Fluttertoast.showToast(
      msg: "Error: $e",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
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
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    ),
  );
}



