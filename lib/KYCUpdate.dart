import 'dart:convert';
import 'dart:io';

import 'package:cshrealestatemobile/SalesDashboard.dart';
import 'package:cshrealestatemobile/TenantDashboard.dart';
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
  String? selectedDocumentType;
  String? emiratesIdFrontFile, emiratesIdBackFile, passportFile, visaFile;

  final List<String> documentTypes = ['Emirates ID', 'Passport', 'Visa'];


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
  Future<void> sendFormData(File file, String docType, String expiryDate, {required bool isPdf}) async {
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

          selectedDocumentType = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Document Type",
                    hintText: "Select Document Type",
                    labelStyle: GoogleFonts.poppins(color: Colors.black), // Set label text color to blue
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Default border color
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1), // Blue border when not focused
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color, width: 1), // Thicker blue border when focused
                    ),
                  ),
                  value: selectedDocumentType,
                  items: documentTypes.map((String doc) {
                    return DropdownMenuItem<String>(
                      value: doc,
                      child: Text(doc),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDocumentType = newValue;
                      emiratesIdFrontFile = emiratesIdBackFile = passportFile = visaFile = null;
                    });
                  },
                ),
                SizedBox(height: 15),
                if (selectedDocumentType != null)
                  Column(
                    children: [
                      if (selectedDocumentType == 'Emirates ID') ...[
                        buildDocumentCard(title: 'Emirates ID - Front', filePath: emiratesIdFrontFile, isFront: true),
                        buildDocumentCard(title: 'Emirates ID - Back', filePath: emiratesIdBackFile, isFront: false),
                      ] else
                        buildDocumentCard(title: selectedDocumentType!, filePath: selectedDocumentType == 'Passport' ? passportFile : visaFile),
                    ],
                  ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: appbar_color),
                    onPressed: () async {
                    if (selectedDocumentType == null) {
                    _showSnackBar("Please select a document type.");
                    return;
                    }

                    File? fileToSend;
                    String fileType = "";
                    String date = "2023-10-25"; // Modify as needed
                    bool isPdf = false;

                    switch (selectedDocumentType) {
                    case 'Emirates ID':
                    if (emiratesIdFrontFile == null || emiratesIdBackFile == null) {
                    _showSnackBar("Please upload both front and back of Emirates ID");
                    return;
                    }

                    // Convert front and back images into a PDF
                    fileToSend = await generatePdf(File(emiratesIdFrontFile!), File(emiratesIdBackFile!));
                    if (!fileToSend.existsSync()) {
                      print("🚨 PDF Generation Failed! File does not exist");
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
                    return;
                    }
                    fileToSend = File(passportFile!);
                    fileType = "Passport";
                    break;

                    case 'Visa':
                    if (visaFile == null) {
                    _showSnackBar("Please upload the Visa");
                    return;
                    }
                    fileToSend = File(visaFile!);
                    fileType = "Visa";
                    break;

                    default:
                    _showSnackBar("Invalid document type selected.");
                    return;
                    }

                    if (fileToSend != null) {
                    await sendFormData(fileToSend, fileType, date, isPdf: isPdf);
                    } else {
                    _showSnackBar("Error processing the file.");
                    }
                    },
                    child: Text('Submit', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                )

              ],
            ),
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
