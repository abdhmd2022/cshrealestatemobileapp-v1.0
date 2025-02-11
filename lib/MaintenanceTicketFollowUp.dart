import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'MaintenanceTicketReport.dart';
import 'constants.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MaintenanceFollowUpScreen(),
  ));
}

class MaintenanceFollowUpScreen extends StatefulWidget {
  @override
  _MaintenanceFollowUpScreenState createState() => _MaintenanceFollowUpScreenState();
}

class _MaintenanceFollowUpScreenState extends State<MaintenanceFollowUpScreen> {
  List<Map<String, String>> followUps = [
    {"role": "Created", "description": "Ticket created"},
    {"role": "Supervisor", "description": "Checked and approved"},
    {"role": "Technician", "description": "Work in progress"},
    //{"role": "Technician", "description": "Work Completed"},
    //{"role": "Closed", "description": "Ticket closed"},



  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        automaticallyImplyLeading: false,
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

              SizedBox(height: 16),
              Container(
                margin: EdgeInsets.only(left: 0, right: 20),
                child: Row(
                  children: [
                    Text(
                      'Attachments',
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

              SizedBox(height: 20),

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
              SizedBox(height: 16),


              Padding(
                padding: EdgeInsets.only(top: 10),
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


              SizedBox(height: 20),
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


                          },
                          child: Text('Submit'),
                        ),
                      ],)
                ),)
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
