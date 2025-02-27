import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:pdf/pdf.dart'; // For kIsWeb check
import 'package:http/http.dart' as http;
import 'MaintenanceTicketReport.dart';
import 'constants.dart';
import 'package:printing/printing.dart'; // For PDF preview
import 'package:pdf/widgets.dart' as pw;

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
  }

  File? _signatureFile; // Store the signature separately

  Future<void> _saveSignature(String id) async {
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

     /* generatePdf(context);*/

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving signature: $e')),
      );
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

    final url = '$BASE_URL_config/v1/maintenanceStatus'; // Replace with your API endpoint
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

        print('data $jsonData');
        final List<dynamic> statuses = jsonData['data']['maintenanceStatus'];
        setState(() {
          maintenanceStatusList =
              statuses.map((status) => MaintenanceStatus.fromJson(status)).toList();
        });
      } else {
        print('Upload failed with status code: ${response.statusCode}');
        print('Upload failed with response: ${response.body}');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }
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
          style: TextStyle(
              color: Colors.white
          ),),
      ),
      body: SingleChildScrollView(
        child:Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 20.0,right:20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 16,),
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
                              Text(followUp["role"]!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(followUp["description"]!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              SizedBox(height: 0),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),),

              SizedBox(height: 10,),

              Container(
                margin: EdgeInsets.only(left: 0, right: 20,bottom:6),
                child: Row(
                  children: [
                    Text(
                      'Maintenance Status',
                      style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold,),
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
    style: TextStyle(color: Colors.black54, fontSize: 16),
    ),
    onChanged: (value) {
    setState(() {
    selectedStatus = value;

    if(selectedStatus!.category != 'Close')
      {
        _signatureController.clear();
      }
    });
    },
    ),
    ),

              SizedBox(height: 6),

              Padding(
                padding: EdgeInsets.only(top: 0),
                child: TextFormField(

                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Amount",
                    prefixText: "AED ",
                    contentPadding: EdgeInsets.all(15),

                    floatingLabelStyle: TextStyle(
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

              SizedBox(height: 16),

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
                  floatingLabelStyle: TextStyle(
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
                  labelStyle: TextStyle(
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
                            style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,),
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
                            setState(() {

                              _signatureController.clear();

                            });
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
                      style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold,),
                    ),
                    /*SizedBox(width: 2),
                    Text(
                      '*', // Red asterisk for required field
                      style: TextStyle(
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

                              selectedStatus = null;

                              _amountController.clear();
                              _remarksController.clear();


                              _signatureController.clear();

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
                                _saveSignature(widget.ticketid);
                              }
                            else
                              {
                                // for no close category
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Submit.')),
                                );
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
