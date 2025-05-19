import 'dart:convert';
import 'dart:io';

import 'package:cshrealestatemobile/AdminDashboard.dart';
import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'constants.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';


import 'package:http_parser/http_parser.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class DocumentType {
  final int id;
  final String name;
  final bool isMandatory;

  DocumentType({required this.id, required this.name, required this.isMandatory});

  factory DocumentType.fromJson(Map<String, dynamic> json) {
    return DocumentType(
      id: json['id'],
      name: json['name'],
      isMandatory: json['is_mandatory'].toString().toLowerCase() == 'true',
    );
  }
}


class DecentTenantKYCForm extends StatefulWidget {
  @override
  _DecentTenantKYCFormState createState() => _DecentTenantKYCFormState();
}




/*Future<void> sendFormData(PlatformFile? file, String docType, String expiryDate) async {
  if (file == null) {
    print("🚨 No file selected.");
    return;
  }

  String url = "$baseurl/tenant/kyc/$user_id";
  print("🔹 Uploading to: $url");

  try {
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add headers
    request.headers.addAll({
      "Authorization": "Bearer $Company_Token", // Add token if required
    });

    // Add form fields
    request.fields['doc_type'] = docType;
    request.fields['expiry_date'] = expiryDate;

      // Mobile: Use File path
      File filePath = File(file.path!);
      var stream = http.ByteStream(filePath.openRead());
      var length = await filePath.length();

      request.files.add(http.MultipartFile(
        'image',
        stream,
        length,
        filename: file.name,
        contentType: MediaType('image', file.extension ?? 'png'), // Correct usage
      ));


    // Send request
    var response = await request.send();

    // Get response data
    var responseData = await response.stream.bytesToString();
    print("✅ Response: ${response.statusCode}");
    print("📦 Response Data: $responseData");

    if (response.statusCode == 201) {
      print("✔ Upload successful");
    } else {
      print("❌ Upload failed: ${response.statusCode}");
    }
  } catch (e) {
    print("🚨 Error uploading file: $e");
  }
}*/

class _DecentTenantKYCFormState extends State<DecentTenantKYCForm> {
  final _formKey = GlobalKey<FormState>();
  String? emiratesIdFrontFile, emiratesIdBackFile, passportFile, visaFile;

  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController documentNoController = TextEditingController();
  DateTime? _selectedExpiryDate;
  String? selectedDocumentType;

  final RegExp emiratesIdRegex = RegExp(r'^784-\d{4}-\d{7}-\d{1}$');


  List<DocumentType> documentTypes = [];
  DocumentType? selectedDocument;
  bool _isUploading = false;
  String? tradeLicenseFile, vatCertificateFile,documentFile;

  @override
  void initState() {
    super.initState();
    fetchDocumentTypes();
  }

  Future<void> fetchDocumentTypes() async {
    int currentPage = 1;
    int pageSize = 10;
    bool hasMore = true;
    List<DocumentType> allTypes = [];

    try {
      while (hasMore) {
        final response = await http.get(
          Uri.parse('$baseurl/tenant/kycDoc?page=$currentPage&size=$pageSize'),
          headers: {"Authorization": "Bearer $Company_Token"},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List list = data['data']['doc_types'];
          final int total = data['meta']['totalCount'];

          allTypes.addAll(list.map((e) => DocumentType.fromJson(e)).toList());

          // Stop if we've fetched all
          if (allTypes.length >= total) {
            hasMore = false;
          } else {
            currentPage++;
          }
        } else {
          print('Failed to fetch page $currentPage');
          break;
        }
      }

      setState(() {
        documentTypes = allTypes;
      });
    } catch (e) {
      print('Error fetching paginated doc types: $e');
    }
  }

