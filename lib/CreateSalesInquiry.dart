import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'SalesDashboard.dart';
import 'constants.dart';

class CreateSalesInquiry extends StatefulWidget {

  @override
  State<CreateSalesInquiry> createState() => _CreateSaleInquiryPageState();
}

class _CreateSaleInquiryPageState extends State<CreateSalesInquiry> {

  final _formKey = GlobalKey<FormState>();

  // text editing controllers intialization
  final customernamecontroller = TextEditingController();
  final customercontactnocontroller = TextEditingController();
  final unittypecontroller = TextEditingController();
  final emiratescontroller = TextEditingController();
  final areacontroller = TextEditingController();
  final descriptioncontroller = TextEditingController();

  // focus nodes initialization
  final customernameFocusNode = FocusNode();
  final customercontactnoFocusNode = FocusNode();
  final unittypeFocusNode = FocusNode();
  final areaFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();

  late String selectedEmirate,selectedasignedto;

  bool _isFocused_email = false,_isFocus_name = false;


  bool _isLoading = false;

      List<String> emirate = [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al-Khaimah',
    'Fujairah'
  ];

  List<String> asignedto = [
    'Self',
  ];

  @override
  void initState() {
    super.initState();

    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    selectedEmirate = emirate.first;
    selectedasignedto = asignedto.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: appbar_color,

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
          title: Text('Inquiry',
            style: TextStyle(
                color: Colors.white
            )),
        ),
        body: Stack(
          children: [
            Visibility(
              visible: _isLoading,
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(
                        left: 20,
                        top: 20,
                        right: 30,
                        bottom: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                          'Create Inquiry',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                          SizedBox(height: 5,),
                          Text(
                            'Create your sales inquiry',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      )
                  ),

                  Container(
                      height: MediaQuery.of(context).size.height,
                      child:  Form(
                          key: _formKey,
                          child: ListView(
                              physics: NeverScrollableScrollPhysics(),
                              children: [
                                Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Name:",
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

                                Padding(

                                    padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),
                                    child: TextFormField(
                                      controller: customernamecontroller,
                                      keyboardType: TextInputType.name,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Name is required';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Customer Name',
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
                                            color:  Colors.black, // Set the focused border color
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocus_name = true;
                                          _isFocused_email = false;

                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocus_name = true;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },

                                    )),

                                Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Customer Contact No.",
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

                                Padding(

                                    padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: customercontactnocontroller,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Contact No. is required';
                                        }

                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Customer Contact No',
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
                                            color:  Colors.black, // Set the focused border color

                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocused_email = true;
                                          _isFocus_name = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocused_email = false;
                                          _isFocus_name = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocused_email = true;
                                          _isFocus_name = false;

                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocused_email = false;
                                          _isFocus_name = false;
                                        });
                                      },

                                    )),

                                Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Unit Type:",
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

                                Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: unittypecontroller,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Unit type is required';
                                        }

                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Unit Type(s)',
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
                                            color:  Colors.black, // Set the focused border color
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                    )


                                ),

                                Container(
                                  child: Column(

                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(padding: EdgeInsets.only(top: 15,left:20),

                                        child:Row(
                                          children: [
                                            Text("Select Emirate:",
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

                                      Padding(
                                        padding: EdgeInsets.only(top:0,left:20,right:20,bottom :0),

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


                                          hint: Text('Emirate'), // Add a hint
                                          value: selectedEmirate,
                                          items: emirate.map((item) {
                                            return DropdownMenuItem<dynamic>(
                                              value: item,
                                              child: Text(item),
                                            );
                                          }).toList(),
                                          onChanged: (value) async {
                                            selectedEmirate = value!;
                                          },

                                          onTap: ()
                                          {
                                            setState(() {
                                              _isFocused_email = false;
                                              _isFocus_name = false;
                                            });

                                          },
                                        ),
                                      ),


                                    ],
                                  ),
                                ),

                                Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Area:",
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

                                Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: areacontroller,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Area is required';
                                        }

                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Area',
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
                                            color:  Colors.black, // Set the focused border color
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                    )


                                ),


                                Container(
                                  child: Column(

                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(padding: EdgeInsets.only(top: 15,left:20),

                                        child:Row(
                                          children: [
                                            Text("Assigned To:",
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

                                      Padding(
                                        padding: EdgeInsets.only(top:0,left:20,right:20,bottom :0),

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


                                          hint: Text('Emirate'), // Add a hint
                                          value: selectedasignedto,
                                          items: asignedto.map((item) {
                                            return DropdownMenuItem<dynamic>(
                                              value: item,
                                              child: Text(item),
                                            );
                                          }).toList(),
                                          onChanged: (value) async {
                                            selectedasignedto = value!;
                                          },

                                          onTap: ()
                                          {
                                            setState(() {
                                              _isFocused_email = false;
                                              _isFocus_name = false;
                                            });

                                          },
                                        ),
                                      ),


                                    ],
                                  ),
                                ),

                                Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
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

                                Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: descriptioncontroller,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Description is required';
                                        }
                                        return null;
                                      },
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
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color:  Colors.black, // Set the focused border color
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                    )
                                ),

                                Padding(padding: EdgeInsets.only(left: 20,right: 20,top: 40,bottom: 50),
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

                                                _formKey.currentState?.reset();
                                                selectedasignedto = asignedto.first;
                                                selectedEmirate = emirate.first;

                                                /*print(_selectedrole['role_name']);*/

                                                customernamecontroller.clear();
                                                customercontactnocontroller.clear();
                                                unittypecontroller.clear();
                                                areacontroller.clear();
                                                descriptioncontroller.clear();

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

                                              if (_formKey.currentState != null &&
                                                  _formKey.currentState!.validate()) {
                                                _formKey.currentState!.save();

                                                setState(() {
                                                  _isFocused_email = false;
                                                  _isFocus_name = false;
                                                });
                                                /*userRegistration(serial_no!,fetched_email,fetched_password,fetched_role,fetched_name);*/

                                              }},
                                            child: Text('Create'),
                                          ),
                                        ],)
                                  ),)
                              ]))
                  )
                ],
              ),)
          ],
        ) ,);}}