import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:pdf/pdf.dart'; // For kIsWeb check
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'MaintenanceTicketReport.dart';
import 'constants.dart';
import 'package:printing/printing.dart'; // For PDF preview
import 'package:pdf/widgets.dart' as pw;
import 'package:http_parser/src/media_type.dart';

class MaintenanceStatus {
  final int id;
  final String name;
  final String category;
  final int company_id;

  MaintenanceStatus({
    required this.id,
    required this.name,
    required this.category,
    required this.company_id,
  });

  factory MaintenanceStatus.fromJson(Map<String, dynamic> json) {
    return MaintenanceStatus(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      company_id: json['company_id'],
    );
  }
}

class MaintenanceFollowUpScreen extends StatefulWidget {
  final String ticketid; // Accept ID

  MaintenanceFollowUpScreen({required this.ticketid});
  @override
  _MaintenanceFollowUpScreenState createState() => _MaintenanceFollowUpScreenState();
}

class _MaintenanceFollowUpScreenState extends State<MaintenanceFollowUpScreen>  {
  List<Map<String, String>> followUps = [
    {"role": "Created", "description": "Ticket created"},
    {"role": "Supervisor", "description": "Checked and approved"},
    {"role": "Technician", "description": "Work in progress"},
    //{"role": "Technician", "description": "Work Completed"},
    //{"role": "Closed", "description": "Ticket closed"},
  ];

  DateTime? nextFollowupDate;

  MaintenanceStatus? selectedStatus;

   SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  List<MaintenanceStatus> maintenanceStatusList = [];

  List<dynamic> _attachment = [];
  final ImagePicker _picker = ImagePicker();
  TextEditingController _remarksController = TextEditingController();
  TextEditingController _amountController = TextEditingController();

  List<Map<String, dynamic>> subTickets = [];
  int? selectedSubTicketId;

