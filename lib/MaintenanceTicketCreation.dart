import 'dart:io';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

class MaintenanceTicketCreation extends StatefulWidget
{
  const MaintenanceTicketCreation({Key? key}) : super(key: key);
  @override
  _MaintenanceTicketCreationPageState createState() => _MaintenanceTicketCreationPageState();
}

class _MaintenanceTicketCreationPageState extends State<MaintenanceTicketCreation> {

  String? selectedMaintenanceType; // To store the selected dropdown value
  final List<String> maintenance_types_list = [
    'Electrical Works',
    'A/C Works',
    'Plumbing Works',
    'Paint Works',
    'Pest Control',
    'Tile Works',
    'Others'
  ];

  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _totalamountController = TextEditingController();

  List<File> _attachment = []; // List to store selected images
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages(ImageSource source) async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(); // Pick multiple images
    if (pickedFiles != null) {
      setState(() {
        // Add all selected images to the attachments list
        _attachment.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }


  void _showAttachmentOptions() {
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
                      _pickImages(ImageSource.gallery); // Open gallery to pick multiple images
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
                      _pickImages(ImageSource.gallery); // Open gallery to pick multiple images
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

    selectedMaintenanceType = maintenance_types_list.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: appbar_color,

          leading: GestureDetector(
            onTap: ()
            {
              Navigator.of(context).pop();
            },
            child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),

          title: Text('Maintenance Ticket',
            style: TextStyle(
                color: Colors.white
            ),),
        ),
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

                    /*Container(
                      margin: EdgeInsets.only(left: 20,right: 20,bottom: 3,top: 20),
                      child: Text("Ticket Creation",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28
                      ),)
                    ),

                    Container(
                      margin: EdgeInsets.only(left: 20,right: 20,bottom: 30),
                      child: Text("Create your maintenance ticket",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54
                      ),),
                    ),*/

                    Card(
                        surfaceTintColor: Theme.of(context).colorScheme.surface,
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
                                        'Name',
                                        style: TextStyle(fontSize: 16,
                                            color: Colors.black54),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 30,),

                                  Column(
                                    children: [
                                      Icon(
                                        Icons.hardware_outlined,
                                        color: Colors.black54,
                                      ),
                                      SizedBox(height: 2), // Add space between icon and text
                                      Text(
                                        'Status',
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
                                        'Unit No',
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
                                        Icons.apartment,
                                        color: Colors.black54,
                                      ),
                                      SizedBox(height: 2), // Add space between icon and text
                                      Text(
                                        'Building',
                                        style: TextStyle(fontSize: 16,
                                            color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ],)
                              ,),
                          ],))
                      ),

                    Container(
                      margin: EdgeInsets.only(left: 20,right: 20,top: 30),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only( top:0,
                              bottom: 5,
                              left: 0,
                              right: 20),
                          child: Row(
                            children: [
                              Text("Maintenance Type:",
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

                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          margin: EdgeInsets.only(left: 00,right: 0,bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          ),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: InputBorder.none, // Remove default border
                              contentPadding: EdgeInsets.zero, // Remove extra padding
                            ),
                            value: selectedMaintenanceType, // Replace with your variable
                            hint: Text('Select an option'),
                            items: maintenance_types_list.map((String item) { // Replace 'items' with your list
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedMaintenanceType = newValue; // Replace with your state logic
                              });
                            },
                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),),

                    Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[

                          Container(
                            margin: EdgeInsets.only( top:0,
                                bottom: 5,
                                left: 20,
                                right: 20),
                            child: Row(
                              children: [
                                Text("Description:",
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

                          Container(
                              margin: EdgeInsets.only(
                                  top:0,
                                  bottom: 0,
                                  left: 20,
                                  right: 20
                              ),
                              child: TextFormField(
                                  controller: _descriptionController,
                                  keyboardType: TextInputType.multiline,
                                  maxLength: 500, // Limit input to 500 characters
                                  maxLines: 3, // A
                                  decoration: InputDecoration(
                                    hintText: 'Enter Description',
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

                          Container(
                            margin: EdgeInsets.only(left: 20, right: 20),
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
        margin: EdgeInsets.only(left:20,right: 20),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_attachment.isNotEmpty)
            Column(
              children: [
                Row(
                  children: _attachment
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
                  onPressed: _showAttachmentOptions, // Trigger image picker
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
              onPressed: _showAttachmentOptions, // Trigger image picker
              child: Icon(
                Icons.attach_file,
                size: 30, // Icon size
                color: Colors.blueAccent, // Icon color
              ),
            ),
          SizedBox(height: 20),

          Text('No attachment selected'),

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
