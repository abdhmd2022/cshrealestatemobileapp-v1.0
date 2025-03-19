import 'dart:io';
import 'package:cshrealestatemobile/MaintenanceTicketReport.dart';
import 'package:cshrealestatemobile/SalesDashboard.dart';
import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Sidebar.dart';

class TenantComplaint extends StatefulWidget
{
  const TenantComplaint({Key? key}) : super(key: key);
  @override
  _TenantComplaintPageState createState() => _TenantComplaintPageState();
}

class _TenantComplaintPageState extends State<TenantComplaint> with TickerProviderStateMixin {

  String? selectedType = "";

  final List<String> type_list = [
    'Complaints',
    'Suggestions',
  ];

  TextEditingController _descriptionController = TextEditingController();

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
  final _formKey = GlobalKey<FormState>();


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

          title: Text('Complaint/Suggestions',
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
                child: Form(
                  key: _formKey,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card
                          (
                            surfaceTintColor: appbar_color,
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
                                                    color: appbar_color,
                                                  ),
                                                  SizedBox(height: 2), // Add space between icon and text
                                                  Text(
                                                    'Saadan',
                                                    style: GoogleFonts.poppins(fontSize: 16,
                                                        color: appbar_color),
                                                  )])])),

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
                                                    color: appbar_color,
                                                  ),
                                                  SizedBox(height: 2), // Add space between icon and text
                                                  Text(
                                                    '+971 500000000',
                                                    style: GoogleFonts.poppins(fontSize: 16,
                                                        color: appbar_color),
                                                  )])]))]),

                                    SizedBox(height: 30,),

                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          color: appbar_color,
                                        ),
                                        SizedBox(height: 2), // Add space between icon and text
                                        Text(
                                          'saadan@ca-eim.com',
                                          style: GoogleFonts.poppins(fontSize: 16,
                                              color: appbar_color),
                                        )])]))),

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
                                    Text("Type:",
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
                                margin: EdgeInsets.only(left: 0, right: 0, bottom: 20),

                                child: DropdownButtonFormField<dynamic>(
                                  decoration: InputDecoration(

                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: appbar_color),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.black),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                  ),


                                  hint: Text('Select Type'), // Add a hint
                                  value: selectedType!.isNotEmpty ? selectedType : null,
                                  items: type_list.map((item) {
                                    return DropdownMenuItem<dynamic>(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: (value) async {
                                    selectedType = value!;
                                  },


                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Type is required'; // Error message
                                    }
                                    return null; // No error if a value is selected
                                  },
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
                                      controller: _descriptionController,
                                      keyboardType: TextInputType.multiline,
                                      validator: (value)
                                      {
                                        if(value == null || value.isEmpty)
                                        {
                                          return "Description is required";
                                        }
                                        return null;
                                      },

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
                              {
                                if (_formKey.currentState != null &&
                                    _formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();



                                }
                              }
                            },
                            child: Text('Submit',
                                style: GoogleFonts.poppins(
                                    color: Colors.white
                                )),
                          ),)
                      ]),
                )

            )
        )
    );}}
