import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'SalesInquiryReport.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FollowUpStatus {
  final int id;
  final String name;
  final String category;

  FollowUpStatus({
    required this.id,
    required this.name,
    required this.category,
  });

  // Factory method to create a FollowUpStatus object from JSON
  factory FollowUpStatus.fromJson(Map<String, dynamic> json) {
    return FollowUpStatus(
      id: json['id'],
      name: json['name'],
      category: json['category'],  // Convert to bool
    );
  }
}

class FollowUpType {
  final int id;
  final String name;
  final int company_id;

  FollowUpType({
    required this.id,
    required this.name,
    required this.company_id
  });

  // Factory method to create a FollowUpStatus object from JSON
  factory FollowUpType.fromJson(Map<String, dynamic> json) {
    return FollowUpType(
      id: json['id'],
      name: json['name'],
        company_id:json['company_id']
    );
  }
}


class ActivitySource {
  final int id;
  final String name;

  ActivitySource({
    required this.id,
    required this.name,
  });

  // Factory method to create a FollowUpStatus object from JSON
  factory ActivitySource.fromJson(Map<String, dynamic> json) {
    return ActivitySource(
      id: json['id'],
      name: json['name'],
    );
  }
}

class FollowupSalesInquiry extends StatefulWidget {

  final String name;
  final List<String> unittype;
  final List<String> existingAreaList;
  final List<String> existingEmirateList;
  final String contactno;
  final String email;
  final String id;

  const FollowupSalesInquiry({
    Key? key,
    required this.name,
    required this.unittype,
    required this.existingAreaList,
    required this.existingEmirateList,
    required this.contactno,
    required this.email,
    required this.id,


  }) : super(key: key);
  @override
  State<FollowupSalesInquiry> createState() => _FollowupSaleInquiryPageState();
}

class _FollowupSaleInquiryPageState extends State<FollowupSalesInquiry> {

  final _formKey = GlobalKey<FormState>();

  // text editing controllers intialization
  final customernamecontroller = TextEditingController();
  final customercontactnocontroller = TextEditingController();
  final unittypecontroller = TextEditingController();
  final emiratescontroller = TextEditingController();
  final areacontroller = TextEditingController();
  final remarksController = TextEditingController();
  final emailcontroller = TextEditingController();

  // focus nodes initialization
  final customernameFocusNode = FocusNode();
  final customercontactnoFocusNode = FocusNode();
  final unittypeFocusNode = FocusNode();
  final areaFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();

  DateTime? nextFollowUpDate;

  bool isUnitSelected = false;

  List<Map<String, dynamic>>? filteredEmirates;
  List<Map<String, dynamic>>? filteredAreas;

  SharedPreferences? prefs;

  bool isAllUnitsSelected = false;

  bool isEmirateSelected = false;

  bool isAreasSelected = false;

  bool isAllEmiratesSelected = false;

  bool isAllAreasSelected = false;

  String? selectedEmirate;

  bool _isFocused_email = false,_isFocus_name = false;

  bool _isLoading = false;

  double? range_min, range_max;

  FollowUpStatus? selectedfollowup_status;

  FollowUpType? selectedfollowup_type;

  ActivitySource? selectedactivity_source;

  final TextEditingController startController = TextEditingController();

  final TextEditingController endController = TextEditingController();


  String selectedEmiratesString = "Select Emirate";

  final List<String> interestTypes = ["Rent", "Buy"]; // List of options

  int? selectedInterestType;

  final List<String> propertyType = [
    'Residential',
    'Commercial',
  ];

  List<int> selectedUnitIds = [];

  RangeValues? _currentRangeValues;

  List<ActivitySource> activitysource_list = [];

  final List<Map<String, dynamic>> specialfeatures = [];

  final List<Map<String, dynamic>> amenities = [];

   Set<int> selectedSpecialFeatures = {};

   Set<int> selectedAmenities = {};

  String _hintText = 'Enter Contact No'; // Default hint text

