import 'dart:io';
import 'package:cshrealestatemobile/SalesDashboard.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import 'Sidebar.dart';

class kycUpdate extends StatefulWidget
{
  const kycUpdate({Key? key}) : super(key: key);
  @override
  _kycUpdatePageState createState() => _kycUpdatePageState();
}

class _kycUpdatePageState extends State<kycUpdate> with TickerProviderStateMixin {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoRoleFound = false;

  String name = "",email = "";


  List<File> EID_attachment = []; // List to store eid images

  List<File> passport_attachment = []; // List to store passport images

  List<File> visa_attachment = []; // List to store visa images

  final ImagePicker eid_picker = ImagePicker();

  final ImagePicker passport_picker = ImagePicker();

  final ImagePicker visa_picker = ImagePicker();

  Future<void> _pickEIDImages(ImageSource source) async {
    final List<XFile>? pickedFiles = await eid_picker.pickMultiImage(); // Pick multiple images
    if (pickedFiles != null) {
      setState(() {
        // Add all selected images to the attachments list
        EID_attachment.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  Future<void> _pickpassportImages(ImageSource source) async {
    final List<XFile>? pickedFiles = await passport_picker.pickMultiImage(); // Pick multiple images
    if (pickedFiles != null) {
      setState(() {
        // Add all selected images to the attachments list
        passport_attachment.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  Future<void> _pickvisaImages(ImageSource source) async {
    final List<XFile>? pickedFiles = await visa_picker.pickMultiImage(); // Pick multiple images
    if (pickedFiles != null) {
      setState(() {
        // Add all selected images to the attachments list
        visa_attachment.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }


  void _showEIDAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16,top: 20,right: 20,bottom: 50),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickEIDImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.upload, size: 40, color: Colors.blueAccent),
                        ),
                        SizedBox(height: 8),
                        Text('Upload'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickEIDImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.camera_alt, size: 40, color: Colors.blueAccent),
                        ),
                        SizedBox(height: 8),
                        Text('Capture'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPassportAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16,top: 20,right: 20,bottom: 50),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickpassportImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.upload, size: 40, color: Colors.blueAccent),
                        ),
                        SizedBox(height: 8),
                        Text('Upload'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickpassportImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.camera_alt, size: 40, color: Colors.blueAccent),
                        ),
                        SizedBox(height: 8),
                        Text('Capture'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVisaAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16,top: 20,right: 20,bottom: 50),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickvisaImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.upload, size: 40, color: Colors.blueAccent),
                        ),
                        SizedBox(height: 8),
                        Text('Upload'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickvisaImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.camera_alt, size: 40, color: Colors.blueAccent),
                        ),
                        SizedBox(height: 8),
                        Text('Capture'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /*void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Control the height based on content
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16,top: 20,right: 20,bottom: 50),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.upload, size: 40, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Upload'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.camera_alt, size: 40, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Capture'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }*/

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: appbar_color,
          automaticallyImplyLeading: false,

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

          title: Text('KYC Update',
            style: TextStyle(
                color: Colors.white
            ),),
        ),

        drawer: Sidebar(
            isDashEnable: isDashEnable,
            isRolesVisible: isRolesVisible,
            isRolesEnable: isRolesEnable,
            isUserEnable: isUserEnable,
            isUserVisible: isUserVisible,
            Username: name,
            Email: email,
            tickerProvider: this),

        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            /*decoration:BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Color(0xFFD9FCF6),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
              ),
            ),*/
            child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Card(
                          surfaceTintColor: Colors.blueGrey,
                          elevation: 10,
                          margin: EdgeInsets.only(left: 20,right: 20, top: 20),
                          child:  Container(
                              padding: EdgeInsets.all(20),
                              child:Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 5,),
                                    child:Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color: Colors.black54,
                                            ),
                                            SizedBox(height: 2), // Add space between icon and text
                                            Text(
                                              'Saadan',
                                              style: TextStyle(fontSize: 16,
                                                  color: Colors.black54),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 30,),

                                        Column(
                                          children: [
                                            Icon(
                                              Icons.apartment,
                                              color: Colors.black54,
                                            ),
                                            SizedBox(height: 2), // Add space between icon and text
                                            Text(
                                              'Al Khaleej Center',
                                              style: TextStyle(fontSize: 16,
                                                  color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ],)
                                    ,),

                                  SizedBox(width: MediaQuery.of(context).size.width/5,),
                                  Container(
                                    margin: EdgeInsets.only(bottom: 5,),
                                    child:Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.home_filled,
                                              color: Colors.black54,
                                            ),
                                            SizedBox(height: 2), // Add space between icon and text
                                            Text(
                                              '101',
                                              style: TextStyle(fontSize: 16,
                                                  color: Colors.black54),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 30,),

                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.public,
                                              color: Colors.black54,
                                            ),
                                            SizedBox(height: 2), // Add space between icon and text
                                            Text(
                                              'Dubai',
                                              style: TextStyle(fontSize: 16,
                                                  color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ],)
                                    ,),
                                ],))
                      ),


                      Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            SizedBox(height: 20,),
                            Container(
                              margin: EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                children: [
                                  Text(
                                    'Emirates ID',
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
                              margin: EdgeInsets.only(left:20,right: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [


                                  if (EID_attachment.isNotEmpty)
                                    Column(
                                      children: [
                                        Row(
                                          children: EID_attachment
                                              .map((attachment) => Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.file(
                                              attachment,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ))
                                              .toList(),
                                        ),
                                        SizedBox(height: 10),
                                        // Plus icon to add more images

                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(), // Makes the button round
                                            padding: EdgeInsets.all(16), // Adds padding around the icon
                                            elevation: 5, // Adds elevation for the shadow effect
                                            backgroundColor: Colors.white, // Button background color
                                          ),
                                          onPressed: _showEIDAttachmentOptions, // Trigger image picker
                                          child: Icon(
                                            Icons.add,
                                            size: 30, // Icon size
                                            color: Colors.blueAccent, // Icon color
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(), // Makes the button round
                                        padding: EdgeInsets.all(16), // Adds padding around the icon
                                        elevation: 5, // Adds elevation for the shadow effect
                                        backgroundColor: Colors.white, // Button background color
                                      ),
                                      onPressed: _showEIDAttachmentOptions, // Trigger image picker
                                      child: Icon(
                                        Icons.attach_file,
                                        size: 30, // Icon size
                                        color: Colors.blueAccent, // Icon color
                                      ),
                                    ),


                                ],
                              ),),
                          ]),

                      SizedBox(height: 20,),

                      Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[

                            Container(
                              margin: EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                children: [
                                  Text(
                                    'Passport',
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
                              margin: EdgeInsets.only(left:20,right: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (passport_attachment.isNotEmpty)
                                    Column(
                                      children: [
                                        Row(
                                          children: passport_attachment
                                              .map((attachment) => Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.file(
                                              attachment,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ))
                                              .toList(),
                                        ),
                                        SizedBox(height: 10),
                                        // Plus icon to add more images

                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(), // Makes the button round
                                            padding: EdgeInsets.all(16), // Adds padding around the icon
                                            elevation: 5, // Adds elevation for the shadow effect
                                            backgroundColor: Colors.white, // Button background color
                                          ),
                                          onPressed: _showPassportAttachmentOptions, // Trigger image picker
                                          child: Icon(
                                            Icons.add,
                                            size: 30, // Icon size
                                            color: Colors.blueAccent, // Icon color
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(), // Makes the button round
                                        padding: EdgeInsets.all(16), // Adds padding around the icon
                                        elevation: 5, // Adds elevation for the shadow effect
                                        backgroundColor: Colors.white, // Button background color
                                      ),
                                      onPressed: _showEIDAttachmentOptions, // Trigger image picker
                                      child: Icon(
                                        Icons.attach_file,
                                        size: 30, // Icon size
                                        color: Colors.blueAccent, // Icon color
                                      ),
                                    ),


                                ],
                              ),),
                          ]),

                      SizedBox(height: 20,),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[

                            Container(
                              margin: EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                children: [
                                  Text(
                                    'Visa Copy',
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
                              margin: EdgeInsets.only(left:20,right: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (visa_attachment.isNotEmpty)
                                    Column(
                                      children: [
                                        Row(
                                          children: visa_attachment
                                              .map((attachment) => Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.file(
                                              attachment,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ))
                                              .toList(),
                                        ),
                                        SizedBox(height: 10),
                                        // Plus icon to add more images

                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(), // Makes the button round
                                            padding: EdgeInsets.all(16), // Adds padding around the icon
                                            elevation: 5, // Adds elevation for the shadow effect
                                            backgroundColor: Colors.white, // Button background color
                                          ),
                                          onPressed: _showPassportAttachmentOptions, // Trigger image picker
                                          child: Icon(
                                            Icons.add,
                                            size: 30, // Icon size
                                            color: Colors.blueAccent, // Icon color
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(), // Makes the button round
                                        padding: EdgeInsets.all(16), // Adds padding around the icon
                                        elevation: 5, // Adds elevation for the shadow effect
                                        backgroundColor: Colors.white, // Button background color
                                      ),
                                      onPressed: _showVisaAttachmentOptions, // Trigger image picker
                                      child: Icon(
                                        Icons.attach_file,
                                        size: 30, // Icon size
                                        color: Colors.blueAccent, // Icon color
                                      ),
                                    ),


                                ],
                              ),),
                          ]),

                      /*  SizedBox(height: 10),

                    Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[

                          Container(
                            margin: EdgeInsets.only(
                                top:0,
                                bottom: 2,
                                left: 20,
                                right: 20
                            ),
                            child: Text("Total Amount:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16

                                )
                            ),),

                          Container(
                              margin: EdgeInsets.only(
                                  top:0,
                                  bottom: 20,
                                  left: 20,
                                  right: 20
                              ),
                              child: TextField(
                                  controller: _totalamountController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,

                                  decoration: InputDecoration(
                                    hintText: 'Enter Amount',
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10), // Set the border radius
                                      borderSide: BorderSide(
                                        color: Colors.black, // Set the border color
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:  Colors.black, // Set the focused border color
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ))),
                        ]),*/

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

                            }
                          },
                          child: Text('Submit',
                              style: TextStyle(
                                  color: Colors.white
                              )),
                        ),)
                    ])
            )
        )
    );}}
