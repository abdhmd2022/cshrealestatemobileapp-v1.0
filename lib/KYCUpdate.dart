import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'constants.dart';

class DecentTenantKYCForm extends StatefulWidget {
  @override
  _DecentTenantKYCFormState createState() => _DecentTenantKYCFormState();
}

class _DecentTenantKYCFormState extends State<DecentTenantKYCForm> {
  final _formKey = GlobalKey<FormState>();
  String? emiratesIdFrontFile, emiratesIdBackFile, passportFile, visaFile;

  Future<void> pickFile(String docType, {bool isFront = true}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (docType == 'Emirates ID') {
          if (isFront) {
            emiratesIdFrontFile = result.files.single.path;
          } else {
            emiratesIdBackFile = result.files.single.path;
          }
        } else if (docType == 'Passport') {
          passportFile = result.files.single.path;
        } else if (docType == 'Visa') {
          visaFile = result.files.single.path;
        }
      });
    }
  }

  Future<void> captureFile(String docType, {bool isFront = true}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        if (docType == 'Emirates ID') {
          if (isFront) {
            emiratesIdFrontFile = file.path;
          } else {
            emiratesIdBackFile = file.path;
          }
        } else if (docType == 'Passport') {
          passportFile = file.path;
        } else if (docType == 'Visa') {
          visaFile = file.path;
        }
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Update', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: appbar_color.withOpacity(0.9),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Container(
          color: Colors.white,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child:  Container(
                    padding: EdgeInsets.only(top:0),
                    child:Row(
                      children: [

                        Row(mainAxisSize: MainAxisSize.min,

                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            Container(
                                margin: EdgeInsets.only(left: 10,right: 5, top: 0),
                                padding: EdgeInsets.only(left:0,right:10, top: 5, bottom: 5),
                                decoration: BoxDecoration(
                                  color: appbar_color.withOpacity(0.1),

                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child:Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.circleUser,
                                      color: appbar_color.withOpacity(1),
                                      size: 20,

                                    ),
                                    SizedBox(width: 8,),
                                    Text("widget.name",
                                        style: TextStyle(
                                          color: appbar_color.withOpacity(1),
                                          fontWeight: FontWeight.bold,

                                        ))

                                  ],
                                )
                            ),

                            Container(
                                margin: EdgeInsets.only(left: 0,right: 5, top: 0),
                                padding: EdgeInsets.only(left:10,right:10, top: 5, bottom: 5),
                                decoration: BoxDecoration(

                                  color: appbar_color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child:Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.envelope ,
                                      color: appbar_color.withOpacity(1),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8,),
                                    Text("widget.email",
                                        style: TextStyle(
                                            color: appbar_color.withOpacity(1),
                                            fontWeight: FontWeight.bold
                                        ))
                                  ],
                                )
                            ),
                          ],),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 15,),


                buildDocumentCard(
                  title: 'Emirates ID Front',
                  filePath: emiratesIdFrontFile,
                  onPickFile: () => pickFile('Emirates ID', isFront: true),
                  onCaptureFile: () => captureFile('Emirates ID', isFront: true),
                ),
                buildDocumentCard(
                  title: 'Emirates ID Back',
                  filePath: emiratesIdBackFile,
                  onPickFile: () => pickFile('Emirates ID', isFront: false),
                  onCaptureFile: () => captureFile('Emirates ID', isFront: false),
                ),
                buildDocumentCard(
                  title: 'Passport',
                  filePath: passportFile,
                  onPickFile: () => pickFile('Passport'),
                  onCaptureFile: () => captureFile('Passport'),
                ),
                buildDocumentCard(
                  title: 'Visa',
                  filePath: visaFile,
                  onPickFile: () => pickFile('Visa'),
                  onCaptureFile: () => captureFile('Visa'),
                ),
                SizedBox(height: 30),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: appbar_color),
                    onPressed: () {
                      if (emiratesIdFrontFile == null || emiratesIdFrontFile!.isEmpty) {
                        _showSnackBar("Please upload Emirates ID front side.");
                      } else if (emiratesIdBackFile == null || emiratesIdBackFile!.isEmpty) {
                        _showSnackBar("Please upload Emirates ID back side.");
                      } else if (passportFile == null || passportFile!.isEmpty) {
                        _showSnackBar("Please upload Passport.");
                      } else if (visaFile == null || visaFile!.isEmpty) {
                        _showSnackBar("Please upload Visa.");
                      } else {
                        // Proceed with submission
                      }
                    },
                    child: Text('Submit', style: TextStyle(color: Colors.white)),
                  ),
                )

              ],
            ),
          ),
        )

      ),
    );
  }

  Widget buildDocumentCard({
    required String title,
    required String? filePath,
    required VoidCallback onPickFile,
    required VoidCallback onCaptureFile,
  }) {
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
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            filePath != null ? Text("Uploaded: $filePath") : Text("No file selected"),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: onPickFile, icon: Icon(Icons.upload,color: appbar_color,), label: Text('Upload',style: TextStyle(color: appbar_color),)),
                SizedBox(width: 10),
                ElevatedButton.icon(                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: onCaptureFile, icon: Icon(Icons.camera_alt,color: appbar_color,), label: Text('Capture',style: TextStyle(color: appbar_color))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
