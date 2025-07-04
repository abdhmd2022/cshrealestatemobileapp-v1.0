import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cshrealestatemobile/MaintenanceTicketCreation.dart';
import 'package:cshrealestatemobile/MaintenanceTicketFollowUp.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'Sidebar.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';



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
    if(hasPermission('canViewMaintenanceTickets')){
      fetchAllTickets();
    }

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

    if(hasPermission('canViewTicketComment')){
      await fetchComments(); // 🔥 Load first page initially
    }


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
                  if(hasPermission('canViewTicketComment'))...[
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
                            else if (currentScope == 'landlord') {
                              isCurrentUserComment = item['landlord_id'] != null;
                            }


                            String username;
                            if (item['tenant_id'] != null) {
                              username = item["tenant"]?["name"] ?? "Tenant";
                            } else if (item['landlord_id'] != null) {
                              if (currentScope == 'landlord' && item['landlord_id'] != null) {
                                // It's *this* landlord's comment
                                username = "You";
                              } else {
                                // Some other landlord (if relevant)
                                username = "Landlord";

                              }
                            } else if (item["created_user"] != null) {
                              username = item["created_user"]["name"] ?? "Admin";
                            } else {
                              username = "Admin";
                            }

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
                                          fontWeight: FontWeight.w600,
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
                                        DateFormat('hh:mm a').format(DateTime.parse(item["created_at"]).toLocal()),

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
                  ]
                  else...[
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
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
                            "You don’t have permission to view comments.",
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      )
                      ),
                    ),
                  ],


                  if(status!='Close')...[


                    // Comment input area
                    if(hasPermission('canCreateTicketComment'))...[
                      SizedBox(height: 10),
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
                currentScope == 'user'
                    ? "created_by"
                    : currentScope == 'tenant'

                    ? "tenant_id"
                    : currentScope == 'landlord'
                    ? "landlord_id"
                    : null: 1,
                "tenant": currentScope == 'tenant' ? {"name": "You"} : null,
                "created_user": currentScope == 'user' ? {"name": "You"} : null,
                "landlord": currentScope == 'landlord' ? {"name": "You"} : null,
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
            )
            ]

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

  void _filterSubTicketsIfNeeded(Map<String, dynamic> ticket, bool isAdmin, bool isAdminFromApi, int userId) {
    if (isAdmin && !isAdminFromApi) {
      final allSubs = ticket['sub_tickets'] ?? [];
      ticket['sub_tickets'] = allSubs.where((sub) => sub['assigned_to'] == userId).toList();
    }
  }

  Future<File> generateInvoicePDF({
    required String invoiceNumber,
    required String maintenanceType,
    required double amount,
    required DateTime receiptDate,
    required DateTime dueDate,
    required BuildContext context
  }) async
  {
    final pdf = pw.Document();

    final vatRate = 0.05;
    final vatAmount = amount * vatRate;
    final totalAmount = amount + vatAmount;

    final formattedReceiptDate = DateFormat('dd-MMM-yyyy').format(receiptDate);
    final formattedDueDate = DateFormat('dd-MMM-yyyy').format(dueDate);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "TAX INVOICE",
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),
                pw.Text("Invoice Number: $invoiceNumber"),
                pw.Text("Invoice Date: $formattedReceiptDate"),
                pw.Text("Due Date: $formattedDueDate"),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text("Sr No"),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text("Description"),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text("Amount (AED)"),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text("1"),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(maintenanceType),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(amount.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(""),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text("VAT (5%)"),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(vatAmount.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(""),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text("Total"),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(totalAmount.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text("Thank you for your business!",
                    style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          );
        },
      ),
    );


    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_$invoiceNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;


  }


  Future<void> fetchAllTickets() async {
    List<Map<String, dynamic>> allFormattedTickets = [];
    int page = 1;
    bool hasMore = true;

    setState(() {
      isLoading = true;
      isFetchingMore = false;
    });

    print('landlord hai ya nai -> $is_landlord');
    print('admin hai ya nai -> $is_admin');

    try {
      while (hasMore) {
        final url = is_admin
            ? "$baseurl/maintenance/ticket?page=$page"
            : is_landlord
            ? "$baseurl/maintenance/ticket/?landlord_id=$user_id&flat_id=$flat_id&page=$page"
            : "$baseurl/maintenance/ticket/?tenant_id=$user_id&flat_id=$flat_id&page=$page";

        final response = await http.get(Uri.parse(url), headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        });

        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);

          if (responseBody['success'] == true) {
            final rawTickets = responseBody['data']['tickets'] as List<dynamic>;
            List<dynamic> filteredTickets = [];

            if (is_admin && !is_admin_from_api) {
              for (var ticket in rawTickets) {
                final subtickets = ticket['sub_tickets'] ?? [];
                final assigned = subtickets.where((sub) => sub['assigned_to'] == user_id).toList();
                if (assigned.isNotEmpty) {
                  ticket['sub_tickets'] = assigned;
                  filteredTickets.add(ticket);
                }
              }
            } else {
              filteredTickets = rawTickets;
            }

            final formattedTickets = filteredTickets.map((ticket) {
              final subTickets = ticket['sub_tickets'] ?? [];

              // Handle rental flat
              Map<String, dynamic>? rental = ticket['rental_flat'];
              Map<String, dynamic>? sold = ticket['sold_flat'];

              final rentalFlat = rental?['flat'];
              final soldFlat = sold?['flat'];

              final rentalBuilding = rentalFlat?['building'];
              final soldBuilding = soldFlat?['building'];

              final rentalState = rentalBuilding?['area']?['state'];
              final soldState = soldBuilding?['area']?['state'];

              final status = () {
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
                  if (followUps.first['status']['category'] != "Close") {
                    allClosed = false;
                  }
                }

                if (allFollowupsMissing) return "Pending";
                return allClosed ? "Close" : "Normal";
              }();

              return {
                'ticketNumber': ticket['id'].toString(),
                'availableFrom': ticket['available_from'] ?? '',
                'availableTo': ticket['available_to'] ?? '',
                'sub_tickets': subTickets,
                'status': status,
                'date': ticket['created_at']?.split('T')[0] ?? '',

                // Rental data
                'unitNumber_rental': rentalFlat?['name'] ?? '',
                'buildingName_rental': rentalBuilding?['name'] ?? '',
                'emirate_rental': rentalState?['name'] ?? '',

                // Sold data
                'unitNumber_sold': soldFlat?['name'] ?? '',
                'buildingName_sold': soldBuilding?['name'] ?? '',
                'emirate_sold': soldState?['name'] ?? '',

                'maintenanceTypesAll': subTickets.map((sub) {
                  final type = sub['type'];
                  return {
                    'subTicketId': sub['id'].toString(),
                    'type': type['name'],
                    'category': type['category'] ?? 'N/A',
                    'followps': sub['followps'] ?? [],
                  };
                }).toList(),

                'maintenanceTypesFiltered': subTickets.where((sub) {
                  final followUps = sub['followps'] as List<dynamic>;
                  if (followUps.isEmpty) return true;
                  return followUps.first['status']['category'] != 'Close';
                }).map((sub) {
                  final type = sub['type'];
                  return {
                    'subTicketId': sub['id'].toString(),
                    'type': type['name'],
                    'category': type['category'] ?? 'N/A',
                  };
                }).toList(),

                'description': subTickets.map((sub) {
                  final typeName = sub['type']?['name'] ?? 'Unknown';
                  final desc = sub['description'] ?? 'No description';
                  return '• $typeName: $desc';
                }).join('\n'),
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
          print("HTTP Error ${response.statusCode}: ${response.body}");
        }
      }

      setState(() {
        tickets = allFormattedTickets;
        filterTickets(); // Optional
      });
    } catch (e) {
      print("Exception in fetchAllTickets: $e");
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
        final searchLower = searchQuery.toLowerCase();

        bool hasMatchingSubTicket = ticket['maintenanceTypesAll'] is List &&
            (ticket['maintenanceTypesAll'] as List).any((subTicket) =>
            subTicket is Map &&
                subTicket.containsKey('type') &&
                subTicket['type'] is String &&
                subTicket['type'].toLowerCase().contains(searchLower));

        bool unitMatch = (ticket['unitNumber_rental'] ?? '').toLowerCase().contains(searchLower) ||
            (ticket['unitNumber_sold'] ?? '').toLowerCase().contains(searchLower);

        bool buildingMatch = (ticket['buildingName_rental'] ?? '').toLowerCase().contains(searchLower) ||
            (ticket['buildingName_sold'] ?? '').toLowerCase().contains(searchLower);

        bool emirateMatch = (ticket['emirate_rental'] ?? '').toLowerCase().contains(searchLower) ||
            (ticket['emirate_sold'] ?? '').toLowerCase().contains(searchLower);

        return (ticket['ticketNumber'] ?? '').toLowerCase().contains(searchLower) ||
            unitMatch ||
            buildingMatch ||
            emirateMatch ||
            (ticket['status'] ?? '').toLowerCase().contains(searchLower) ||
            hasMatchingSubTicket;
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

  String _getTicketLocation(Map ticket) {
    final unit = ticket['unitNumber_rental']?.isNotEmpty == true
        ? ticket['unitNumber_rental']
        : ticket['unitNumber_sold'] ?? 'Unit';

    final building = ticket['buildingName_rental']?.isNotEmpty == true
        ? ticket['buildingName_rental']
        : ticket['buildingName_sold'] ?? 'Building';

    return "$unit - $building";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
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

            if(hasPermission('canViewMaintenanceTickets'))...[
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
              ))
                  : filteredTickets.isEmpty
                  ?  Expanded(
                  child:  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // center inside column
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No data available",
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
            ]
            else...[
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
                        "You don’t have permission to view maintenance tickets.",
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ]


          ],

        ),
      ),
    floatingActionButton: hasPermission('canCreateMaintenanceTicket') ? Container(
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
      ) : null

    );
  }


  Future<void> saveInvoice({
    required String ticketId,
    required String subTicketId,
    required String amount,
    required DateTime receiptDate,
    required String maintenanceType,
    required BuildContext parentContext,
    DateTime? dueDate,
  }) async
  {
    // Validation
    if (subTicketId.isEmpty) {
      Fluttertoast.showToast(msg: "Please select a maintenance type!");
      return;
    }
    if (amount.trim().isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) {
      Fluttertoast.showToast(msg: "Please enter a valid positive amount!");
      return;
    }
    if (receiptDate == null) {
      Fluttertoast.showToast(msg: "Please select a receipt date!");
      return;
    }
    if (dueDate != null && dueDate.isBefore(receiptDate)) {
      Fluttertoast.showToast(msg: "Due date must be after receipt date!");
      return;
    }

    final String url = "$baseurl/maintenance/invoices";
    String uuid = Uuid().v4();

    final Map<String, dynamic> requestBody = {
      "uuid": uuid,
      "sub_ticket_id": int.tryParse(subTicketId) ?? subTicketId,
      "amount": double.parse(amount),
      "date": receiptDate.toIso8601String().split('T')[0],
    };

    if (dueDate != null) {
      requestBody["due_date"] = dueDate.toIso8601String().split('T')[0];
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Company_Token",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
       /* Fluttertoast.showToast(
          msg: responseBody['message'] ?? "Invoice saved successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );*/


        final invoice = responseBody['data']['invoice'];

        // ✅ Don't pop the bottom sheet yet
        final action = await showGeneralDialog<String>(
          context: parentContext,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.5),
          transitionDuration: Duration(milliseconds: 300),
          pageBuilder: (context, anim1, anim2) {
            return Center(
              child: _buildInvoiceDialogContent(context),
            );
          },
          transitionBuilder: (context, anim1, anim2, child) {
            return FadeTransition(
              opacity: anim1,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            );
          },
        );




        // ✅ Handle action
        if (action == 'download' || action == 'print' || action == 'share') {
          showDialog(
            context: parentContext,
            barrierDismissible: false,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
                      strokeWidth: 3.5,
                    ),
                    SizedBox(width: 16),
                    Text("Preparing invoice...", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          );

          final file = await generateInvoicePDF(
              invoiceNumber: invoice['id'].toString(),
              maintenanceType: invoice['sub_ticket']['type']['name'] ?? 'N/A',
              amount: double.parse(invoice['amount'].toString()),
              receiptDate: DateTime.parse(invoice['date']),
              dueDate: dueDate ?? DateTime.parse(invoice['date']),
              context: parentContext
          );

          Navigator.of(parentContext, rootNavigator: true).pop(); // Close loader

          if (action == 'download' || action == 'print') {
            await Printing.layoutPdf(onLayout: (_) => file.readAsBytesSync());
          } else if (action == 'share') {
            await Share.shareXFiles([XFile(file.path)], text: "Here is your tax invoice.");
          }


          // ✅ Now close the bottom sheet
          Navigator.of(parentContext).pop();
        } else if (action == 'no') {
          // ✅ Just close the bottom sheet
          Navigator.of(parentContext).pop();
        }

      } else {
        final errorBody = jsonDecode(response.body);
        Fluttertoast.showToast(
          msg: errorBody['message'] ?? "Error: ${response.statusCode}",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Something went wrong: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }


  void _showCreateInvoicePopup(BuildContext screenContext, Map<String, dynamic> ticket) {
    final nonClosedTypes = ticket['maintenanceTypesFiltered'] ?? [];
    final TextEditingController amountController = TextEditingController();
    DateTime? receiptDate;
    DateTime? dueDate;
    String? selectedSubTicketId;
    String? selectedMaintenanceType;

    bool isSubmitting = false;


    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.white, // ✅ This sets the modal sheet background to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: appbar_color),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Create Invoice",
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);


                            }
                            )
                      ],
                    ),
                    Divider(),

                    Theme(
                      data: Theme.of(context).copyWith(
                        // Don't set primaryColor here! That affects text color.
                        colorScheme: ColorScheme.light(
                          primary: appbar_color, // For focus border, button etc
                          onPrimary: Colors.white,
                          onSurface: Colors.black, // Default text color
                        ),
                        hoverColor: appbar_color.withOpacity(0.1),
                        highlightColor: Colors.transparent, // ✅ Prevent over-corner highlight
                        splashColor: Colors.transparent,    // ✅ Prevent ripple beyond corner
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedSubTicketId,
                        decoration: InputDecoration(
                          labelText: "Select Maintenance Type",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        icon: Icon(Icons.keyboard_arrow_down, color: appbar_color),
                        style: GoogleFonts.poppins(color: Colors.black87), // ✅ Forces text color to black
                        dropdownColor: Colors.white,
                        items: nonClosedTypes.map<DropdownMenuItem<String>>((type) {
                          return DropdownMenuItem<String>(
                            value: type['subTicketId'].toString(),
                            child: Text(
                              type['type'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                color: Colors.black87, // ✅ Selected + unselected always black/grey
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSubTicketId = value;
                            final selectedType = nonClosedTypes.firstWhere(
                                  (type) => type['subTicketId'].toString() == value,
                              orElse: () => null,
                            );
                            selectedMaintenanceType = selectedType?['type'] ?? '';
                            print('sub ticket -> $selectedSubTicketId, maintenance type -> $selectedMaintenanceType');
                          });
                        },

                      ),
                    ),


                    SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      cursorColor: appbar_color,
                      style: GoogleFonts.poppins(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Amount",
                        labelStyle: GoogleFonts.poppins(color: Colors.grey),
                        prefixText: "AED ",
                        prefixStyle: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: appbar_color),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: appbar_color, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),



                    SizedBox(height: 12),

                    _buildDateField(
                      context,
                      label: "Receipt Date",
                      date: receiptDate,
                      onPick: (picked) => setState(() => receiptDate = picked),
                    ),

                    SizedBox(height: 12),

                    _buildDateField(
                      context,
                      label: "Due Date",
                      date: dueDate,
                      onPick: (picked) => setState(() => dueDate = picked),
                    ),

                    SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.clear, color: Colors.white),
                            label: Text("Clear", style: GoogleFonts.poppins(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedSubTicketId = null;
                                amountController.clear();
                                receiptDate = null;
                                dueDate = null;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: isSubmitting
                                ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Icon(Icons.check_circle, color: Colors.white),
                            label: Text(
                              isSubmitting ? "Creating..." : "Create Invoice",
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appbar_color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                              // Validate inputs first
                              if (selectedSubTicketId == null || selectedSubTicketId!.isEmpty) {
                                Fluttertoast.showToast(msg: "Please select a maintenance type!");
                                return;
                              }
                              if (amountController.text.trim().isEmpty ||
                                  double.tryParse(amountController.text.trim()) == null ||
                                  double.parse(amountController.text.trim()) <= 0) {
                                Fluttertoast.showToast(msg: "Please enter a valid positive amount!");
                                return;
                              }
                              if (receiptDate == null) {
                                Fluttertoast.showToast(msg: "Please select a receipt date!");
                                return;
                              }
                              if (dueDate != null && dueDate!.isBefore(receiptDate!)) {
                                Fluttertoast.showToast(msg: "Due date must be after receipt date!");
                                return;
                              }


                              await saveInvoice(
                                ticketId: ticket['ticketNumber'],
                                subTicketId: selectedSubTicketId!,
                                maintenanceType: selectedMaintenanceType ?? "",
                                amount: amountController.text.trim(),
                                receiptDate: receiptDate!,
                                dueDate: dueDate,
                                parentContext: context
                              );

                              setState(() => isSubmitting = false);
                            },


                          ),
                        )

                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateField(BuildContext context,
      {required String label, required DateTime? date, required Function(DateTime) onPick}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: appbar_color,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: appbar_color),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                date != null
                    ? "$label: ${DateFormat('dd-MMM-yyyy').format(date)}"
                    : "Select $label",
                style: GoogleFonts.poppins(
                  color: date != null ? Colors.black87 : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDialogContent(BuildContext dialogContext) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(dialogContext).size.width * 0.85,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated success icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green.shade600,
                          size: 64,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Text(
                  "Invoice Ready",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Your invoice has been generated",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Column(
                  children: [
                    _modernActionButton(
                      icon: Icons.download,
                      label: "Download",
                      onPressed: () => Navigator.pop(dialogContext, 'download'),
                      color: Colors.blueAccent,
                    ),
                    SizedBox(height: 10),
                    _modernActionButton(
                      icon: Icons.print,
                      label: "Print",
                      onPressed: () => Navigator.pop(dialogContext, 'print'),
                      color: Colors.indigoAccent,
                    ),
                    SizedBox(height: 10),
                    _modernActionButton(
                      icon: Icons.share,
                      label: "Share",
                      onPressed: () => Navigator.pop(dialogContext, 'share'),
                      color: Colors.teal,
                    ),
                    SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, 'no'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "No,Thanks",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _modernActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 48),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
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
                      if(hasPermission('canFollowUpTicket'))...[
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
                      ],

                    if (is_admin && ticket['status'] != 'Close') ...[
                      _buildDecentButton(
                        'Create Invoice',
                        Icons.receipt_long,
                        Colors.purple,
                            () {
                          _showCreateInvoicePopup(context, ticket);
                        },
                      ),
                      SizedBox(width: 5),
                    ],

                    
                      if (ticket['status'] == 'Close' && is_admin) ...[
                      if(hasPermission('canCreateTicketComment') || hasPermission('canViewTicketComment'))...[
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
                        ]

                      ] else if (ticket['status'] != 'Close') ...[
                      if(hasPermission('canCreateTicketComment') || hasPermission('canViewTicketComment'))...[
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
                        ]
                      ],

                    
                    if(hasPermission('canViewTicketComplaint'))...[
                      _buildDecentButton(
                        'Complaint',
                        Icons.report_problem_outlined,
                        Colors.redAccent,
                            () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => ComplaintBottomSheet(ticketId: ticket['ticketNumber']),
                          );

                        },
                      ),
                      SizedBox(width: 5),
                    ],




                    if (!is_admin)...[
                      if(ticket['status']=='Close')...[

                        _buildDecentButton(
                          'Feedback',
                          Icons.feedback,
                          Colors.blue,
                              () {
                            _showFeedbackDialog(int.parse(ticket['ticketNumber'])); // Existing Feedback Section
                          },
                        ),
                      ]

                    ],

                    if (is_admin)...[
                      if(ticket['status']=='Close')...[
                      if(hasPermission('canViewTicketFeedback'))...[
                        _buildDecentButton(
                          'Feedback',
                          Icons.feedback,
                          Colors.blue,
                              () {
                            _showViewFeedbackPopup(context, ticket['ticketNumber']); // Admin View Feedback
                          },
                        ),
                      ]
                      ]
                    ]
                  ],
                ),
                SizedBox(height: 10,),
                // Subtickets list (Each with only "Transfer" button)
            if(is_admin && ticket['status']!='Close')...[
              if(hasPermission('canTransferSubTicketJob'))...[


                Column(
                  children: ticket['maintenanceTypesFiltered'].map<Widget>((subTicket) {

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

              ]
            ]

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
    return Column(
      children: [
      Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Row(
          children: [
            Icon(Icons.confirmation_number, color: Colors.teal, size: 24.0),
            SizedBox(width: 8.0),
            Text(
              "MT-${ticket['ticketNumber']}",
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        _getStatusBadge(ticket['status'] ?? "Pending"),
      ],
    ),





      ],
    );
  }

  Widget _buildTicketDetails(Map<String, dynamic> ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        if (ticket['availableFrom'] != null && ticket['availableFrom'].toString().isNotEmpty &&
            ticket['availableTo'] != null && ticket['availableTo'].toString().isNotEmpty && is_admin)...[
              if(hasPermission('canViewAvailability'))...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableFrom = DateFormat('dd-MMM-yyyy hh:mm a')
                          .format(DateTime.parse(ticket['availableFrom']).toLocal());

                      final availableTo = DateFormat('dd-MMM-yyyy hh:mm a')
                          .format(DateTime.parse(ticket['availableTo']).toLocal());
                      final combinedText = '$availableFrom → $availableTo';
                      final fitsInline = combinedText.length < (constraints.maxWidth / 7);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Text('Availability',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),),
                            SizedBox(height: 3),


                            Row(

                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.access_time_rounded, size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: fitsInline
                                        ? [
                                      Text(
                                        combinedText,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ]
                                        : [
                                      Text(
                                        availableFrom,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Text(
                                        '→ $availableTo',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      );
                    },
                  ),
                ),
              ]
        ],


        _buildInfoRow('Unit:', ticket['unitNumber_rental'].isNotEmpty
            ? ticket['unitNumber_rental']
            : ticket['unitNumber_sold']),
        _buildInfoRow(
          'Building:',
          '${ticket['buildingName_rental']?.isNotEmpty == true ? ticket['buildingName_rental'] : ticket['buildingName_sold'] ?? 'N/A'}, '
              '${ticket['emirate_rental']?.isNotEmpty == true ? ticket['emirate_rental'] : ticket['emirate_sold'] ?? 'N/A'}',
        ),
       /* _buildInfoRow('Emirate:', ticket['emirate']),*/
    if (ticket['maintenanceTypesAll'] != null && ticket['maintenanceTypesAll'].isNotEmpty)
      _buildInfoRow_subtype(
        'Type:',
        (ticket['maintenanceTypesAll'] as List).cast<Map<String, dynamic>>(),
      ),



    _buildInfoRow('Submitted On:', DateFormat('dd-MMM-yyyy').format(DateTime.parse(ticket['date']))),




      ],
    );
  }

  Widget buildSubticketDescriptions(List<dynamic> subtickets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descriptions:',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        ...subtickets.map((sub) {
          final type = sub['type']?['name'] ?? 'Unknown';
          final desc = sub['description'] ?? 'No description';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
                      children: [
                        TextSpan(
                          text: '$type: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: desc),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ Align text top-to-top
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

  Widget _buildInfoRow_subtype(String label, List<Map<String, dynamic>> subtickets) {
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subtickets.map<Widget>((subTicket) {
                bool isClosed = false;
                if (subTicket['followps'] != null &&
                    subTicket['followps'] is List &&
                    subTicket['followps'].isNotEmpty) {
                  final firstFollowUp = subTicket['followps'][0];
                  isClosed = firstFollowUp['status']['category'] == 'Close';
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isClosed ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),

                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      if (isClosed)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child:
                          Icon(Icons.check_circle, color:Colors.green, size: 14),
                        ),
                      if (!isClosed)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child:
                          Icon(Icons.access_time, color:Colors.orange, size: 14),
                        ),
                      Text(
                        subTicket['type'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isClosed ? Colors.green : Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    ],
                  ),
                );
              }).toList(),
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
      case 'Drop':
        label = 'Drop';
        color = Colors.redAccent;
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
          buildSubticketDescriptions(ticket['sub_tickets'] ?? []),
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

class ComplaintBottomSheet extends StatefulWidget {
  final String ticketId;

  const ComplaintBottomSheet({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<ComplaintBottomSheet> createState() => _ComplaintBottomSheetState();
}

class _ComplaintBottomSheetState extends State<ComplaintBottomSheet> {
  List<dynamic> complaintList = [];
  bool isLoading = true;
  bool isSubmitting = false;
  List<dynamic> complaintStatuses = [];
  dynamic selectedStatus;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchComplaintHistoryAndStatus();
  }


  Future<void> _fetchComplaintHistoryAndStatus() async {
    final token = Company_Token;
    await Future.wait([
      _fetchComplaintHistory(token),
      _fetchComplaintStatuses(token),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchComplaintHistory(String token) async {
    int currentPage = 1;
    bool hasMore = true;
    List<dynamic> allComplaints = [];

    while (hasMore) {
      final response = await http.get(
        Uri.parse('$baseurl/maintenance/complaint/?ticket_id=${widget.ticketId}&page=$currentPage'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> complaints = json['data']['complaints'] ?? [];

        print('status list ->${complaintStatuses}');

        if (complaints.isEmpty) {
          hasMore = false;
        } else {
          allComplaints.addAll(complaints);
          currentPage++;
        }
      } else {
        print('code -> ${response.statusCode} \n\n body -> ${response.body}');
        hasMore = false;
      }
    }

    setState(() {
      complaintList = allComplaints.reversed.toList(); // Latest first
    });
  }

  Future<void> _fetchComplaintStatuses(String token) async {
    int currentPage = 1;
    bool hasMore = true;
    List<dynamic> allStatuses = [];

    while (hasMore) {
      final response = await http.get(
        Uri.parse('$baseurl/tenant/complaintStatus/?page=$currentPage'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> statuses = json['data']['complaintStatus'] ?? [];

        if (statuses.isEmpty) {
          hasMore = false;
        } else {
          allStatuses.addAll(statuses);
          currentPage++;
        }
      } else {
        print('code -> ${response.statusCode} \n\n body -> ${response.body}');
        hasMore = false;
      }
    }

    // Set selectedStatus to first Normal category
    final normalStatus = allStatuses.firstWhere(
          (status) => (status['category']?.toString().toLowerCase() ?? '') == 'normal',
      orElse: () => null,
    );

    if (normalStatus != null) {
      selectedStatus = normalStatus;
    }

    setState(() {
      complaintStatuses = allStatuses;
    });
  }

  // old complaint history function
  /*Future<void> _fetchComplaintHistory() async {
    final token = Company_Token;
    int currentPage = 1;
    bool hasMore = true;
    List<dynamic> allComplaints = [];

    while (hasMore) {
      final response = await http.get(
        Uri.parse('$baseurl/maintenance/complaint/?ticket_id=${widget.ticketId}&page=$currentPage'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> complaints = json['data']['complaints'] ?? [];

        if (complaints.isEmpty) {
          hasMore = false;
        } else {
          allComplaints.addAll(complaints);
          currentPage++;
        }
      } else {
        hasMore = false;
      }
    }

    setState(() {
      complaintList = allComplaints.reversed.toList(); // Latest first
      isLoading = false;
    });

  }*/

  Future<void> _submitComplaint() async {
    final description = _controller.text.trim();
    if (description.isEmpty) return;

    setState(() => isSubmitting = true);
    final token = Company_Token;

    print('status id -> ${selectedStatus['id']}');

    final response = await http.post(
      Uri.parse('$baseurl/maintenance/complaint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "ticket_id": widget.ticketId,
        'status_id' : selectedStatus['id'],
        "description": description,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201)
    {
      _controller.clear();
      await _fetchComplaintHistoryAndStatus(); // Refresh the list
    }
    else
    {
        print('error in creating complaint');
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = !isLoading && complaintList.isEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
      ),
      child: isEmpty
          ? LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.minHeight,
              ),
              child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.chat_rounded, color: appbar_color),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Complaints",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Divider(),



                      // Empty State
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                            SizedBox(height: 12),
                            Text("No complaints yet", style: GoogleFonts.poppins(color: Colors.grey)),
                          ],
                        ),
                      ),

                      if(!is_admin)...[
                        Divider(height: 24),

                        // Input
                        _buildInputField(),

                        SizedBox(height: 12),
                        _buildSubmitButton(),
                        SizedBox(height: 8),
                      ]

                    ],
                  )
              ),
            ),
          );
        },
      )

          : LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.minHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.chat_rounded, color: appbar_color),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Complaints",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(),

                    // Complaint List
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator.adaptive()),
                      )
                    else
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: ListView.separated(
                          itemCount: complaintList.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = complaintList[index];
                            return Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.comment_bank_rounded, color: appbar_color),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['description'] ?? '',
                                            style: GoogleFonts.poppins(fontSize: 14)),
                                        SizedBox(height: 6),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: appbar_color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            DateFormat('dd-MMM-yyyy hh:mm a').format(
                                              DateTime.parse(item['created_at'].toString()).toLocal(),
                                            ),
                                            style: TextStyle(fontSize: 12, color: appbar_color),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    if(!is_admin)...[
                      Divider(height: 24),

                      // Input + Button
                      _buildInputField(),
                      SizedBox(height: 12),
                      _buildSubmitButton(),
                      SizedBox(height: 8),
                    ]


                  ],
                ),

              ),
            ),
          );
        },
      )
    );
  }
  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
        color: Colors.white,
      ),
      child: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 100,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: Icon(Icons.mode_comment_outlined, color: appbar_color),
          hintText: "Type your complaint here...",
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.send_rounded, color: Colors.white),
        label: isSubmitting
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text("Submit", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        onPressed: isSubmitting ? null : _submitComplaint,
        style: ElevatedButton.styleFrom(
          backgroundColor: appbar_color,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );

  }




}