  Future<void> pickFile({bool isFront = true}) async {
    if (selectedDocumentType == null) {
      _showSnackBar("Please select a document type first.");
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        if (selectedDocumentType == 'Emirates ID') {
          if (isFront) {
            emiratesIdFrontFile = file.path;
          } else {
            emiratesIdBackFile = file.path;
          }
        } else if (selectedDocumentType == 'Passport') {
          passportFile = file.path;
        } else if (selectedDocumentType == 'Visa') {
          visaFile = file.path;
        }
       else if (selectedDocumentType == 'Trade License') {
          tradeLicenseFile = file.path;
        } else if (selectedDocumentType == 'VAT Certificate') {
          vatCertificateFile = file.path;
        }
        else {
          documentFile = file.path;
        }

      });
    }
  }

  Future<void> captureFile({bool isFront = true}) async {
    if (selectedDocumentType == null) {
      _showSnackBar("Please select a document type first.");
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        if (selectedDocumentType == 'Emirates ID') {
          if (isFront) {
            emiratesIdFrontFile = file.path;
          } else {
            emiratesIdBackFile = file.path;
          }
        } else if (selectedDocumentType == 'Passport') {
          passportFile = file.path;
        } else if (selectedDocumentType == 'Visa') {
          visaFile = file.path;
        }
        else if (selectedDocumentType == 'Trade License') {
          tradeLicenseFile = file.path;
        } else if (selectedDocumentType == 'VAT Certificate') {
          vatCertificateFile = file.path;
        }
        else{
          documentFile = file.path;
        }

      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 16)),
        backgroundColor: appbar_color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),

      ),
    );
  }