  Future<void> _selectNextFollowupDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: nextFollowupDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Restricts past dates
      lastDate: DateTime(2100),  // You can set this to any future date
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: appbar_color,
            colorScheme: ColorScheme.light(
              primary: appbar_color, // Highlights selection in blue
            ),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != nextFollowupDate) {
      setState(() {
        nextFollowupDate = pickedDate;
      });
    }
  }

  Future<void> sendFormData() async {

    try {
      String url = is_admin
          ? "$baseurl/maintenance/followup"
          : "$baseurl/maintenance/followup";

      var uuid = Uuid();
      String uuidValue = uuid.v4();
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final Map<String, dynamic> requestBody = {
        "uuid":uuidValue,
        "sub_ticket_id":selectedSubTicketId,
        "status_id":selectedStatus!.id,
        "date":todayDate,
        "description": _remarksController.text,
        "next_followup_date":DateFormat('yyyy-MM-dd').format(nextFollowupDate ?? DateTime.now())
      };

      print('followup request body : ${requestBody}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Company_Token",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {

        Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        int followupId = decodedResponse["data"]["followp"]["id"];
        sendImageData(followupId);

        print('follow up without image successfull');

        setState(() {
          _amountController.clear();
          selectedStatus = null;
          selectedSubTicketId = null;
          _remarksController.clear();
          nextFollowupDate = null;
          _signatureController.clear();
          _attachment.clear();
        });

        sendImageData(followupId);

      }
      else {
        print('Upload failed with status code: ${response.statusCode}');
        print('Upload failed with response: ${response.body}');
      }
    } catch (e) {
      print('Error during upload: $e');
    }
  }

  bool isValidImage(dynamic file) {
    final validExtensions = ['jpg', 'jpeg', 'png'];

    if (file is File) {
      // For mobile, check the file extension

      final extension = file.path.split('.').last.toLowerCase();
      return validExtensions.contains(extension);
    } else if (file is Uint8List) {
      // For web, check the MIME type
      final mimeType = lookupMimeType('', headerBytes: file);
      return mimeType != null && mimeType.startsWith('image/');
    }
    return false;
  }

  String getMimeType(String path) {
    final mimeType = lookupMimeType(path);
    return mimeType?.split('/').last ?? 'jpeg'; // Default to JPEG
  }

  Future<void> sendImageData(int id) async {
    try {
      final String urll = "$baseurl/uploads/followup/$id";
      final url = Uri.parse(urll);

      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $Company_Token', // Authentication token
      });

      // ✅ Ensure only valid images are uploaded
      _attachment = _attachment.where(isValidImage).toList();

      for (var file in _attachment) {
        if (file is File) {
          // ✅ Mobile (iOS & Android) - Use file path
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              file.path,
              filename: basename(file.path),
              contentType: MediaType('image', getMimeType(file.path)),
            ),
          );
        } else if (file is Uint8List) {
          // ✅ Web - Use in-memory file
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              file,
              filename: 'followup_image_${DateTime.now().millisecondsSinceEpoch}.png',
              contentType: MediaType('image', 'png'), // Defaulting to PNG
            ),
          );
        }
      }

      // ✅ Send request & handle response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {

        print('then follow up with image successfull');

        setState(() {
          _amountController.clear();
          selectedStatus = null;
          selectedSubTicketId = null;
          _remarksController.clear();
          nextFollowupDate = null;
          _signatureController.clear();
          _attachment.clear();
        });

        fetchTickets(widget.ticketid);

      } else {
        print('Upload failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error during upload: $e');
    }
  }

  Future<void> _pickImages({bool fromCamera = false}) async {
    List<XFile>? pickedFiles;

    if (fromCamera) {
      // Capture a single image
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        pickedFiles = [file]; // Convert single file to a list
      }
    } else {
      // Pick multiple images from gallery (works for Web & Mobile)
      pickedFiles = await _picker.pickMultiImage();
    }

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        setState(() {
          if (kIsWeb) {
            _handleWebFile(file);
          } else {
            _handleMobileFile(file);
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {

    fetchMaintenanceStatus();

    print('ticket id ${widget.ticketid}');
    fetchTickets(widget.ticketid);
  }

  File? _signatureFile; // Store the signature separately

  Map<String, dynamic>? tenantFlatDetails;

  Future<void> _saveSignature(String id,BuildContext context) async {
    try {
      if (_signatureController.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please sign before saving.')),
        );
        return;
      }

      // Ensure UI updates before capturing signature
      await Future.delayed(Duration(milliseconds: 100));

      // Convert signature to an image
      final ui.Image? signatureImage = await _signatureController.toImage();
      final ByteData? byteData = await signatureImage?.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not convert signature to image')),
        );
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get internal storage directory
      final directory = await getApplicationSupportDirectory(); // Internal memory location
      final String folderPath = '${directory.path}/$id';
      final Directory userDirectory = Directory(folderPath);

      // Ensure the directory exists
      if (!await userDirectory.exists()) {
        await userDirectory.create(recursive: true);
      }

      final String filePath = '$folderPath/signature.png';
      final signatureFile = File(filePath);

      // **Remove old signature before saving new one**
      if (await signatureFile.exists()) {
        await signatureFile.delete();
      }

      // Save new signature to internal memory
      await signatureFile.writeAsBytes(pngBytes);

      // **Update UI with new signature**
      setState(() {
        _signatureFile = signatureFile; // Store separately
      });

      // **Reset SignatureController**
      _signatureController.clear();
      _signatureController.dispose();
      _signatureController = SignatureController(
        penStrokeWidth: 2,
        penColor: Colors.black,
        exportBackgroundColor: Colors.white,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signature saved successfully!')),
      );

      print("Signature saved at: $filePath");

      // send sign to api
      await uploadSignatureImage(selectedSubTicketId!);

      // sending followup data
      sendFormData();
     /* generatePdf(context);*/

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving signature: $e')),
      );
    }
  }

  Future<void> uploadSignatureImage(int subTicketId) async {
    try {
      if (_signatureFile == null || !await _signatureFile!.exists()) {
        print("No signature file to upload.");
        return;
      }

      final url = Uri.parse("$baseurl/maintenance/followup/sign/$subTicketId"); // ✅ your API for sub_ticket_id

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $Company_Token',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'signature', // field name your backend expects
          _signatureFile!.path,
          filename: basename(_signatureFile!.path),
          contentType: MediaType('image', 'png'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        print('✅ Signature uploaded successfully.');
      } else {
        print('❌ Signature upload failed. Status: ${response.statusCode}');
        print('Body: ${response.body}');
      }
    } catch (e) {
      print('Error uploading signature: $e');
    }
  }

  Future<void> generatePdf(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Load saved signature image
      Uint8List? signatureBytes;
      if (_signatureFile != null && await _signatureFile!.exists()) {
        signatureBytes = await _signatureFile!.readAsBytes();
      }

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Maintenance Report",
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),

                pw.SizedBox(height: 20),

                pw.Text("This document contains the details of the maintenance request.",
                    style: pw.TextStyle(fontSize: 14)),

                pw.SizedBox(height: 40),

                // Display the signature if available
                if (signatureBytes != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Authorized Signature:", style: pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(height: 10),
                      pw.Image(pw.MemoryImage(signatureBytes), width: 200, height: 100),
                    ],
                  )
                else
                  pw.Text("Signature not available", style: pw.TextStyle(fontSize: 14, color: PdfColors.red)),
              ],
            );
          },
        ),
      );

      // Save PDF file
      final output = await getApplicationDocumentsDirectory();
      final pdfFile = File("${output.path}/maintenance_report.pdf");
      await pdfFile.writeAsBytes(await pdf.save());

      // Open PDF Preview
      Printing.layoutPdf(onLayout: (format) async => pdf.save());

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  void _handleMobileFile(XFile file) {
    File newFile = File(file.path);

    setState(() {
      if (!_attachment.any((existingFile) => existingFile is File && existingFile.path == newFile.path)) {
        _attachment.add(newFile);
      }
    });
  }

  Future<void> _handleWebFile(XFile file) async {
    Uint8List bytes = await file.readAsBytes();

    setState(() {
      if (!_attachment.any((existingFile) => existingFile is Uint8List && listEquals(existingFile, bytes))) {
        _attachment.add(bytes);
      }
    });
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16, top: 20, right: 20, bottom: 50),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachmentOption(
                    icon: Icons.upload,
                    label: 'Upload',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(); // Pick images from gallery (works for Web & Mobile)
                    },
                  ),
                  if (!kIsWeb) // Camera option is not supported on Web
                    _attachmentOption(
                      icon: Icons.camera_alt,
                      label: 'Capture',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImages(fromCamera: true); // Capture image using camera
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> fetchMaintenanceStatus() async {

    maintenanceStatusList.clear();

    final url = '$baseurl/maintenance/status'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request



    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {


        final jsonData = json.decode(response.body);

        /*print('data $jsonData');*/
        final List<dynamic> statuses = jsonData['data']['maintenanceStatus'];
        setState(() {
          maintenanceStatusList = statuses
              .where((status) =>
          (status['category'] as String).toLowerCase() != 'drop')
              .map((status) => MaintenanceStatus.fromJson(status))
              .toList();
        });
      } else {
        print('Upload failed with status code: ${response.statusCode}');
        print('Upload failed with response: ${response.body}');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }
  }

  Future<void> fetchTickets(String ticketID) async {
    subTickets.clear();
    String url = is_admin
        ? "$baseurl/maintenance/ticket/$ticketID"
        : '';

    try {
      final Map<String, String> headers = {
        'Authorization': 'Bearer $Company_Token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['success'] == true) {
          var jsonData = responseBody['data']['ticket'];

          // Extract sub_tickets
          final subTicketList = List<Map<String, dynamic>>.from(jsonData['sub_tickets'] ?? []);

          setState(() {
            subTickets = subTicketList.where((ticket) {
              // ✅ Filter by assigned user if needed
              if (is_admin && !is_admin_from_api && ticket['assigned_to'] != user_id) {
                return false;
              }

              final followups = ticket['followps'] as List<dynamic>? ?? [];

              if (followups.isNotEmpty) {
                // Sort to get latest follow-up
                followups.sort((a, b) {
                  final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
                  final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
                  return dateB.compareTo(dateA); // Newest first
                });

                final latestFollowup = followups.first;
                final latestCategory = latestFollowup['status']?['category']?.toString().toLowerCase();

                // ✅ Exclude if closed
                return latestCategory != 'close';
              }

              return true; // Keep if no followups
            }).map((ticket) {
              return {
                "id": ticket["id"],
                "name": ticket["type"]["name"] ?? "Unknown",
                "description": ticket["description"] ?? "",
                "followps": ticket["followps"] ?? []
              };
            }).toList();


            // Extract contract_flat details
            var contractFlat = jsonData['contract_flat'];
            var flatDetails = contractFlat['flat'];
            var building = flatDetails['building'];
            var area = building['area'];
            var state = area['state'];

            tenantFlatDetails = {
              "tenantName": contractFlat['contract']['tenant_id'].toString(), // Assuming tenant_id represents tenant
              "tenantMobile": "", // Not present in new JSON
              "flatName": flatDetails["name"],
              "buildingName": building["name"],
              "areaName": area["name"],
              "stateName": state["name"]
            };
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
  }

  /*Future<void> fetchTickets(String ticketID) async {

    subTickets.clear();
    String url = is_admin
        ? "$baseurl/maintenance/ticket/$ticketID"
        : '';

    *//*final String url = "$BASE_URL_config/v1/maintenance"; // will change it for tenant*//*

    *//*print('url $url');*//*

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

          var jsonData = json.decode(response.body);
          var tickets = jsonData['data']['ticket']['sub_tickets'] as List;
          var tenantFlat = jsonData['data']['ticket']['tenant_flat'];


          setState(() {
            subTickets = tickets.map((ticket) {
              return {
                "id": ticket["id"],
                "name": ticket["type"]["name"],
                "followps": ticket["followps"] as List
              };
            }).toList();

            tenantFlatDetails = {
              "tenantName": tenantFlat["tenent"]["name"],
              "tenantMobile": tenantFlat["tenent"]["mobile"] ?? "",
              "flatName": tenantFlat["flat"]["name"],
              "buildingName": tenantFlat["flat"]["building"]["name"],
              "areaName": tenantFlat["flat"]["building"]["area"]["name"],
              "stateName": tenantFlat["flat"]["building"]["area"]["state"]["name"]
            };
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

  }*/

  Widget platformLoader() {
    return Platform.isIOS
        ? CupertinoActivityIndicator(radius: 12) // iOS-style loader
        : CircularProgressIndicator(
      color: appbar_color, // Matches button text color
      strokeWidth: 3, // Thin and modern look
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: GestureDetector(
          onTap: ()
          {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MaintenanceTicketReport()),
            );
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),

        title: Text('Ticket Follow-Up',
          style: GoogleFonts.poppins(
              color: Colors.white
          )),
      ),
      body: SingleChildScrollView(
        child:Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 20.0,right:20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 10),

              tenantFlatDetails != null
                ? Card(
                elevation: 3,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
                child: Padding(
                padding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 16),
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
                        child: Wrap(
                          runSpacing: 8,
                          spacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [


                            if(widget.ticketid!='null')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.confirmation_number, size: 16, color: Colors.teal),
                                  SizedBox(width: 4),
                                  Text(
                                    "MT-${widget.ticketid}",
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ],
                              ),

                            if (tenantFlatDetails!["tenantMobile"].toString().isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone, size: 16, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    tenantFlatDetails!["tenantMobile"],
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ],
                              ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.apartment, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  tenantFlatDetails!["flatName"],
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ],
                            ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.business, size: 16, color: Colors.orange),
                                SizedBox(width: 4),
                                Text(
                                  tenantFlatDetails!["buildingName"],
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ],
                            ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.red),
                                SizedBox(width: 4),
                                Text(
                                  "${tenantFlatDetails!["areaName"]}, ${tenantFlatDetails!["stateName"]}",
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),),],),),)
                 : Center(child: platformLoader()),

              /*SizedBox(height: 10),

              Padding(padding: EdgeInsets.only(left: 5,top: 10,bottom: 10),
                child:  Column(
                  children: followUps.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> followUp = entry.value;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 2),
                              child: Icon(Icons.circle, size: 12, color: Colors.blueAccent),
                            ),
                            if (index != followUps.length -1)
                              Container(height: 40, width: 2, color: Colors.blueAccent),
                          ],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(followUp["role"]!, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(followUp["description"]!, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                              SizedBox(height: 0),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),),*/

              SizedBox(height: 10),

              Container(
                margin: EdgeInsets.only(left: 0, right: 20,bottom:6),
                child: Row(
                  children: [
                    Text(
                      'Maintenance Type',
                      style: GoogleFonts.poppins(fontSize: 16,
                        fontWeight: FontWeight.bold,),
                    ),
                    SizedBox(width: 2),
                    Text(
                      '*', // Red asterisk for required field
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.red, // Red color for the asterisk
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                margin: EdgeInsets.only(left: 0, right: 0, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 0.75),
                ),
                child: DropdownButtonFormField<int>(
                  value: selectedSubTicketId,
                  items: subTickets.map((subTicket) {
                    return DropdownMenuItem<int>(
                      value: subTicket["id"],
                      child: Text(subTicket["name"]),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  ),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                  hint: Text(
                    "Select Maintenance Type",
                    style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedSubTicketId = value;
                      print("Selected SubTicket ID: $selectedSubTicketId");
                    });
                  },
                ),
              ),

              // Display Selected SubTicket Follow-ups
            if (selectedSubTicketId != null)
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
            padding: EdgeInsets.only(left:20,right:20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Builder(
              builder: (context) {
                var followups = subTickets
                    .firstWhere((ticket) => ticket["id"] == selectedSubTicketId)["followps"];

                followups.sort((a, b) =>
                    DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

                if (followups.isEmpty) {
                  return Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "No follow-ups available",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                    ),
                  );
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 18),
                    Text(
                      "Follow-ups",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),




                    ListView.builder(
                shrinkWrap: true,
                clipBehavior: Clip.none,
                physics: NeverScrollableScrollPhysics(),
                itemCount: followups.length,
                itemBuilder: (context, index) {
                var followup = followups[index];
                return Padding(
                padding: EdgeInsets.only(top:6,bottom:0),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.circle, size: 12, color: appbar_color),
                            if (index != followups.length)
                              Expanded(
                                child: Container(width: 2, color: appbar_color),
                              ),
                          ],
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                followup["created_user"]["name"],
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Status: ${followup["status"]['name']}',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                              ),
                              Text(
                                'Description: ${followup["description"]}',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ]));})
                  ],
                );
                })]))),

              Container(
                margin: EdgeInsets.only(left: 0, right: 20,bottom:6),
                child: Row(
                  children: [
                    Text(
                      'Maintenance Status',
                      style: GoogleFonts.poppins(fontSize: 16,
                        fontWeight: FontWeight.bold,),
                    ),
                    SizedBox(width: 2),
                    Text(
                      '*', // Red asterisk for required field
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.red, // Red color for the asterisk
                      ),
                    ),
                  ],
                ),
              ),

              Container(
    padding: EdgeInsets.symmetric(horizontal: 12),
    margin: EdgeInsets.only(left: 0, right: 0, bottom: 10),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.black, width: 0.75),
    ),
    child: DropdownButtonFormField<MaintenanceStatus>(
    value: selectedStatus,
    items: maintenanceStatusList.map((status) {
    return DropdownMenuItem<MaintenanceStatus>(
    value: status,
    child: Text(status.name),
    );
    }).toList(),
    decoration: InputDecoration(
    border: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    ),
    icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
    hint: Text(
    "Select Maintenance Status",
    style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
    ),
    onChanged: (value) {
    setState(() {
    selectedStatus = value;

    print('status category -> ${selectedStatus!.category}');

    if(selectedStatus!.category != 'Close')
      {
        _signatureController.clear();
      }

    if(selectedStatus!.category != 'Normal')
    {
      nextFollowupDate = null;
    }
    });
    },
    ),
    ),

              if(selectedStatus !=null && (selectedStatus!.category != "Close" && selectedStatus!.category != "Drop"))
                SizedBox(
                width: double.infinity, // Expands to full screen width
                height: 40, // Standard button height
                child: ElevatedButton(
                  onPressed: () => _selectNextFollowupDate(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color, // Blue button
                    foregroundColor: Colors.white, // White text
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Slightly rounded corners
                    ),
                  ),
                  child: Text(
                    nextFollowupDate == null
                        ? "Select Next Follow-up Date"
                        : "Next Follow-up Date: ${DateFormat('dd-MMM-yyyy').format(nextFollowupDate!)}",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ),
              ),

              SizedBox(height: 10),

             /* Center(
                child: DropdownButton<int>(
                  value: selectedSubTicketId,
                  hint: Text("Select Maintenance Type"),
                  items: subTickets.map((subTicket) {
                    return DropdownMenuItem<int>(
                      value: subTicket["id"],
                      child: Text(subTicket["name"]),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedSubTicketId = newValue;
                    });
                    print("Selected SubTicket ID: $selectedSubTicketId");
                  },
                ),
              ),


              SizedBox(height: 6),*/

             /* Padding(
                padding: EdgeInsets.only(top: 0),
                child: TextFormField(

                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Amount",
                    prefixText: "AED ",
                    contentPadding: EdgeInsets.all(15),

                    floatingLabelStyle: GoogleFonts.poppins(
                      color: appbar_color, // Change label color when focused
                      fontWeight: FontWeight.normal,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: appbar_color, // Change this color as needed
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 6),*/

              TextFormField(
                controller: _remarksController,
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
                  hintText: 'Enter Remarks*',
                  labelText: "Remarks",
                  floatingLabelStyle: GoogleFonts.poppins(
                    color: appbar_color, // Change label color when focused
                    fontWeight: FontWeight.normal,
                  ),
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
                      color: appbar_color, // Change this color as needed
                      width: 1,
                    ),
                  ),
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.black,
                  ),
                ),
              ),

              if(selectedStatus !=null && selectedStatus!.category == "Close")

              Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 0, right: 20,bottom:6),
                      child: Row(
                        children: [
                          Text(
                            'Tenant Signature',
                            style: GoogleFonts.poppins(fontSize: 16,
                              fontWeight: FontWeight.bold,),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '*', // Red asterisk for required field
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.red, // Red color for the asterisk
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(
                          color: Colors.black, // Border color
                          width: 1, // Border width
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), // Shadow color
                            spreadRadius: 6, // How much the shadow expands
                            blurRadius: 6, // Softness of the shadow
                            offset: Offset(2, 4), // Position: (X: right, Y: down)
                          ),
                        ],
                        borderRadius: BorderRadius.circular(8), // Optional: Rounded corners
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8), // Match the border radius
                        child: Signature(
                          controller: _signatureController,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // Button background color
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Rounded corners
                              side: BorderSide(
                                color: Colors.grey, // Border color
                                width: 0.5, // Border width
                              ),
                            ),
                          ),
                          onPressed: () {


                            _signatureController.clear();

                            /*fetchTickets(widget.ticketid);*/

                          },
                          child: Text('Clear'),
                        ),
                        /* ElevatedButton(
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
                    onPressed:_saveSignature,
                    child: Text('Save Signature'),
                  ),*/
                      ],
                    ),
                  ],
                ),

              SizedBox(height: 10),

              Container(
                margin: EdgeInsets.only(left: 0, right: 20),
                child: Row(
                  children: [
                    Text(
                      'Attachments',
                      style: GoogleFonts.poppins(fontSize: 16,
                        fontWeight: FontWeight.bold,),
                    ),
                    /*SizedBox(width: 2),
                    Text(
                      '*', // Red asterisk for required field
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.red, // Red color for the asterisk
                      ),
                    ),*/

                  ],
                ),
              ),

              SizedBox(height: 16),

              Container(
                  margin: EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_attachment.isNotEmpty)
                          Column(
                            children: [
                              Wrap(
                                spacing: 12.0, // Horizontal space between items
                                runSpacing: 12.0, // Vertical space between rows
                                children: [
                                  ..._attachment.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var attachment = entry.value; // Can be File (mobile) or Uint8List (web)

                                    return Stack(
                                      children: [
                                        Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.5),
                                                  spreadRadius: 2,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: attachment is File
                                                    ? Image.file(
                                                  attachment, // ✅ Use Image.file for Mobile (File)
                                                  width: 75,
                                                  height: 75,
                                                  fit: BoxFit.cover,
                                                )
                                                    : Image.memory(
                                                  attachment as Uint8List, // ✅ Use Image.memory for Web (Uint8List)
                                                  width: 75,
                                                  height: 75,
                                                  fit: BoxFit.cover,
                                                ))),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _attachment.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withOpacity(0.7), // Semi-transparent black
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3), // Soft shadow
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.all(4), // Slightly larger padding for better touch target
                                              child: Icon(
                                                Icons.close,
                                                size: 15,
                                                color: Colors.white70, // Soft white color for the icon
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: CircleBorder(),
                                      padding: EdgeInsets.all(16),
                                      elevation: 5,
                                      backgroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      _showAttachmentOptions(context);
                                    },
                                    child: Icon(
                                      Icons.add,
                                      size: 30,
                                      color: appbar_color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Column(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(),
                                    padding: EdgeInsets.all(16),
                                    elevation: 8,
                                    backgroundColor: appbar_color,
                                  ),
                                  onPressed: () {
                                    _showAttachmentOptions(context);
                                  },
                                  child: Icon(
                                    Icons.attach_file,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text('No attachment selected'),
                              ])])),

              SizedBox(height: 40),

              Padding(padding: EdgeInsets.only(left: 20,right: 20,top: 0,bottom: 50),
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
                              _amountController.clear();

                              selectedStatus = null;
                              selectedSubTicketId = null;
                              _remarksController.clear();
                              nextFollowupDate = null;

                              _signatureController.clear();
                              _attachment.clear();
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
                          onPressed: ()
                          {
                            if(selectedStatus!.category == "Close")
                              {
                                _saveSignature(widget.ticketid,context);
                              }

                            else
                              {
                                sendFormData();
                              }
                          },
                          child: Text('Submit'),
                        ),
                      ],)
                ),),
            ],
          ),
        ),
      ),

    );
  }
}

Widget _attachmentOption({required IconData icon, required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(4, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Icon(icon, size: 40, color: appbar_color),
        ),
        SizedBox(height: 8),
        Text(label),
      ],
    ),
  );
}
