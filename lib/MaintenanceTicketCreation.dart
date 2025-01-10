import 'dart:io';
import 'package:cshrealestatemobile/MaintenanceTicketReport.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'Sidebar.dart';

class MaintenanceTicketCreation extends StatefulWidget
{
  const MaintenanceTicketCreation({Key? key}) : super(key: key);
  @override
  _MaintenanceTicketCreationPageState createState() => _MaintenanceTicketCreationPageState();
}

class _MaintenanceTicketCreationPageState extends State<MaintenanceTicketCreation> with TickerProviderStateMixin {

  List<String> selectedMaintenanceTypes = [];

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoRoleFound = false;

  String name = "",email = "";

  bool selectAll = false;

  // Function to toggle Select All option
  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      if (selectAll) {
        selectedMaintenanceTypes = List<String>.from(maintenance_types_list);
      } else {
        selectedMaintenanceTypes.clear();
      }
    });
  }


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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

        backgroundColor: const Color(0xFFF2F4F8),
        appBar: AppBar(
          backgroundColor: appbar_color,
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

          title: Text('Maintenance Ticket',
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
                        surfaceTintColor: Colors.white,
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
                                                Icons.home_filled,
                                                color: Colors.blueGrey,
                                              ),
                                              SizedBox(height: 2), // Add space between icon and text
                                              Text(
                                                '101',
                                                style: TextStyle(fontSize: 16,
                                                    color: Colors.blueGrey),
                                              ),
                                            ],
                                          ),

                                          SizedBox(width: MediaQuery.of(context).size.width / 5,),

                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.apartment,
                                                color: Colors.blueGrey,
                                              ),
                                              SizedBox(height: 2), // Add space between icon and text
                                              Text(
                                                'Al Khaleej Center',
                                                style: TextStyle(fontSize: 16,
                                                    color: Colors.blueGrey),
                                              ),
                                            ],
                                          ),
                                        ],)
                                      ,),
                                  ],),
                                SizedBox(height: 10,),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,

                                        children: [

                                        _buildDecentButton('Edit',
                                            Icons.edit,
                                            Colors.blueGrey.shade300,
                                                ()
                                            {

                                            })
                                      ],)
                              ],
                            ),
                            )
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
                          margin: EdgeInsets.only(left: 0, right: 0, bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 0.75),
                          ),
                          child: MultiSelectDialogField(

                            items: maintenance_types_list
                                .map((type) => MultiSelectItem<String>(type, type))
                                .toList(),
                            initialValue: selectedMaintenanceTypes,
                            title: Text("Maintenance Type(s)"),
                            searchable: true,
                            selectedColor: Colors.blueGrey,
                            confirmText: Text(
                              "Confirm",
                              style: TextStyle(color: Colors.blueGrey), // Custom confirm button text color
                            ),
                            cancelText: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.blueGrey), // Custom cancel button text color
                            ),
                            buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                            buttonText: Text(
                              "Select Maintenance Type(s)",
                              style: TextStyle(color: Colors.black54, fontSize: 16),
                            ),
                            onConfirm: (values) {
                              setState(() {
                                selectedMaintenanceTypes = List<String>.from(values);
                              });
                            },
                            chipDisplay: MultiSelectChipDisplay(
                              onTap: (value) {
                                setState(() {
                                  selectedMaintenanceTypes.remove(value);
                                });
                              },
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                            ),
                            // We manage Select All outside of MultiSelectDialogField
                          ),
                        )
                        /* Container(
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
                        ),*/
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
                                    filled: true,
                                    fillColor: Colors.white,
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
                            SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
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
                                ),),

    SizedBox(height: 10),

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
                                  Column(
                                    children: [ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(), // Makes the button round
                                        padding: EdgeInsets.all(16), // Adds padding around the icon
                                        elevation: 8, // Adds elevation for the shadow effect
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

                                      Text('No attachment selected'),],
                                  ),
                              ],
                            ),)



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
