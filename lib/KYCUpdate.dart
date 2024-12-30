import 'package:cshrealestatemobile/SalesDashboard.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'constants.dart';

class DecentTenantKYCForm extends StatefulWidget {
  @override
  _DecentTenantKYCFormState createState() => _DecentTenantKYCFormState();
}

class _DecentTenantKYCFormState extends State<DecentTenantKYCForm> {
  final _formKey = GlobalKey<FormState>();
  String? emiratesIdFile, passportFile, visaCopyFile;

  Future<void> pickFile(String docType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (docType == 'Emirates ID') {
          emiratesIdFile = result.files.single.path;
        } else if (docType == 'Passport') {
          passportFile = result.files.single.path;
        } else if (docType == 'Visa Copy') {
          visaCopyFile = result.files.single.path;
        }
      });
    }
  }

  Future<void> captureFile(String docType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        if (docType == 'Emirates ID') {
          emiratesIdFile = file.path;
        } else if (docType == 'Passport') {
          passportFile = file.path;
        } else if (docType == 'Visa Copy') {
          visaCopyFile = file.path;
        }
      });
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(fontSize: 16),
      ),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating, // Makes the SnackBar float above the screen
      margin: EdgeInsets.all(16), // Adds margin around the SnackBar
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Update', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 1,
        backgroundColor: appbar_color,
        iconTheme: IconThemeData(color: Colors.white),

        leading: GestureDetector(
          onTap: ()
          {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SalesDashboard()),
            );
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left:10.0,right: 10,bottom: 16),
        child: Column(
          children: [
            Card
              (
                color: Colors.white,
                surfaceTintColor: Colors.blueGrey,
                elevation: 10,
                margin: EdgeInsets.only(left: 20,right: 20, top: 20),
                child:  Container(
                    padding: EdgeInsets.all(20),
                    child:Column(

                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 5,),
                              child:Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Colors.blueGrey,
                                      ),
                                      SizedBox(height: 2), // Add space between icon and text
                                      Text(
                                        'Saadan',
                                        style: TextStyle(fontSize: 16,
                                            color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                ],)
                              ,),

                            SizedBox(width: MediaQuery.of(context).size.width/5,),
                            Container(
                              margin: EdgeInsets.only(bottom: 5,),
                              child:Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        color: Colors.blueGrey,
                                      ),
                                      SizedBox(height: 2), // Add space between icon and text
                                      Text(
                                        '+971 500000000',
                                        style: TextStyle(fontSize: 16,
                                            color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),


                                ],)
                              ,),
                          ],),

                        SizedBox(height: 30,),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.blueGrey,
                            ),
                            SizedBox(height: 2), // Add space between icon and text
                            Text(
                              'saadan@ca-eim.com',
                              style: TextStyle(fontSize: 16,
                                  color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ],
                    )
                )
            ),

            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  buildDocumentCard(
                    title: 'Emirates ID',
                    filePath: emiratesIdFile,
                    onPickFile: () => pickFile('Emirates ID'),
                    onCaptureFile: () => captureFile('Emirates ID'),
                  ),
                  buildDocumentCard(
                    title: 'Passport',
                    filePath: passportFile,
                    onPickFile: () => pickFile('Passport'),
                    onCaptureFile: () => captureFile('Passport'),
                  ),
                  buildDocumentCard(
                    title: 'Visa Copy',
                    filePath: visaCopyFile,
                    onPickFile: () => pickFile('Visa Copy'),
                    onCaptureFile: () => captureFile('Visa Copy'),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.only(left: 20,right: 20,top: 20,bottom: 80),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appbar_color,
                        elevation: 5, // Adjust the elevation to make it look elevated
                        shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                      ),
                      onPressed: () {
                        {
                          if (emiratesIdFile!.isEmpty) {
                            _showSnackBar("Please upload Emirates ID.");
                          } else if (passportFile!.isEmpty) {
                            _showSnackBar("Please upload Passport.");
                          } else if (visaCopyFile!.isEmpty) {
                            _showSnackBar("Please upload Visa Copy.");
                          } else {
                            // Proceed with form submission

                          }
                        }
                      },
                      child: Text('Submit',
                          style: TextStyle(
                              color: Colors.white
                          )),
                    ),),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCustomerDetailsCard({
    required String name,
    required String email,
    required String contact,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Customer Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          buildDetailRow(Icons.person, name),
          buildDetailRow(Icons.email, email),
          buildDetailRow(Icons.phone, contact),
        ],
      ),
    );
  }

  Widget buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 16),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            filePath != null
                ? Row(
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filePath,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (title == 'Emirates ID') {
                        emiratesIdFile = null;
                      } else if (title == 'Passport') {
                        passportFile = null;
                      } else if (title == 'Visa Copy') {
                        visaCopyFile = null;
                      }

                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            )
                : const Text(
              'No file selected',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                _buildDecentButton(
                  'Upload',
                  Icons.upload,
                  Colors.blueAccent,
                    onPickFile
                ),

                SizedBox(width: 10),

                _buildDecentButton(
                    'Capture',
                    Icons.camera_alt_outlined,
                    Colors.deepOrange,
                    onCaptureFile
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDecentButton(
    String label, IconData icon, Color color, VoidCallback onPressed) {
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
