import 'package:cshrealestatemobile/AdminDashboard.dart';
import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'SalesInquiryReport.dart';
import 'Sidebar.dart';
import 'package:google_fonts/google_fonts.dart';

class TenantmoveinoutRequest extends StatefulWidget
{
  @override
  _TenantmoveinoutRequestPageState createState() => _TenantmoveinoutRequestPageState();
}

class _TenantmoveinoutRequestPageState extends State<TenantmoveinoutRequest> with TickerProviderStateMixin {

  String? selectedType; // To store the selec// ted dropdown value
  final List<String> request_type = [
    'Move In',
    'Move Out',
  ];

  TextEditingController _remarksController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoRoleFound = false;

  String name = "",email = "";

  /*List<File> _attachment = []; // List to store selected images
  final ImagePicker _picker = ImagePicker();*/

  /*Future<void> _pickImages(ImageSource source) async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(); // Pick multiple images
    if (pickedFiles != null) {
      setState(() {
        // Add all selected images to the attachments list
        _attachment.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }*/


  /*void _showAttachmentOptions() {
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
  }*/

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
          backgroundColor: appbar_color.withOpacity(0.9),
          automaticallyImplyLeading: false,

          leading: GestureDetector(
            onTap: ()
            {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TenantDashboard()),
              );
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),),

          title: Text('Move In/Out',
            style: GoogleFonts.poppins(
                color: Colors.white
            ),),
        ),

        drawer: Sidebar(
            isDashEnable: isDashEnable,
            isRolesVisible: isRolesVisible,
            isRolesEnable: isRolesEnable,
            isUserEnable: isUserEnable,
            isUserVisible: isUserVisible,
            ),

        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration:BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
              ),
            ),
            child: SingleChildScrollView(
                child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: Form(
                        key: _formKey,
                        child: ListView(
                            children: [
                              Stack(
                                children: [
                                  Card(
                                    surfaceTintColor: appbar_color,
                                    elevation: 10,
                                    margin: EdgeInsets.only(left: 20, right: 20, top: 20),
                                    child: Container(
                                      padding: EdgeInsets.all(20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(bottom: 5),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.all(8), // Add margin around the icon
                                                      child: Icon(
                                                        Icons.person,
                                                        color: appbar_color,
                                                        size: 30, // Adjust size for better look
                                                      ),
                                                    ),
                                                    SizedBox(height: 2), // Space between icon and text
                                                    Text(
                                                      "Saadan",
                                                      style: GoogleFonts.poppins(fontSize: 16, color: appbar_color),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 30),
                                                Column(
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.all(8), // Add margin around the icon
                                                      child: Icon(
                                                        Icons.apartment,
                                                        color: appbar_color,
                                                        size: 30, // Adjust size for better look
                                                      ),
                                                    ),
                                                    SizedBox(height: 2), // Space between icon and text
                                                    Text(
                                                      "Al Khaleej Center",
                                                      style: GoogleFonts.poppins(fontSize: 16, color: appbar_color),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: MediaQuery.of(context).size.width / 5),
                                          Container(
                                            margin: EdgeInsets.only(bottom: 5),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.all(8), // Add margin around the icon
                                                      child: Icon(
                                                        Icons.home,
                                                        color: appbar_color,
                                                        size: 30, // Adjust size for better look
                                                      ),
                                                    ),
                                                    SizedBox(height: 2), // Space between icon and text
                                                    Text(
                                                      '101',
                                                      style: GoogleFonts.poppins(fontSize: 16, color: appbar_color),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 30),
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.all(8), // Add margin around the icon
                                                      child: Icon(
                                                        Icons.public,
                                                        color: appbar_color,
                                                        size: 30, // Adjust size for better look
                                                      ),
                                                    ),
                                                    SizedBox(height: 2), // Space between icon and text
                                                    Text(
                                                      "Dubai",
                                                      style: GoogleFonts.poppins(fontSize: 16, color: appbar_color),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 30,
                                    right: 30,
                                    child: IconButton(
                                      icon: Icon(Icons.edit, color: appbar_color),
                                      onPressed: () {
                                        // Add your edit functionality here
                                        print('Edit icon pressed');
                                      },
                                    ),
                                  ),
                                ],
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
                                          Text("Request Type:",
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16

                                              )
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
                                        value: selectedType, // Replace with your variable
                                        hint: Text('Select Type'),

                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Type is required'; // Custom error message
                                          }
                                          return null;
                                        },

                                        items: request_type.map((String item) { // Replace 'items' with your list
                                          return DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(item),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedType = newValue; // Replace with your state logic
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
                                          Text("Remarks:",
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16

                                              )
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
                                        margin: EdgeInsets.only(
                                            top:0,
                                            bottom: 0,
                                            left: 20,
                                            right: 20
                                        ),
                                        child: TextFormField(
                                            controller: _remarksController,
                                            keyboardType: TextInputType.multiline,
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Remarks are required';
                                              }
                                              return null;
                                            },
                                            maxLength: 500, // Limit input to 500 characters
                                            maxLines: 3, // A
                                            decoration: InputDecoration(
                                              hintText: 'Enter Remarks',
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
                                            style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontSize: 15,
                                            ))),



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
                                style: GoogleFonts.poppins(
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
                                  style: GoogleFonts.poppins(
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

                                    if (_formKey.currentState != null &&
                                        _formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();



                                    }},
                                  child: Text('Submit',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white
                                      )),
                                ),)

                            ]))
                )

            )
        )
    );}}
