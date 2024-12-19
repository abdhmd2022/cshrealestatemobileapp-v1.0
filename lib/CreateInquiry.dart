import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'constants.dart';

class CreateInquiry extends StatefulWidget {

  @override
  State<CreateInquiry> createState() => _CreateInquiryPageState();
}

class _CreateInquiryPageState extends State<CreateInquiry> {

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

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: appbar_color,
          title: Text('Create Inquiry',
            style: TextStyle(
                color: Colors.white
            )),
        ),
        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.all(20),
            child:    Card(
              surfaceTintColor: Theme.of(context).colorScheme.surface,
              elevation: 20,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Form(
                    key: _formKey,
                    child: ListView(
                        children: [

                          Container(padding: EdgeInsets.only(top: 5),
                            child: TextFormField(
                              controller: customernamecontroller,
                              focusNode: customernameFocusNode,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              decoration: InputDecoration(
                                labelText: 'Customer Name',
                                filled: true,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                  borderSide: BorderSide(
                                    color: Colors.black12,
                                  ),
                                ),
                                fillColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: Colors.black54, // Set the label text color to black
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                              ),
                              style: TextStyle(
                                color: Colors.black,
                              ),

                              validator: (value) {
                                if (value == null || value.isEmpty)
                                {
                                  return 'Please enter customer name';
                                }

                                return null;
                              },
                            ),),

                          SizedBox(height: 16.0),

                          TextFormField(
                            controller: customercontactnocontroller,
                            focusNode: customercontactnoFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                                borderSide: BorderSide(
                                  color: Colors.black12,
                                ),
                              ),
                              labelText: 'Customer Contact No',
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: TextStyle(
                                color: Colors.black54, // Set the label text color to black
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),

                            validator: (value)
                            {
                              if (value == null || value.isEmpty)
                              {
                                return 'Please enter customer contact no.';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16.0),

                          TextFormField(
                            controller: unittypecontroller,

                            focusNode: unittypeFocusNode,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                                borderSide: BorderSide(
                                  color: Colors.black12,
                                ),
                              ),
                              labelText: 'Unit Type',
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: TextStyle(
                                color: Colors.black54, // Set the label text color to black
                              ),

                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),

                              ),
                            ),

                            validator: (value)
                            {
                              if (value == null || value.isEmpty)
                              {
                                return 'Please enter Unit Type(s)';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16.0),

                          DropdownMenu<String>(
                            width: MediaQuery.of(context).size.width - 90,
                            initialSelection: emirate.first,
                            menuStyle: MenuStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            label: Text("Emirate"),
                            onSelected: (String? emirate) {
                              setState(() {
                                selectedEmirate = emirate!;
                              });
                            },
                            dropdownMenuEntries:
                            emirate.map<DropdownMenuEntry<String>>((String emirate) {
                              return DropdownMenuEntry<String>(
                                value: emirate,
                                label: emirate,
                              );
                            }).toList(),
                          ),

                          SizedBox(height: 16.0),

                          TextFormField(
                            controller: areacontroller,
                            focusNode: areaFocusNode,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                                borderSide: BorderSide(
                                  color: Colors.black12,
                                ),
                              ),
                              labelText: 'Area',
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: TextStyle(
                                color: Colors.black54, // Set the label text color to black
                              ),

                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),

                            validator: (value)
                            {
                              if (value == null || value.isEmpty)
                              {
                                return 'Please enter area';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16.0),

                          DropdownMenu<String>(
                            width: MediaQuery.of(context).size.width - 90,
                            initialSelection: asignedto.first,
                            menuStyle: MenuStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            label: Text("Assigned To"),
                            onSelected: (String? asignedto) {
                              setState(() {
                                selectedasignedto = asignedto!;
                              });
                            },
                            dropdownMenuEntries:
                            asignedto.map<DropdownMenuEntry<String>>((String asignedto) {
                              return DropdownMenuEntry<String>(
                                value: asignedto,
                                label: asignedto,
                              );
                            }).toList(),
                          ),

                          SizedBox(height: 16.0),

                          Container(padding: EdgeInsets.only(top: 5),
                            child: TextFormField(
                              controller: descriptioncontroller,
                              focusNode: descriptionFocusNode,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                filled: true,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                  borderSide: BorderSide(
                                    color: Colors.black12,
                                  ),
                                ),
                                fillColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: Colors.black54, // Set the label text color to black
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                              ),
                              style: TextStyle(
                                color: Colors.black,
                              ),

                              validator: (value) {
                                if (value == null || value.isEmpty)
                                {
                                  return 'Please enter description';
                                }
                                return null;
                              })),

                          Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.only(left: 20,right: 20,top: 30,bottom: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appbar_color,
                                elevation: 5, // Adjust the elevation to make it look elevated
                                shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                              ),
                              onPressed: () {
                                {
                                  if (_formKey.currentState != null &&
                                      _formKey.currentState!.validate())
                                  {
                                    _formKey.currentState!.save();
                                  }
                                }},
                              child: Text('Create',
                                  style: TextStyle(
                                      color: Colors.white
                                  )),
                            )
                          )
                        ]
                    ))))));}}