  void _sendEmail(String recipientEmail, String subject, String body) async {
    final String username = "your-email@example.com"; // Your email
    final String password = "your-email-password"; // Your email password

    final smtpServer = gmail(username, password); // Use Gmail SMTP Server

    final message = Message()
      ..from = Address(username, "Your Name")
      ..recipients.add(recipientEmail) // Recipient Email
      ..subject = subject
      ..text = body; // Email Body

    try {
      final sendReport = await send(message, smtpServer);
      print("Email Sent: ${sendReport.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email sent successfully!")),
      );
    } catch (e) {
      print("Email Sending Failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send email")),
      );
    }
  }

  /*void _preSelectEmiratesAndAreas() {
    // Assume that selectedEmiratesList contains a list of selected emirates
    List<String> preSelectedEmirates = widget.existingEmirateList; // Example selected emirates
    List<String> preSelectedAreasList = widget.existingAreaList; // This will hold the areas in "Area - Emirate" format

    setState(() {
      // Loop through each emirate
      for (var emirate in emirates) {
        if (preSelectedEmirates.contains(emirate['label'])) {
          emirate['isSelected'] = true; // Mark as selected
          selectedEmiratesList.add(emirate['label']);

          // Only preselect the areas that are in preSelectedAreasList for this emirate
          List<Map<String, dynamic>> areasInEmirate = areas[emirate['label']] ?? [];
          for (var area in areasInEmirate) {
            // If the area is in the preSelectedAreasList, mark it as selected
            if (preSelectedAreasList.contains(area['label'])) {
              area['isSelected'] = true;
              selectedAreas.add('${area['label']} - ${emirate['label']}'); // Add area with emirate to selectedAreas list
            }
          }
        }
      }

      // Update the selected emirates and areas strings
      selectedEmirates = selectedEmiratesList.join(', '); // Update selected emirates string
      selectedAreasString = selectedAreas.join(', '); // Update selected areas string
    });
  }*/

  List<Map<String, dynamic>> emirates = [
    {"label": "Abu Dhabi", "isSelected": false},
    {"label": "Dubai", "isSelected": false},
    {"label": "Sharjah", "isSelected": false},
    {"label": "Ajman", "isSelected": false},
    {"label": "Umm Al Quwain", "isSelected": false},
    {"label": "Ras Al Khaimah", "isSelected": false},
    {"label": "Fujairah", "isSelected": false},
  ];

  List<FollowUpStatus> followupstatus_list = [];

  List<FollowUpType> followuptype_list = [];

  String? selectedPropertyType;

  List<Map<String, dynamic>> unitTypes = [];

  Map<String, List<Map<String, dynamic>>> areas = {};

  String selectedUnitType = "Select Unit Types";
  String selectedEmirates = "Select Emirate";
  String selectedAreasString = "Select Area";
  List<Map<String, dynamic>> selectedEmiratesList = []; // Store objects with 'id' and 'label'
  List<Map<String, dynamic>> selectedAreas = []; // Store objects with 'id' and 'label'

  List<Map<String, dynamic>> areasToDisplay = []; // Global variable

  void _showEmailPopup(Function updateMainState) {
    TextEditingController subjectController = TextEditingController();
    TextEditingController bodyController = TextEditingController();
    String buttonText = "Select Next Follow-up Date";

    bool isSubjectEmpty = false;
    bool isBodyEmpty = false;
    bool isFollowUpTypeEmpty = false;
    bool isFollowUpStatusEmpty = false;
    bool isFollowUpDateEmpty = false;
    bool isRemarksEmpty = false;

    if (nextFollowUpDate != null) {
      setState(() {
        buttonText = 'Next Follow-up: ${DateFormat("dd-MMM-yyyy").format(nextFollowUpDate!)}';
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                "Send Email",
                style: TextStyle(color: Colors.black),
              ),
              content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Input for Subject
                      TextField(
                        controller: subjectController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "Subject",
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: isSubjectEmpty ? Colors.red : Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isSubjectEmpty ? Colors.red : appbar_color),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          errorText: isSubjectEmpty ? "Subject is required" : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            isSubjectEmpty = value.trim().isEmpty;
                          });
                        },
                      ),
                      SizedBox(height: 10),

                      // Input for Body
                      TextField(
                        controller: bodyController,
                        maxLines: 3,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "Message Body",
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: isBodyEmpty ? Colors.red : Colors.black),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isBodyEmpty ? Colors.red : appbar_color),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          errorText: isBodyEmpty ? "Message body is required" : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            isBodyEmpty = value.trim().isEmpty;
                          });
                        },
                      ),
                      SizedBox(height: 10),

                      // Follow-up Type Dropdown
                      DropdownButtonFormField<FollowUpType>(
                        value: selectedfollowup_type,
                        decoration: InputDecoration(
                          labelText: 'Follow-up Type*',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: isFollowUpTypeEmpty ? Colors.red : Colors.black54),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isFollowUpTypeEmpty ? Colors.red : appbar_color),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          errorText: isFollowUpTypeEmpty ? "Follow-up Type is required" : null,
                        ),
                        items: followuptype_list.map((FollowUpType status) {
                          return DropdownMenuItem<FollowUpType>(
                            value: status,
                            child: Text(status.name, style: TextStyle(color: Colors.black87)),
                          );
                        }).toList(),
                        onChanged: (FollowUpType? value) {
                          setState(() {
                            selectedfollowup_type = value;
                            isFollowUpTypeEmpty = value == null;
                            updateMainState();

                          });
                        },
                      ),
                      SizedBox(height: 10),

                      // Follow-up Status Dropdown
                      DropdownButtonFormField<FollowUpStatus>(
                        value: selectedfollowup_status,
                        decoration: InputDecoration(
                          labelText: 'Follow-up Status*',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: isFollowUpStatusEmpty ? Colors.red : Colors.black54),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isFollowUpStatusEmpty ? Colors.red : appbar_color),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          errorText: isFollowUpStatusEmpty ? "Follow-up Status is required" : null,
                        ),
                        items: followupstatus_list.map((FollowUpStatus status) {
                          return DropdownMenuItem<FollowUpStatus>(
                            value: status,
                            child: Text(status.name, style: TextStyle(color: Colors.black87)),
                          );
                        }).toList(),
                        onChanged: (FollowUpStatus? value) {
                          setState(() {
                            selectedfollowup_status = value;
                            if (selectedfollowup_status!.category != 'Normal') {
                              nextFollowUpDate = null;
                            }
                            isFollowUpStatusEmpty = value == null;
                            updateMainState();

                          });
                        },
                      ),

                      // Follow-up Date (only if status is "Normal")
                      if (selectedfollowup_status != null && selectedfollowup_status!.category == 'Normal')
                        Column(
                          children: [
                            SizedBox(height: 5),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appbar_color,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: nextFollowUpDate ?? DateTime.now().add(Duration(days: 1)),
                                  firstDate: DateTime.now().add(Duration(days: 1)), // Restrict past dates
                                  lastDate: DateTime(2100),
                                  builder: (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: appbar_color, // Header background and selected date color
                                          onPrimary: Colors.white, // Header text color
                                          onSurface: Colors.black, // Calendar text color
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: appbar_color, // Button text color
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (pickedDate != null) {
                                  setState(() {
                                    buttonText ='Next Follow-up: ${DateFormat("dd-MMM-yyyy").format(pickedDate!)}';
                                    nextFollowUpDate = pickedDate; // Save selected date
                                  });

                                  updateMainState();
                                }
                              },
                              child: Text(buttonText),
                            ),


                            if (isFollowUpDateEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Text("Follow-up Date is required", style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                            SizedBox(height: 5),

                          ],
                        ),

                      // Remarks
                      TextField(
                        controller: remarksController,
                        maxLines: 3,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "Remarks",
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: isRemarksEmpty ? Colors.red : Colors.black),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isRemarksEmpty ? Colors.red : appbar_color),
                            borderRadius: BorderRadius.circular(8),

                          ),
                          errorText: isRemarksEmpty ? "Remarks are required" : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            isRemarksEmpty = value.trim().isEmpty;
                          });
                        },
                      ),
                    ],
                  ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel", style: TextStyle(color: appbar_color)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isSubjectEmpty = subjectController.text.trim().isEmpty;
                      isBodyEmpty = bodyController.text.trim().isEmpty;
                      isFollowUpTypeEmpty = selectedfollowup_type == null;
                      isFollowUpStatusEmpty = selectedfollowup_status == null;
                      isFollowUpDateEmpty = selectedfollowup_status != null &&
                          selectedfollowup_status!.category == 'Normal' &&
                          nextFollowUpDate == null;
                      isRemarksEmpty = remarksController.text.trim().isEmpty;
                    });

                    if (!isSubjectEmpty && !isBodyEmpty && !isFollowUpTypeEmpty &&
                        !isFollowUpStatusEmpty && !isFollowUpDateEmpty && !isRemarksEmpty) {
                      updateMainState();

                      Navigator.of(context).pop();
                      sendFollowupInquiryRequest();
                    }
                  },
                  child: Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _showWhatsAppPopup(BuildContext context,Function updateMainState) {
    TextEditingController messageController = TextEditingController();
    String buttonText = "Select Next Follow-up Date";
    String phoneNumber = customercontactnocontroller.text.trim(); // Get number from TextField

    bool isFollowUpTypeEmpty = false;
    bool isFollowUpStatusEmpty = false;
    bool isFollowUpDateEmpty = false;
    bool isRemarksEmpty = false;
    bool isMessageEmpty = false;


    if (nextFollowUpDate != null) {
      setState(() {
        buttonText ='Next Follow-up: ${DateFormat("dd-MMM-yyyy").format(nextFollowUpDate!)}';
      });
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white, // Apply appbar_color to full
              title: Text(
                "WhatsApp",
                style: TextStyle(color: Colors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input field for the message


                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Message",
                      hintText: 'Enter your message',
                      labelStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: isMessageEmpty ? Colors.red : Colors.black),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isMessageEmpty ? Colors.red : appbar_color),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      errorText: isMessageEmpty ? "Message is required" : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isMessageEmpty = value.trim().isEmpty;
                      });
                    },
                  ),


                  SizedBox(height: 10),


                  // Follow-up Type Dropdown
                  DropdownButtonFormField<FollowUpType>(
                    value: selectedfollowup_type,
                    decoration: InputDecoration(
                      labelText: 'Follow-up Type*',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: isFollowUpTypeEmpty ? Colors.red : Colors.black54),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isFollowUpTypeEmpty ? Colors.red : appbar_color),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      errorText: isFollowUpTypeEmpty ? "Follow-up Type is required" : null,
                    ),
                    items: followuptype_list.map((FollowUpType status) {
                      return DropdownMenuItem<FollowUpType>(
                        value: status,
                        child: Text(status.name, style: TextStyle(color: Colors.black87)),
                      );
                    }).toList(),
                    onChanged: (FollowUpType? value) {
                      setState(() {
                        selectedfollowup_type = value;
                        isFollowUpTypeEmpty = value == null;
                        updateMainState();

                      });
                    },
                  ),
                  SizedBox(height: 10),

                  // Follow-up Status Dropdown
                  DropdownButtonFormField<FollowUpStatus>(
                    value: selectedfollowup_status,
                    decoration: InputDecoration(
                      labelText: 'Follow-up Status*',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: isFollowUpStatusEmpty ? Colors.red : Colors.black54),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isFollowUpStatusEmpty ? Colors.red : appbar_color),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      errorText: isFollowUpStatusEmpty ? "Follow-up Status is required" : null,
                    ),
                    items: followupstatus_list.map((FollowUpStatus status) {
                      return DropdownMenuItem<FollowUpStatus>(
                        value: status,
                        child: Text(status.name, style: TextStyle(color: Colors.black87)),
                      );
                    }).toList(),
                    onChanged: (FollowUpStatus? value) {
                      setState(() {
                        selectedfollowup_status = value;
                        if (selectedfollowup_status!.category != 'Normal') {
                          nextFollowUpDate = null;
                        }
                        isFollowUpStatusEmpty = value == null;
                        updateMainState();

                      });
                    },
                  ),

                  // Follow-up Date (only if status is "Normal")
                  if (selectedfollowup_status != null && selectedfollowup_status!.category == 'Normal')
                    Column(
                      children: [
                        SizedBox(height: 5),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appbar_color,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: nextFollowUpDate ?? DateTime.now().add(Duration(days: 1)),
                              firstDate: DateTime.now().add(Duration(days: 1)), // Restrict past dates
                              lastDate: DateTime(2100),
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: appbar_color, // Header background and selected date color
                                      onPrimary: Colors.white, // Header text color
                                      onSurface: Colors.black, // Calendar text color
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: appbar_color, // Button text color
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedDate != null) {
                              setState(() {
                                buttonText ='Next Follow-up: ${DateFormat("dd-MMM-yyyy").format(pickedDate!)}';
                                nextFollowUpDate = pickedDate; // Save selected date
                              });

                              updateMainState();
                            }
                          },
                          child: Text(buttonText),
                        ),
                        if (isFollowUpDateEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text("Follow-up Date is required", style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),

                      ],
                    ),
                  SizedBox(height: 10),

                  // Remarks
                  TextField(
                    controller: remarksController,
                    maxLines: 3,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Remarks",
                      labelStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: isRemarksEmpty ? Colors.red : Colors.black),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isRemarksEmpty ? Colors.red : appbar_color),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      errorText: isRemarksEmpty ? "Remarks are required" : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isRemarksEmpty = value.trim().isEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
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
                    String message = messageController.text;

                    setState(() {
                      isMessageEmpty = messageController.text.trim().isEmpty;
                      isFollowUpTypeEmpty = selectedfollowup_type == null;
                      isFollowUpStatusEmpty = selectedfollowup_status == null;
                      isFollowUpDateEmpty = selectedfollowup_status != null &&
                          selectedfollowup_status!.category == 'Normal' &&
                          nextFollowUpDate == null;
                      isRemarksEmpty = remarksController.text.trim().isEmpty;
                    });

                    if (!isMessageEmpty && !isFollowUpTypeEmpty &&
                        !isFollowUpStatusEmpty && !isFollowUpDateEmpty && !isRemarksEmpty) {
                      updateMainState();

                      sendFollowupInquiryRequest();

// Open WhatsApp
                      String whatsappUrl = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";

                      launch(whatsappUrl);

                      Navigator.of(context).pop();
                    }



                    if (message.isNotEmpty && nextFollowUpDate != null) {

                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Enter message & select a date!")),
                      );
                    }
                  },
                  child: Text("Send"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openEmail(String no) async {

    final String email = emailcontroller.text.trim();

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email, // Replace with the recipient's email
      queryParameters: {
        'subject': 'Inquiry Follow-up ($no)',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      print("Could not open email client");
    }
  }

  /*  void openWhatsApp() async {
    String phone = customercontactnocontroller.text.trim(); // Get number from TextField
    String message = Uri.encodeComponent("Hello"); // Encode message
    String url = "https://wa.me/$phone?text=$message"; // Construct WhatsApp URL

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("Could not open WhatsApp");
    }
  }*/

  Future<void> openCaller() async {

    final String phoneNumber = '${customercontactnocontroller.text}';

    final Uri phoneUri = Uri.parse("tel:$phoneNumber"); // Replace with a valid number
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  Future<void> sendFollowupInquiryRequest() async {

    // Replace with your API endpoint
    final String url = "$BASE_URL_config/v1/leadFollowUp";

    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();

    DateTime today = DateTime.now();

    // Format the date to yyyy-MM-dd
    String formattedDate = DateFormat('yyyy-MM-dd').format(today);

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    String? nextfollowupdate = '';
    if(nextFollowUpDate!=null)
      {
         nextfollowupdate = formatter.format(nextFollowUpDate!);
      }
    else
      {
        nextfollowupdate = null;
      }


    // Constructing the JSON body

    final Map<String, dynamic> requestBody = {
      "uuid": uuidValue,
      "lead_id":widget.id,
      "date":formattedDate, // today's date
      "status_id":selectedfollowup_status!.id,
      "next_followup_date": nextfollowupdate, // next follow up date
      "type_id":selectedfollowup_type!.id,
      "remarks" : remarksController.text
    };

    print('create request body $requestBody');

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
        // Request was successful
        print("Response Data: ${response.body}");
        setState(() {
          /*_formKey.currentState?.reset();
          nextFollowUpDate = null;
          selectedfollowup_status = null;
          selectedfollowup_type = null;
          remarksController.clear();*/

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SalesInquiryReport()),
          );
        });

      } else {
        // Error occurred
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");

      }
    } catch (error) {
      print("Exception: $error");
    }
  }

  void updateAreasDisplay() {
    areasToDisplay.clear();

    selectedEmiratesList.forEach((emirate) {
      areasToDisplay.addAll(areas[emirate['label']] ?? []);
    });

    // Reset areas not belonging to the selected emirates
    areas.forEach((emirate, areaList) {
      if (!selectedEmiratesList.any((e) => e['label'] == emirate)) {
        areaList.forEach((area) {
          area['isSelected'] = false;
        });
      }
    });

    // Update selectedAreasString based on updated areasToDisplay
    final selectedAreaLabels = areasToDisplay
        .where((area) => area['isSelected'])
        .map((area) => area['label'] as String)
        .toList();

    selectedAreasString = selectedAreaLabels.isEmpty ? "Select Area" : selectedAreaLabels.join(', ');
  }

  void loadAreasFromJson(dynamic jsonResponse) {
    try {
      final areasFromResponse = jsonResponse['data']?['areas'] as List<dynamic>? ?? [];

      areas.clear(); // Clear existing areas

      for (var area in areasFromResponse) {
        final emirateName = area['emirates']?['state_name'] ?? '';
        if (emirateName.isNotEmpty) {
          areas.putIfAbsent(emirateName, () => []); // Add emirate key if not already present
          areas[emirateName]!.add({
            "label": area['area_name'] ?? '',
            "id": area['cost_centre_masterid'] ?? '',
            "isSelected": false,
          });
        }
      }

      print("Areas loaded successfully: $areas");
    } catch (e) {
      print("Error loading areas: $e");
    }

  }

  void populateEmiratesList(dynamic jsonResponse) {
    try {
      // Safely extract the "emirates" list
      final emiratesFromResponse = jsonResponse['data']?['emirates'] as List<dynamic>?;

      if (emiratesFromResponse == null || emiratesFromResponse.isEmpty) {
        print("No emirates data found in the response.");
        return; // Exit if there's no data
      }

      // Map the "state_name" into the "emirates" list format
      emirates = emiratesFromResponse.map((emirate) {
        return {
          "label": emirate['state_name'] ?? '', // Fallback to empty string if state_name is null
          "id": emirate['cost_centre_masterid'] ?? '',
          "isSelected": false, // Default to not selected
        };
      }).toList();

      print('Emirates list populated successfully. Total Emirates: ${emirates.length}');
    } catch (e) {
      // Log the error for debugging
      print('Error populating Emirates list: $e');
    }
  }

  void fetchFlatTypes(dynamic jsonResponse) {
    final data = jsonResponse is String
        ? jsonDecode(jsonResponse)
        : jsonResponse;

    if (data != null && data['data'] != null && data['data']['flatTypes'] != null) {
      final flatTypes = data['data']['flatTypes'] as List<dynamic>;

      unitTypes = flatTypes
          .map((flat) => {
        'label': flat['flat_type'], // Flat type name
        'id': flat['cost_centre_masterid'], // ID value
        'isSelected': false, // Default selection state
      })
          .toList();
    } else {
      print('Error: Invalid data structure');
    }
  }

  Future<void> fetchEmirates() async {

    print('fetching emirates');

    emirates.clear();

    final url = '$BASE_URL_config/v1/masters/emirates'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {


        final data = jsonDecode(response.body);
        setState(() {
          populateEmiratesList(data);

        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }
  }

  Future<void> fetchAreas() async {

    print('fetching areas');

    areas.clear();

    final url = '$BASE_URL_config/v1/masters/areas'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        setState(() {
          loadAreasFromJson(data);

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

  void _updateRangeFromTextFields() {
    // Parse start and end values, defaulting to range_min and range_max if invalid
    double start = double.tryParse(startController.text) ?? range_min!;
    double end = double.tryParse(endController.text) ?? range_max!;

    // Constrain start and end to the min and max values
    start = start.clamp(range_min!, range_max!);
    end = end.clamp(range_min!, range_max!);

    // Ensure start value is less than or equal to end value
    if (start > end) {
      end = start;
    }

    setState(() {
      _currentRangeValues = RangeValues(start, end);
    });
  }

  Future<void> fetchUnitTypes() async {

    print('fetching unit types');
    unitTypes.clear();

    final url = '$BASE_URL_config/v1/masters/flatTypes'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {
          fetchFlatTypes(data);

        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }


  }

  Future<void> fetchActivitySources() async {

    activitysource_list.clear();

    final url = '$BASE_URL_config/v1/activitySources'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {
          List<dynamic> activitySourceList = data['data']['activitySources'];

          for (var status in activitySourceList) {
            // Create a FollowUpStatus object from JSON
            ActivitySource activitySource = ActivitySource.fromJson(status);

            // Add the object to the list
            activitysource_list.add(activitySource);


          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }


  }

  Future<void> fetchAmenities() async {

    amenities.clear();

    final url = '$BASE_URL_config/v1/amenities'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    print('fetch url $url');
    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {


        setState(() {

          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> amenitiesData = data['data']['amenities'];

          for (var item in amenitiesData) {
            if (item['is_special'] == "true") {
              specialfeatures.add(item);
            } else {
              amenities.add(item);
            }
          }
          setState(() {});

        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    };
  }

  Future<void> fetchLeadStatus() async {

    followupstatus_list.clear();

    final url = '$BASE_URL_config/v1/leadStatus'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {
          List<dynamic> leadStatusList = data['data']['leadStatus'];

          for (var status in leadStatusList) {
            // Create a FollowUpStatus object from JSON
            FollowUpStatus followUpStatus = FollowUpStatus.fromJson(status);

            // Add the object to the list
            followupstatus_list.add(followUpStatus);

            // Optionally, you can print the object for verification
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }


  }

  Future<void> fetchLeadType() async {

    followuptype_list.clear();

    final url = '$BASE_URL_config/v1/leadFollowUpTypes'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {
          List<dynamic> followuplist = data['data']['followUpTypes'];

          for (var followup in followuplist) {
            // Create a FollowUpStatus object from JSON
            FollowUpType followUpType = FollowUpType.fromJson(followup);

            // Add the object to the list
            followuptype_list.add(followUpType);


            // Optionally, you can print the object for verification
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }


  }

  void updateEmiratesSelection() {
    setState(() {
      // Check if all Emirates are selected
      isAllEmiratesSelected = emirates.every((emirate) => emirate['isSelected']);

      // Update the selected Emirates text field
      selectedEmiratesString = emirates
          .where((emirate) => emirate['isSelected'])
          .map((emirate) => emirate['label'])
          .join(', ') ?? "Select Emirate";
    });
  }

  void updateAreasSelection() {
    // Reset selected areas if no Emirates are selected
    if (emirates.every((emirate) => !emirate['isSelected'])) {
      selectedAreas.clear();
      selectedAreasString = "Select Area";
    } else {
      selectedAreasString = selectedAreas.isNotEmpty
          ? selectedAreas.join(', ')
          : "Select Area";
    }

    // Update areas visibility based on selected Emirates
    for (var emirate in emirates) {
      if (emirate['isSelected']) {
        String emirateName = emirate['label'];
        // Check if all areas are selected for this emirate
        isAllAreasSelected = areas[emirateName]?.every((area) => area['isSelected']) ?? false;
      }
    }
    setState(() {});
  }

  void updateSelectedAreasString(List<Map<String, dynamic>> filteredAreas)  {
    final selectedAreaLabels = filteredAreas
        .where((area) => area['isSelected'])
        .map((area) => area['label'] as String)
        .toList();

    selectedAreasString = selectedAreaLabels.isEmpty ? "Select Area" : selectedAreaLabels.join(', ');
  }

  void clearAreas() {
    areasToDisplay.clear(); // Reset areas to display
    for (var areaList in areas.values) {
      for (var area in areaList) {
        area['isSelected'] = false;
      }
    }
    selectedAreas.clear();
    selectedAreasString = "Select Area(s)";
  }

  void _openUnitTypeDropdown(BuildContext context) async {
    final selectedItems = await showModalBottomSheet<Map<String, List<dynamic>>>(
      context: context,
      isDismissible: false, // Prevent closing by tapping outside
      enableDrag: false,    // Prevent closing by dragging
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, dynamic>> filteredUnitTypes = List.from(unitTypes); // Make a copy of the original list

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "Unit Type(s)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        filteredUnitTypes = unitTypes
                            .where((unit) =>
                            unit['label']
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Unit Types',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color), // BlueGrey border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color), // BlueGrey focused border color
                      ),
                    ),
                  ),
                ),
                // Conditionally show Select All only if there is no search query
                if (searchController.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: CheckboxListTile(
                        title: Text("Select All",
                          style: TextStyle(color: Colors.black),
                        ),
                        activeColor: appbar_color,

                        value: isAllUnitsSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            isAllUnitsSelected = value ?? false;
                            // Update all unit types based on Select All
                            for (var unit in unitTypes) {
                              unit['isSelected'] = isAllUnitsSelected;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                SizedBox(height: 15),
                Expanded(
                  child: ListView(
                    children: filteredUnitTypes.map((unit) {
                      return CheckboxListTile(
                        title: Text(unit['label']),
                        activeColor: appbar_color,
                        value: unit['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            unit['isSelected'] = value!;
                            // If an individual unit is deselected, unselect 'Select All'
                            if (!unit['isSelected']) {
                              isAllUnitsSelected = false;
                            }
                            // If all units are selected, select 'Select All'
                            if (unitTypes.every((u) => u['isSelected'])) {
                              isAllUnitsSelected = true;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color, // Button background color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5), // Rounded corners
                        side: BorderSide(
                          color: Colors.grey, // Border color
                          width: 0.5, // Border width
                        ),
                      ),
                    ),
                    onPressed: () {
                      // Extract the IDs of all selected unit types
                      selectedUnitIds = unitTypes
                          .where((unit) => unit['isSelected'])
                          .map((unit) => unit['id'] as int)
                          .toList();

                      // Extract names of selected items
                      List<String> selectedNames = unitTypes
                          .where((unit) => unit['isSelected'])
                          .map((unit) => unit['label'] as String)
                          .toList();

                      if (selectedUnitIds.isEmpty) {
                        Navigator.of(context).pop(null); // Return null if no selection
                      } else {
                        // Return both IDs and names
                        Navigator.of(context).pop({'ids': selectedUnitIds, 'names': selectedNames});
                      }
                    },
                    child: Text('OK'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Update the selected items and set the background color
    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        selectedUnitType = selectedItems['names']!.join(', ');
        isUnitSelected = true;  // Mark as selected
      });
    } else {
      setState(() {
        selectedUnitType = "Select Unit Types";  // Reset if no selection
        isUnitSelected = false;  // Mark as not selected
      });
    }
  }

  void _openEmirateDropdown(BuildContext context) async {
    final selectedItems = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        filteredEmirates = List.from(emirates);
        isAllEmiratesSelected = filteredEmirates!.every((a) => a['isSelected']);

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "Emirate(s)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        filteredEmirates = emirates
                            .where((emirate) => emirate['label']
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Emirate(s)',
                      prefixIcon: Icon(Icons.search, color: appbar_color),
                      labelStyle: TextStyle(color: appbar_color),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color, width: 2.0),
                      ),
                    ),
                    cursorColor: appbar_color,
                  ),
                ),
                CheckboxListTile(
                  title: Text("Select All"),
                  value: isAllEmiratesSelected,
                  activeColor: appbar_color,

                  onChanged: (bool? value) {
                    setState(() {
                      isAllEmiratesSelected = value ?? false;

                      // Update all emirates based on "Select All"
                      for (var emirate in filteredEmirates!) {
                        emirate['isSelected'] = isAllEmiratesSelected;
                      }
                    });
                  },
                ),
                Expanded(
                  child: ListView(
                    children: filteredEmirates!.map((emirate) {
                      return CheckboxListTile(
                        activeColor: appbar_color,
                        title: Text(emirate['label']),
                        value: emirate['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            emirate['isSelected'] = value!;

                            // Update the "Select All" checkbox
                            isAllEmiratesSelected = emirates.every((e) => e['isSelected']);

                            // Dynamically update the areas list
                            updateAreasDisplay();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    onPressed: () {
                      final selectedItems = emirates
                          .where((emirate) => emirate['isSelected'])
                          .map((emirate) => {
                        'id': emirate['id'],
                        'label': emirate['label'],
                      })
                          .toList();

                      Navigator.of(context).pop(selectedItems.isEmpty ? null : selectedItems);
                    },
                    child: Text('OK'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        selectedEmiratesList = selectedItems;

        // Update the selectedEmirates string
        selectedEmiratesString = selectedItems.map((item) => item['label'] as String).join(', ');


        // Refresh areas to display
        updateAreasDisplay();
      });
    } else {
      setState(() {
        selectedEmiratesList.clear();
        selectedEmiratesString = "Select Emirate";

        // Clear areas to display
        updateAreasDisplay();
      });
    }
  }

  // Area Dropdown based on selected emirates
  void _openAreaDropdown(BuildContext context) async {
    updateAreasDisplay(); // Ensure areasToDisplay is updated before opening

    final selectedItems = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        filteredAreas = List.from(areasToDisplay);
        isAllAreasSelected = filteredAreas!.every((a) => a['isSelected']);


        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "Select Area(s)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        filteredAreas = areasToDisplay
                            .where((area) => area['label']
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Areas',
                      prefixIcon: Icon(Icons.search, color: appbar_color),
                      labelStyle: TextStyle(color: appbar_color),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color, width: 2.0),
                      ),
                    ),
                    cursorColor: appbar_color,
                  ),
                ),
                CheckboxListTile(
                  title: Text("Select All"),
                  value: isAllAreasSelected,
                  activeColor: appbar_color,

                  onChanged: (bool? value) {
                    setState(() {
                      isAllAreasSelected = value ?? false;

                      // Update all areas based on "Select All"
                      for (var area in filteredAreas!) {
                        area['isSelected'] = isAllAreasSelected;
                      }
                    });
                  },
                ),
                Expanded(
                  child: ListView(
                    children: filteredAreas!.map((area) {
                      String? emirateName;
                      areas.forEach((key, value) {
                        if (value.contains(area)) {
                          emirateName = key;
                        }
                      });
                      return CheckboxListTile(
                        activeColor: appbar_color,
                        title: Text('${area['label']} - ${emirateName ?? "Unknown"}'), // Label with emirate name
                        value: area['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            area['isSelected'] = value!;
                            isAllAreasSelected = filteredAreas!.every((a) => a['isSelected']);
                            updateSelectedAreasString(filteredAreas!);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    onPressed: () {
                      final selectedItems = filteredAreas!
                          .where((area) => area['isSelected'])
                          .map((area) => {
                        'id': area['id'],
                        'label': area['label'],
                      }).toList();

                      Navigator.of(context).pop(selectedItems.isEmpty ? null : selectedItems);
                    },
                    child: Text('OK'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        selectedAreas = selectedItems;
        selectedAreasString = selectedItems.map((item) => item['label'] as String).join(', ');


      });
    } else {
      setState(() {
        selectedAreas.clear();
        selectedAreasString = 'Select Area(s)';

      });
    }
  }

  @override
  void initState() {
    super.initState();

    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {


    customernamecontroller.text = widget.name;
    customercontactnocontroller.text = widget.contactno;
    emailcontroller.text = widget.email;


    prefs = await SharedPreferences.getInstance();
    setState(() {

      range_min = prefs!.getDouble('range_min') ?? 10000;
      range_max = prefs!.getDouble('range_max') ?? 100000;

      double range_start = range_min! + (range_min! / 0.8);
      double range_end = range_max! - (range_max! * 0.2);

      _currentRangeValues = RangeValues(range_start, range_end);

      startController.text = _currentRangeValues!.start.toStringAsFixed(0);
      endController.text = _currentRangeValues!.end.toStringAsFixed(0);
    });

    fetchLeadStatus();
    fetchLeadType();

    /*_preSelectUnitTypes();*/

    /*_preSelectEmiratesAndAreas();*/

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        centerTitle: true,

        leading: GestureDetector(
          onTap: ()
          {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SalesInquiryReport()),
            );
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),
        title: Text('Follow-Up Inquiry',
            style: TextStyle(
                color: Colors.white
            )),
      ),
      body: Stack(
        children: [
          Visibility(
            visible: _isLoading,
            child: Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
          SingleChildScrollView(
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,

                ),
              child: Column(
                children: [
                  /*Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(
                        left: 20,
                        top: 20,
                        right: 30,
                        bottom: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Follow Up Inquiry',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          *//*SizedBox(height: 5,),
                          Text(
                            'Follow up your sales inquiry',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                          ),*//*
                        ],
                      )
                  ),*/

                  Container(
                      child:  Form(
                          key: _formKey,

                          child: Column(
                            /*physics: NeverScrollableScrollPhysics(),*/
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Container(
                                  padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 0),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [

                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: appbar_color.withOpacity(0.1),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: appbar_color.withOpacity(0), // Shadow color
                                                    spreadRadius: 2, // How much the shadow spreads
                                                    blurRadius: 5, // Softness of the shadow
                                                    offset: Offset(2, 2), // Changes the shadow position (X, Y)
                                                  ),
                                                ],
                                                borderRadius: BorderRadius.circular(12.0),
                                              ),
                                              child: Row(
                                                  children: [

                                                    Icon(
                                                        FontAwesomeIcons.userCircle,
                                                        color: appbar_color.withOpacity(1),
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8,),

                                                    Text(
                                                      customernamecontroller.text.isNotEmpty ? customernamecontroller.text : '',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: appbar_color.withOpacity(1),
                                                          fontWeight: FontWeight.w500
                                                      ),
                                                    ),
                                                  ],
                                              )
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: appbar_color.withOpacity(0.1),

                                                borderRadius: BorderRadius.circular(12.0),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: appbar_color.withOpacity(0), // Shadow color
                                                    spreadRadius: 2, // How much the shadow spreads
                                                    blurRadius: 5, // Softness of the shadow
                                                    offset: Offset(2, 2), // Changes the shadow position (X, Y)
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [

                                                    /*Icon(
                                                      FontAwesomeIcons.phone,
                                                      color: appbar_color.withOpacity(1),
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8,),*/
                                                    Text(
                                                        customercontactnocontroller.text.isNotEmpty ? customercontactnocontroller.text : _hintText,
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color: appbar_color.withOpacity(1),
                                                            fontWeight: FontWeight.w500
                                                        )
                                                    ),


                                                    Row(children:[
                                                      SizedBox(width: 10),

                                                      _buildDecentButton(
                                                        'Whatsapp',
                                                        FontAwesomeIcons.whatsapp,
                                                        Colors.green,
                                                            ()
                                                        {
                                                          _showWhatsAppPopup(context,() {
                                                            setState(() {}); // Updates the main widget
                                                          }); // Updates the main widget

                                                        },
                                                      ),
                                                      SizedBox(width: 10),
                                                      _buildDecentButton(
                                                        'Call',
                                                        FontAwesomeIcons.phone,
                                                        Colors.blueAccent,
                                                        openCaller,
                                                      ),
                                                    ])

                                                  ],
                                              )
                                            ),
                                          ),

                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: appbar_color.withOpacity(0.1),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: appbar_color.withOpacity(0), // Shadow color
                                                    spreadRadius: 2, // How much the shadow spreads
                                                    blurRadius: 5, // Softness of the shadow
                                                    offset: Offset(2, 2), // Changes the shadow position (X, Y)
                                                  ),
                                                ],
                                                borderRadius: BorderRadius.circular(12.0),
                                              ),
                                              child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children:[

                                                    /*Icon(
                                                      FontAwesomeIcons.envelope ,
                                                      color: appbar_color.withOpacity(1),
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8,),*/
                                                    Text(
                                                        emailcontroller.text.isNotEmpty ? emailcontroller.text : '',
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color: appbar_color.withOpacity(1),
                                                            fontWeight: FontWeight.w500
                                                        )
                                                    ),

                                                    Row(children:[
                                                      SizedBox(width: 10),
                                                      _buildDecentButtonwithLabel(
                                                        'Send',
                                                        FontAwesomeIcons.envelope,
                                                        Colors.blueAccent,
                                                            () {

                                                              _showEmailPopup(() {
                                                                setState(() {}); // Updates the main widget
                                                              }); // Updates the main widget

                                                        },
                                                      ),
                                                    ])
                                                  ]
                                              )
                                            ),
                                          ),

                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // second option for headers
                                /*Container(
                                  padding: EdgeInsets.all(20),
                                  margin: EdgeInsets.all(20),

                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customernamecontroller.text.isNotEmpty ? customernamecontroller.text : '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w200,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              customercontactnocontroller.text.isNotEmpty ? customercontactnocontroller.text : _hintText,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w200,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          _buildDecentButton(
                                            'Whatsapp',
                                            FontAwesomeIcons.whatsapp,
                                            Colors.green,
                                            openWhatsApp,
                                          ),
                                          SizedBox(width: 10),
                                          _buildDecentButton(
                                            'Call',
                                            FontAwesomeIcons.phone,
                                            appbar_color,
                                            openCaller,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              emailcontroller.text.isNotEmpty ? emailcontroller.text : '',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w200,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          _buildDecentButtonwithLabel(
                                            'Send',
                                            FontAwesomeIcons.envelope,
                                            appbar_color,
                                                () {
                                              openEmail(widget.id.toString());
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),*/

                                // follow up type
                                Container(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.only(top:20,left:20,right:20,bottom :0),
                                              child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    DropdownButtonFormField<FollowUpType>(
                                                        value: selectedfollowup_type,  // This should be an object of FollowUpStatus
                                                        decoration: InputDecoration(
                                                          hintText: 'Select Follow-up Type*',
                                                          label: Text(
                                                            'Follow-up Type*',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.normal,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderSide: BorderSide(color: Colors.black54),
                                                            borderRadius: BorderRadius.circular(10.0),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: appbar_color),
                                                            borderRadius: BorderRadius.circular(10.0),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(10.0),
                                                            borderSide: BorderSide(color: Colors.black54),
                                                          ),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                                        ),
                                                        validator: (value) {
                                                          if (value == null) {
                                                            return 'Follow-up Type is required'; // Error message
                                                          }
                                                          return null; // No error if a value is selected
                                                        },
                                                        dropdownColor: Colors.white,
                                                        icon: Icon(Icons.arrow_drop_down, color: appbar_color),
                                                        items: followuptype_list.map((FollowUpType status) {
                                                          return DropdownMenuItem<FollowUpType>(
                                                            value: status,
                                                            child: Text(
                                                              status.name,  // Display the 'name'
                                                              style: TextStyle(color: Colors.black87),
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (FollowUpType? value) {
                                                          setState(() {
                                                            selectedfollowup_type = value;
                                                          });})]))])),

              // follow up status
            Container(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.only(top:20,left:20,right:20,bottom :0),
                                              child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    DropdownButtonFormField<FollowUpStatus>(
                                                        value: selectedfollowup_status,  // This should be an object of FollowUpStatus
                                                        decoration: InputDecoration(
                                                          hintText: 'Select Follow-up Status*',
                                                          label: Text(
                                                            'Follow-up Status*',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.normal,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderSide: BorderSide(color: Colors.black54),
                                                            borderRadius: BorderRadius.circular(10.0),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: appbar_color),
                                                            borderRadius: BorderRadius.circular(10.0),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(10.0),
                                                            borderSide: BorderSide(color: Colors.black54),
                                                          ),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                                        ),
                                                        validator: (value) {
                                                          if (value == null) {
                                                            return 'Follow-up Status is required'; // Error message
                                                          }
                                                          return null; // No error if a value is selected
                                                        },
                                                        dropdownColor: Colors.white,
                                                        icon: Icon(Icons.arrow_drop_down, color: appbar_color),
                                                        items: followupstatus_list.map((FollowUpStatus status) {
                                                          return DropdownMenuItem<FollowUpStatus>(
                                                            value: status,
                                                            child: Text(
                                                              status.name,  // Display the 'name'
                                                              style: TextStyle(color: Colors.black87),
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (FollowUpStatus? value) {
                                                          setState(() {
                                                            selectedfollowup_status = value;
                                                            if(selectedfollowup_status!.category!='Normal')
                                                            {
                                                              nextFollowUpDate = null;
                                                            }
                                                          });})]))])),


                                if(selectedfollowup_status!=null && selectedfollowup_status!.category == 'Normal') // follow up date
                                  Container(
                                    padding: EdgeInsets.only(top: 15, left: 20, right: 20),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Next Follow-Up:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () async {
                                            DateTime? pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: nextFollowUpDate ?? DateTime.now().add(Duration(days: 1)),
                                              firstDate: DateTime.now().add(Duration(days: 1)), // Restrict past dates
                                              lastDate: DateTime(2100),
                                              builder: (BuildContext context, Widget? child) {
                                                return Theme(
                                                  data: ThemeData.light().copyWith(
                                                    colorScheme: ColorScheme.light(
                                                      primary: appbar_color, // Header background and selected date color
                                                      onPrimary: Colors.white, // Header text color
                                                      onSurface: Colors.black, // Calendar text color
                                                    ),
                                                    textButtonTheme: TextButtonThemeData(
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: appbar_color, // Button text color
                                                      ),
                                                    ),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );

                                            if (pickedDate != null) {
                                              setState(() {
                                                nextFollowUpDate = pickedDate; // Save selected date
                                              });
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              if(nextFollowUpDate != null)
                                                Row(children:[
                                                  Text(
                                                    nextFollowUpDate != null
                                                        ? DateFormat("dd-MMM-yyyy").format(nextFollowUpDate!) // Formatting date
                                                        : "",
                                                    style: TextStyle(fontSize: 16, color: Colors.black87),
                                                  ),
                                                  SizedBox(width: 10),

                                                ]),
                                              Container(
                                                margin: EdgeInsets.only(top: 0.0),
                                                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(30.0),
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color: Colors.black.withOpacity(0.3),
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 8.0,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [

                                                    FaIcon(FontAwesomeIcons.calendarPlus,color:Colors.black),
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
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                /*Container(
                                  padding: const EdgeInsets.only(left: 20.0, right: 20, top: 15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Property Type:",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 8.0,
                                          runSpacing: 8.0,

                                          children: propertyType.map((amenity) {
                                            final isSelected = selectedPropertyType == amenity; // Single selection logic
                                            return ChoiceChip(
                                              label: Column(
                                                children: [
                                                  if (amenity == "Residential")
                                                    Icon(
                                                      Icons.home,
                                                      color: isSelected ? Colors.white : Colors.black,
                                                    ),
                                                  if (amenity == "Commercial")
                                                    Icon(
                                                      Icons.business,
                                                      color: isSelected ? Colors.white : Colors.black,
                                                    ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    amenity,
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.white : Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              selected: isSelected,
                                              selectedColor: appbar_color,
                                              onSelected: (bool selected) {
                                                setState(() {
                                                  selectedPropertyType = selected ? amenity : null; // Ensure only one selection
                                                });
                                              },
                                              showCheckmark: false,
                                              backgroundColor: Colors.white,// Disable the checkmark

                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),*/

                                /*Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Unit Type:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16

                                          )
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        '*', // Red asterisk for required field
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.red, // Red color for the asterisk
                                        ),
                                      ),
                                    ],
                                  ),
                                ),*/  // unit type

                                /*Padding(
                                  padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                  child: GestureDetector(
                                    onTap: () => _openUnitTypeDropdown(context), // Open the custom dropdown
                                    child: TextFormField(
                                      controller: TextEditingController(text: selectedUnitType),
                                      decoration: InputDecoration(
                                        hintText: 'Select Unit Type(s)',
                                        contentPadding: EdgeInsets.all(15),
                                        fillColor: isUnitSelected ? Colors.transparent : Colors.transparent, // Set to black if selected
                                        filled: true, // Ensure the field is filled but transparent or black based on isSelected
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.black54), // Black border
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.black54), // Black border when enabled
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.black54), // Black border when disabled
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.black54), // Black focused border
                                        ),
                                        labelStyle: TextStyle(color: Colors.black54),
                                        hintStyle: TextStyle(color: Colors.black54), // Hint text color (white for better contrast)
                                      ),
                                      enabled: false, //// Disable direct editing
                                      validator: (value) {
                                        // If no unit type is selected, show error
                                        bool isAnySelected = unitTypes.any((unit) => unit['isSelected']);
                                        if (!isAnySelected) {
                                          return 'Unit type is required';
                                        }
                                        return null; // No error
                                      },
                                    ),
                                  ),
                                ),*/

                                /*Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: unittypecontroller,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Unit type is required';
                                        }

                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Unit Type(s)',
                                        contentPadding: EdgeInsets.all(15),


                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Set the border radius
                                          borderSide: BorderSide(
                                            color: Colors.black, // Set the border color
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color:  Colors.black, // Set the focused border color
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                    )


                                ),*/

                                /*Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(padding: EdgeInsets.only(top: 15,left:20),

                                        child:Row(
                                          children: [
                                            Text("Select Emirate:",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16

                                                )
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              '*', // Red asterisk for required field
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.red, // Red color for the asterisk
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Padding(
                                        padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                        child: GestureDetector(
                                          onTap: () => _openEmirateDropdown(context), // Open the custom dropdown
                                          child: Container(
                                            width: double.infinity, // Make the container expand to full width
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: Colors.transparent, // Set it to transparent
                                              border: Border.all(color: Colors.black54), // Black border
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
                                              children: [
                                                // Column to display selected emirates
                                                Expanded(
                                                  child: selectedEmiratesString.isNotEmpty
                                                      ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: selectedEmiratesString.split(', ').map((emirate) {
                                                      return Text(
                                                        emirate, // Display each emirate on a new line
                                                        style: TextStyle(fontSize: 16, color: Colors.grey),
                                                      );
                                                    }).toList(),
                                                  )
                                                      : Text(
                                                    'Select Emirate', // Placeholder text when no emirates are selected
                                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                                  ),
                                                ),
                                                // Down arrow icon
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.grey, // Adjust the color of the arrow
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )


                                      */

                                /*Padding(
                                        padding: EdgeInsets.only(top:0,left:20,right:20,bottom :0),

                                        child: DropdownButtonFormField<dynamic>(
                                          decoration: InputDecoration(

                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.black),
                                              borderRadius: BorderRadius.circular(10.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: appbar_color),
                                              borderRadius: BorderRadius.circular(10.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10.0),
                                              borderSide: BorderSide(color: Colors.black),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                          ),

                                          hint: Text('Select Emirate'), // Add a hint
                                          value: selectedEmirate,
                                          items: emirate.map((item) {
                                            return DropdownMenuItem<dynamic>(
                                              value: item,
                                              child: Text(item),
                                            );
                                          }).toList(),
                                          onChanged: (value) async {
                                            selectedEmirate = value!;
                                          },

                                          onTap: ()
                                          {
                                            setState(() {
                                              _isFocused_email = false;
                                              _isFocus_name = false;
                                            });

                                          },
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Emirate is required'; // Error message
                                            }
                                            return null; // No error if a value is selected
                                          },
                                        ),
                                      ),*//*

                                    ],
                                  ),
                                ),*/

                                /*Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Area:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16

                                          )
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        '*', // Red asterisk for required field
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.red, // Red color for the asterisk
                                        ),
                                      ),
                                    ],
                                  ),
                                ),*/

                                /*Padding(
                                  padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                  child: GestureDetector(
                                    onTap: selectedEmiratesList.isNotEmpty
                                        ? () => _openAreaDropdown(context) // Open the custom dropdown
                                        : null, // Disable if no emirates are selected
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.transparent, // Set it to transparent as per your requirement
                                        border: Border.all(color: Colors.black54), // Black border
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
                                        children: [
                                          // Column to display selected emirates
                                          Expanded(
                                            child: selectedAreasString.isNotEmpty
                                                ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: selectedAreasString.split(', ').map((emirate) {
                                                return Text(
                                                  emirate, // Display each emirate on a new line
                                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                                );
                                              }).toList(),
                                            )
                                                : Text(
                                              'Select Area(s)', // Placeholder text when no emirates are selected
                                              style: TextStyle(fontSize: 16, color: Colors.grey),
                                            ),
                                          ),
                                          // Down arrow icon
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey, // Adjust the color of the arrow
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Amenities:",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 10),

                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        margin: EdgeInsets.only(left: 0, right: 0, bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,

                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.black, width: 0.75),
                                        ),
                                        child: MultiSelectDialogField(
                                          items: amenities
                                              .map((amenity) =>
                                              MultiSelectItem<int>(amenity['id'], amenity['name']))
                                              .toList(),

                                          initialValue: selectedAmenities.toList(),
                                          title: Text("Amenities"),
                                          searchable: true,
                                          selectedColor: appbar_color,
                                          checkColor: Colors.white,
                                          confirmText: Text(
                                            "Confirm",
                                            style: TextStyle(color: appbar_color), // Custom confirm button
                                          ),
                                          cancelText: Text(
                                            "Cancel",
                                            style: TextStyle(color: appbar_color), // Custom cancel button
                                          ),
                                          buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                                          buttonText: Text(
                                            "Select Amenities",
                                            style: TextStyle(color: Colors.black54, fontSize: 16),
                                          ),
                                          onConfirm: (values) {
                                            setState(() {
                                              selectedAmenities = Set<int>.from(values);
                                            });
                                          },
                                          chipDisplay: MultiSelectChipDisplay(
                                            textStyle: TextStyle(color: Colors.white), // Selected value text color
                                            chipColor: appbar_color,
                                            items: selectedAmenities
                                                .map((id) => MultiSelectItem<int>(
                                                id, amenities.firstWhere((item) => item['id'] == id)['name']))
                                                .toList(),
                                            onTap: (value) {
                                              setState(() {
                                                selectedAmenities.remove(value);
                                              });
                                            },
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.transparent),
                                          ),

                                        ),
                                      )



                                    ],
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.only(left: 20.0, right: 20, top: 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Special Features:",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 10),


                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        margin: EdgeInsets.only(left: 0, right: 0, bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,

                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.black, width: 0.75),
                                        ),
                                        child:  MultiSelectDialogField(
                                          items: specialfeatures
                                              .map((amenity) =>
                                              MultiSelectItem<int>(amenity['id'], amenity['name']))
                                              .toList(),
                                          initialValue: selectedSpecialFeatures.toList(),
                                          title: Text("Special Features"),
                                          searchable: true,
                                          selectedColor: appbar_color,
                                          checkColor: Colors.white,
                                          confirmText: Text(
                                            "Confirm",
                                            style: TextStyle(color: appbar_color),
                                          ),
                                          cancelText: Text(
                                            "Cancel",
                                            style: TextStyle(color: appbar_color),
                                          ),
                                          buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                                          buttonText: Text(
                                            "Select Special Features",
                                            style: TextStyle(color: Colors.black54, fontSize: 16),
                                          ),
                                          onConfirm: (values) {
                                            setState(() {
                                              selectedSpecialFeatures = Set<int>.from(values);
                                            });
                                          },
                                          chipDisplay: MultiSelectChipDisplay(
                                            textStyle: TextStyle(color: Colors.white),
                                            chipColor: appbar_color,
                                            items: selectedSpecialFeatures
                                                .map((id) => MultiSelectItem<int>(
                                                id,
                                                specialfeatures
                                                    .firstWhere((feature) => feature['id'] == id)['name']))
                                                .toList(),
                                            onTap: (value) {
                                              setState(() {
                                                selectedSpecialFeatures.remove(value);
                                              });
                                            },
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.transparent),
                                          ),
                                        ),

                                      )
                                    ],
                                  ),
                                ),
*/

                                /*Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: areacontroller,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Area is required';
                                        }

                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Area',
                                        contentPadding: EdgeInsets.all(15),


                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Set the border radius
                                          borderSide: BorderSide(
                                            color: Colors.black, // Set the border color
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color:  Colors.black, // Set the focused border color
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                    )


                                ),*/

                                /*Container(
                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(padding: EdgeInsets.only(top: 15,left:20),

                                      child:Row(
                                        children: [
                                          Text("Assigned To:",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16

                                              )
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            '*', // Red asterisk for required field
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.red, // Red color for the asterisk
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Padding(
                                      padding: EdgeInsets.only(top:0,left:20,right:20,bottom :0),

                                      child: DropdownButtonFormField<dynamic>(
                                        decoration: InputDecoration(

                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.black),
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: appbar_color),
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10.0),
                                            borderSide: BorderSide(color: Colors.black),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                        ),


                                        hint: Text('Select Assigned To'), // Add a hint
                                        value: selectedasignedto,
                                        items: asignedto.map((item) {
                                          return DropdownMenuItem<dynamic>(
                                            value: item,
                                            child: Text(item),
                                          );
                                        }).toList(),
                                        onChanged: (value) async {
                                          selectedasignedto = value!;
                                        },

                                        onTap: ()
                                        {
                                          setState(() {
                                            _isFocused_email = false;
                                            _isFocus_name = false;
                                          });

                                        },

                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Assigned To is required'; // Error message
                                          }
                                          return null; // No error if a value is selected
                                        },
                                      ),
                                    ),


                                  ],
                                ),
                              ),*/

                                /*Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Follow-Up Remarks:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16

                                          )
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        '*', // Red asterisk for required field
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.red, // Red color for the asterisk
                                        ),
                                      ),
                                    ],
                                  ),
                                ),*/

                                Padding(padding: EdgeInsets.only(top:20,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: remarksController,
                                      keyboardType: TextInputType.multiline,
                                      maxLength: 500, // Limit input to 500 characters
                                      maxLines: 3,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Remarks are required';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        floatingLabelStyle: TextStyle(
                                          color: appbar_color, // Change label color when focused
                                          fontWeight: FontWeight.normal,
                                        ),
                                        hintText: 'Enter Remarks*',
                                        labelText: 'Remarks',
                                        contentPadding: EdgeInsets.all(15),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Set the border radius
                                          borderSide: BorderSide(
                                            color: Colors.black, // Set the border color
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color:  appbar_color, // Set the focused border color
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },

                                      onTap: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                    )
                                ),

                                Padding(padding: EdgeInsets.only(left: 20,right: 20,top: 40,bottom: 50),
                                  child: Container(
                                      child: Row(
                                        mainAxisAlignment:MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white, // Button background color
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5), // Rounded corners
                                                side: BorderSide(
                                                  color: Colors.grey, // Border color
                                                  width: 0.5, // Border width
                                                ),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {

                                                _formKey.currentState?.reset();

                                                /*print(_selectedrole['role_name']);*/

                                                nextFollowUpDate = null;
                                                selectedfollowup_status = null;
                                                selectedfollowup_type = null;
                                                remarksController.clear();

                                              });
                                            },
                                            child: Text('Clear'),
                                          ),

                                          SizedBox(width: 20,),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: appbar_color, // Button background color
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5), // Rounded corners
                                                side: BorderSide(
                                                  color: Colors.grey, // Border color
                                                  width: 0.5, // Border width
                                                ),
                                              ),
                                            ),
                                            onPressed: () {

                                              if (_formKey.currentState != null &&
                                                  _formKey.currentState!.validate()) {
                                                _formKey.currentState!.save();

                                                setState(() {
                                                  _isFocused_email = false;
                                                  _isFocus_name = false;
                                                });
                                                sendFollowupInquiryRequest();
                                              }},
                                            child: Text('Submit'),
                                          ),
                                        ],)
                                  ),)
                              ]))
                  )


                ],
              )
            )
              ,)
        ],
      ) ,);}}
Widget _buildDecentButton(
    String label, IconData icon, Color color, VoidCallback onPressed) {

  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(30.0),
    splashColor: color.withOpacity(0.2),
    highlightColor: color.withOpacity(0.1),
    child: Container(
      margin: EdgeInsets.only(top: 0.0),
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          FaIcon(icon,color:color),
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

Widget _buildDecentButtonwithLabel(
    String label, IconData icon, Color color, VoidCallback onPressed) {

  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(30.0),
    splashColor: color.withOpacity(0.2),
    highlightColor: color.withOpacity(0.1),
    child: Container(
      margin: EdgeInsets.only(top: 0.0),
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          FaIcon(icon,color:color),
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