// Function to generate a PDF from two images
  Future<File> generatePdf(File frontImage, File backImage) async {
    final pdf = pw.Document();

    final frontImageBytes = frontImage.readAsBytesSync();
    final backImageBytes = backImage.readAsBytesSync();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Image(pw.MemoryImage(frontImageBytes)),
        ),
      ),
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Image(pw.MemoryImage(backImageBytes)),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final pdfFile = File("${output.path}/emirates_id.pdf");
    await pdfFile.writeAsBytes(await pdf.save());

    return pdfFile;
  }
  Future<void> sendFormData(File file, String docType, String expiryDate, {required bool isPdf,  required String documentNumber, required int doc_type_id
  }) async {
    if (!file.existsSync()) {
      print("🚨 No file found.");
      return;
    }

    String url = "$baseurl/tenant/kyc/$user_id";
    print("🔹 Uploading to: $url");

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll({
        "Authorization": "Bearer $Company_Token",
      });


      // Add form fields
      request.fields['doc_type'] = docType;
      request.fields['expiry_date'] = expiryDate;
      request.fields['doc_no'] = documentNumber;
      request.fields['doc_type_id'] = doc_type_id.toString();


      // Attach the file (PDF or Image)
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();

      request.files.add(http.MultipartFile(
        isPdf?'image' : 'image',
        stream,
        length,
        filename: "$docType/${file.path.split('/').last}",
        contentType: isPdf ? MediaType('application', 'pdf') : MediaType('image', 'jpeg'),
      ));

    /*  print("📦 Attached Files:");
      for (var file in request.files) {
        print("🔹 Filename: ${file.filename}");
        print("📦 Field Name: ${file.field}");
        print("📏 Content-Type: ${file.contentType}");
      }*/
      var response = await request.send();

// Read response stream properly
      var responseData = await response.stream.bytesToString();
      final decoded = json.decode(responseData);

      print("✅ Response Status Code: ${response.statusCode}");
      print("📦 Raw Response Data: $responseData");
      /*print("🔹 Headers: ${response.headers}");*/

      if (response.statusCode == 201) {


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message']),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // 👈 Floating style
            margin: EdgeInsets.only(
              bottom: 20,
              left: 16,
              right: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        setState(() {
          if (selectedDocumentType == 'Emirates ID') {
              emiratesIdFrontFile = null;
              emiratesIdBackFile = null;

          } else if (selectedDocumentType == 'Passport') {
            passportFile =  null;
          } else if (selectedDocumentType == 'Visa') {
            visaFile =  null;
          }
          else if (selectedDocumentType == 'Trade License') {
            tradeLicenseFile = null;
          } else if (selectedDocumentType == 'VAT Certificate') {
            vatCertificateFile = null;
          }
          else{
            documentFile = file.path;
          }

          selectedDocumentType = null;

          _selectedExpiryDate = null;
          _expiryDateController.clear();
          documentNoController.clear();
        });

        print("✔ Upload successful");
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message']),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating, // 👈 Floating style
            margin: EdgeInsets.only(
              bottom: 20,
              left: 16,
              right: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        print("❌ Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 Error uploading file: $e");
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _getDocumentNumberLabel() {
    switch (selectedDocumentType) {
      case 'Emirates ID':
        return 'Emirates ID Number';
      case 'Passport':
        return 'Passport Number';
      case 'Visa':
        return 'Visa Number';
      case 'Trade License':
        return 'Trade License Number';
      case 'VAT Certificate':
        return 'VAT Certificate Number';
      default:
        return 'Document Number';
    }
  }

  String _getDocumentNumberHint() {
    switch (selectedDocumentType) {
      case 'Emirates ID':
        return 'e.g. 784-XXXX-XXXXXXX-X';
      case 'Passport':
        return 'Enter Passport Number';
      case 'Visa':
        return 'Enter Visa Number';
      case 'Trade License':
        return 'Enter Trade License Number';
      case 'VAT Certificate':
        return 'Enter VAT Certificate Number';
      default:
        return 'Enter Document Number';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('KYC Update', style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
        backgroundColor: appbar_color.withOpacity(0.9),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: ()
          {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TenantDashboard()),
            );
          }
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Form(

          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<DocumentType>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Document Type",
                  hintText: "Select Document Type",
                  labelStyle: GoogleFonts.poppins(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: appbar_color, width: 1),
                  ),
                ),
                value: selectedDocument,
                items: documentTypes.map((doc) {
                  return DropdownMenuItem<DocumentType>(
                    value: doc,
                  child: Text(
                  doc.isMandatory ? "${doc.name} *" : doc.name,
                    style: GoogleFonts.poppins(),
                  ),
                  );
                }).toList(),
                onChanged: (DocumentType? newValue) {
                  setState(() {
                    selectedDocument = newValue;
                    selectedDocumentType = newValue?.name;
                    _selectedExpiryDate = null;
                    _expiryDateController.clear();
                    documentNoController.clear();
                    emiratesIdFrontFile = emiratesIdBackFile = passportFile = visaFile = null;
                  });
                },
              ),

              SizedBox(height: 15),

              TextFormField(
                controller: documentNoController,
                decoration: InputDecoration(
                  labelText: _getDocumentNumberLabel(),
                  hintText: _getDocumentNumberHint(),

                  labelStyle: TextStyle(
                    color: Colors.black, // 👈 change this to your desired color
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color:appbar_color, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => documentNoController.text = value,
                validator: (value) {
                  if (value == null || value.isEmpty) return '${_getDocumentNumberLabel()} is required';

                  if (selectedDocumentType == 'Emirates ID' && !emiratesIdRegex.hasMatch(value)) {
                    return 'Enter a valid Emirates ID (e.g. 784-XXXX-XXXXXXX-X)';
                  }

                  return null;
                },
              ),


              SizedBox(height: 15),

              TextFormField(
                controller: _expiryDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'e.g dd-MMM-yyyy',
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(
                    color: Colors.black, // 👈 change this to your desired color
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color:appbar_color, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(), // 👈 disables past dates

                      lastDate: DateTime(2100),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: appbar_color, // Header background color
                            onPrimary: Colors.white,    // Header text color
                            onSurface: Colors.black,    // Body text color
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueAccent, // Button text color
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedExpiryDate = picked;
                      _expiryDateController.text = "${picked.day.toString().padLeft(2, '0')}-${_getMonthAbbreviation(picked.month)}-${picked.year}";
                    });
                  }
                },

                validator: (value) {
                  if (value == null || value.isEmpty) return 'Expiry date is required';
                  return null;
                },
              ),

              SizedBox(height: 15),
              if (selectedDocumentType != null)
                Column(
                  children: [
                    if (selectedDocumentType == 'Emirates ID') ...[
                      buildDocumentCard(title: 'Emirates ID - Front', filePath: emiratesIdFrontFile, isFront: true),
                      buildDocumentCard(title: 'Emirates ID - Back', filePath: emiratesIdBackFile, isFront: false),
                    ] else if (selectedDocumentType == 'Passport') ...[
                      buildDocumentCard(title: 'Passport', filePath: passportFile),
                    ] else if (selectedDocumentType == 'Visa') ...[
                      buildDocumentCard(title: 'Visa', filePath: visaFile),
                    ] else if (selectedDocumentType == 'Trade License') ...[
                      buildDocumentCard(title: 'Trade License', filePath: tradeLicenseFile),
                    ] else if (selectedDocumentType == 'Vat Certificate') ...[
                      buildDocumentCard(title: 'Vat Certificate', filePath: vatCertificateFile),
                    ]
                    else ...[
                        buildDocumentCard(title: selectedDocumentType!, filePath: documentFile),
                      ]
                  ],
                ),
              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isUploading
                      ? (Platform.isIOS
                      ? CupertinoActivityIndicator(color: Colors.white)
                      : SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ))
                      : Icon(Icons.send_rounded, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: _isUploading
                      ? null
                      : () async {

                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    if (selectedDocumentType == null) {
                      _showSnackBar("Please select a document type.");
                      return;
                    }

                    setState(() => _isUploading = true);

                    File? fileToSend;
                    String fileType = "";
                    bool isPdf = false;

                    try {
                      switch (selectedDocumentType) {
                        case 'Emirates ID':
                          if (emiratesIdFrontFile == null || emiratesIdBackFile == null) {
                            _showSnackBar("Please upload both front and back of Emirates ID");
                            setState(() => _isUploading = false);
                            return;
                          }

                          fileToSend = await generatePdf(File(emiratesIdFrontFile!), File(emiratesIdBackFile!));
                          if (!fileToSend.existsSync()) {
                            print("🚨 PDF Generation Failed! File does not exist");
                            setState(() => _isUploading = false);
                            return;
                          }

                          print("✅ PDF Generated: ${fileToSend.path}");
                          print("📦 PDF Size: ${await fileToSend.length()} bytes");
                          fileType = "Emirates_Id";
                          isPdf = true;
                          break;

                        case 'Passport':
                          if (passportFile == null) {
                            _showSnackBar("Please upload the Passport");
                            setState(() => _isUploading = false);
                            return;
                          }
                          fileToSend = File(passportFile!);
                          fileType = "Passport";
                          break;

                        case 'Visa':
                          if (visaFile == null) {
                            _showSnackBar("Please upload the Visa");
                            setState(() => _isUploading = false);
                            return;
                          }
                          fileToSend = File(visaFile!);
                          fileType = "Visa";
                          break;

                        case 'Trade License':
                          if (tradeLicenseFile == null) {
                            _showSnackBar("Please upload the Trade License");
                            setState(() => _isUploading = false);
                            return;
                          }
                          fileToSend = File(tradeLicenseFile!);
                          fileType = "Trade_License";
                          break;




                        case 'VAT Certificate':
                          if (vatCertificateFile == null) {
                            _showSnackBar("Please upload the VAT Certificate");
                            setState(() => _isUploading = false);
                            return;
                          }
                          fileToSend = File(vatCertificateFile!);
                          fileType = "VAT_Certificate";
                          break;

                        default :
                          if (documentFile == null) {
                            _showSnackBar("Please upload document");
                            setState(() => _isUploading = false);
                            return;
                          }
                          fileToSend = File(documentFile!);
                          fileType = "VAT_Certificate";
                          return;


                      }

                      if (fileToSend != null) {
                        await sendFormData(
                          fileToSend,
                          fileType,
                          _selectedExpiryDate != null
                              ? "${_selectedExpiryDate!.year}-${_selectedExpiryDate!.month.toString().padLeft(2, '0')}-${_selectedExpiryDate!.day.toString().padLeft(2, '0')}"
                              : "",
                          isPdf: isPdf,
                          documentNumber: documentNoController.text,
                          doc_type_id: selectedDocument!.id
                        );
                      } else {
                        _showSnackBar("Error processing the file.");
                      }
                    } catch (e) {
                      print("❌ Exception during submission: $e");
                      _showSnackBar("Something went wrong. Please try again.");
                    } finally {
                      setState(() => _isUploading = false);
                    }
                  },
                  label: _isUploading
                      ? Text(
                    'Submitting...',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  )
                      : Text(
                    'Submit',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),





            ],
          ),
        ),
      ),
    );
  }

  Widget buildDocumentCard({required String title, required String? filePath, bool isFront = true}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
// Show Image Preview if filePath is available
            filePath != null && File(filePath).existsSync()
                ? Image.file(
              File(filePath),
              width: double.infinity,
              height: 150, // Adjust the height as needed
              fit: BoxFit.cover,
            )
                : Text("No file selected", style: GoogleFonts.poppins(color: Colors.red)),

            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                    onPressed: () => pickFile(isFront: isFront),
                    icon: Icon(Icons.upload, color: Colors.white),
                    label: Text('Upload', style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color, // Change this to your desired color
                    elevation: 2, // Optional: Adds shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Optional: Rounded corners
                    ),
                  ),

                ),
                SizedBox(width: 10),
                ElevatedButton.icon(onPressed: () => captureFile(isFront: isFront),
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    label: Text('Capture', style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color, // Change this to your desired color
                    elevation: 2, // Optional: Adds shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Optional: Rounded corners
                    ),
                  ),),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
