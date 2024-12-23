import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'SalesInquiryReport.dart';
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
  final emailcontroller = TextEditingController();

  // focus nodes initialization
  final customernameFocusNode = FocusNode();
  final customercontactnoFocusNode = FocusNode();
  final unittypeFocusNode = FocusNode();
  final areaFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();

   String? selectedasignedto;

  bool isUnitSelected = false;

  bool isAllUnitsSelected = false;


  bool isEmirateSelected = false;

  bool isAllEmiratesSelected = false;


  String? selectedEmirate;

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

  List<Map<String, dynamic>> emirates = [
    {"label": "Abu Dhabi", "isSelected": false},
    {"label": "Dubai", "isSelected": false},
    {"label": "Sharjah", "isSelected": false},
    {"label": "Ajman", "isSelected": false},
    {"label": "Umm Al Quwain", "isSelected": false},
    {"label": "Ras Al-Khaimah", "isSelected": false},
    {"label": "Fujairah", "isSelected": false},
  ];

  List<String> asignedto = [
    'Self',
  ];

  List<Map<String, dynamic>> unitTypes = [
  {"label": "Studio", "isSelected": false},
  {"label": "1BHK", "isSelected": false},
  {"label": "2BHK", "isSelected": false},
  {"label": "3BHK", "isSelected": false},
  {"label": "Penthouse", "isSelected": false},
  ];

  String selectedUnitType = "Select Unit Types";
  String selectedEmirates = "Select Emirate";


  void _openUnitTypeDropdown(BuildContext context) async {
    final selectedItems = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, dynamic>> filteredUnitTypes = List.from(unitTypes); // Make a copy of the original list

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "Unit Type(s)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        filteredUnitTypes = unitTypes
                            .where((unit) =>
                            unit['label']
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Unit Types',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey), // BlueGrey border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey), // BlueGrey focused border color
                      ),
                    ),
                  ),
                ),
                // Conditionally show Select All only if there is no search query
                if (searchController.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: CheckboxListTile(
                        title: Text("Select All",
                          style: TextStyle(color: Colors.black),
                        ),
                        activeColor: Colors.blueGrey,
                        value: isAllUnitsSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            isAllUnitsSelected = value ?? false;
                            // Update all unit types based on Select All
                            for (var unit in unitTypes) {
                              unit['isSelected'] = isAllUnitsSelected;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                SizedBox(height: 15),
                Expanded(
                  child: ListView(
                    children: filteredUnitTypes.map((unit) {
                      return CheckboxListTile(
                        title: Text(unit['label']),
                        activeColor: Colors.blueGrey,
                        value: unit['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            unit['isSelected'] = value!;
                            // If an individual unit is deselected, unselect 'Select All'
                            if (!unit['isSelected']) {
                              isAllUnitsSelected = false;
                            }
                            // If all units are selected, select 'Select All'
                            if (unitTypes.every((u) => u['isSelected'])) {
                              isAllUnitsSelected = true;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
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
                      List<String> selected = unitTypes
                          .where((unit) => unit['isSelected'])
                          .map((unit) => unit['label'] as String)
                          .toList();

                      if (selected.isEmpty) {
                        Navigator.of(context).pop(null);  // Return null if no selection
                      } else {
                        Navigator.of(context).pop(selected);
                      }
                    },
                    child: Text('OK'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Update the selected items and set the background color
    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        selectedUnitType = selectedItems.join(', ');
        isUnitSelected = true;  // Mark as selected
      });
    } else {
      setState(() {
        selectedUnitType = "Select Unit Types";  // Reset if no selection
        isUnitSelected = false;  // Mark as not selected
      });
    }
  }


  void _openEmiratesDropdown(BuildContext context) async {
    final selectedItems = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, dynamic>> filteredEmirates = List.from(emirates); // Make a copy of the original list

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "Emirate(s)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        filteredEmirates = emirates
                            .where((emirate) =>
                            emirate['label']
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Emirate(s)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey), // BlueGrey border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey), // BlueGrey focused border color
                      ),
                    ),
                  ),
                ),
                // Conditionally show Select All only if there is no search query
                if (searchController.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: CheckboxListTile(
                        title: Text("Select All"),
                        activeColor: Colors.blueGrey,
                        value: isAllEmiratesSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            isAllEmiratesSelected = value ?? false;
                            // Update all emirates based on Select All
                            for (var unit in emirates) {
                              unit['isSelected'] = isAllEmiratesSelected;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                SizedBox(height: 15),
                Expanded(
                  child: ListView(
                    children: filteredEmirates.map((unit) {
                      return CheckboxListTile(
                        title: Text(unit['label']),
                        activeColor: Colors.blueGrey,
                        value: unit['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            unit['isSelected'] = value!;
                            // If an individual unit is deselected, unselect 'Select All'
                            if (!unit['isSelected']) {
                              isAllEmiratesSelected = false;
                            }
                            // If all units are selected, select 'Select All'
                            if (emirates.every((u) => u['isSelected'])) {
                              isAllEmiratesSelected = true;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
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
                      List<String> selected = emirates
                          .where((unit) => unit['isSelected'])
                          .map((unit) => unit['label'] as String)
                          .toList();

                      if (selected.isEmpty) {
                        Navigator.of(context).pop(null); // Return null if no selection
                      } else {
                        Navigator.of(context).pop(selected);
                      }
                    },
                    child: Text('OK'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Update the selected items and set the background color
    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        selectedEmirates = selectedItems.join(', ');
        isEmirateSelected = true;  // Mark as selected
      });
    } else {
      setState(() {
        selectedEmirates = "Select Emirate";  // Reset if no selection
        isEmirateSelected = false;  // Mark as not selected
      });
    }
  }




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

          leading: GestureDetector(
            onTap: ()
            {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SalesInquiryReport()),
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
                              /*physics: NeverScrollableScrollPhysics(),*/
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
                                        hintText: 'Enter Name',
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
                                      Text("Contact No.",
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
                                        hintText: 'Enter Contact No',
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
                                      Text("Email Address",
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
                                      controller: emailcontroller,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Email Address is required';
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                                        {
                                          return 'Please enter a valid email address';
                                        }

                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Email Address',
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

                                Padding(
                                  padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                  child: GestureDetector(
                                    onTap: () => _openUnitTypeDropdown(context), // Open the custom dropdown
                                    child: TextFormField(
                                      controller: TextEditingController(text: selectedUnitType),
                                      decoration: InputDecoration(
                                        hintText: 'Select Unit Type(s)',
                                        contentPadding: EdgeInsets.all(15),
                                        fillColor: isUnitSelected ? Colors.transparent : Colors.transparent, // Set to black if selected
                                        filled: true, // Ensure the field is filled but transparent or black based on isSelected
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.black), // Black border
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.black), // Black border when enabled
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.black), // Black border when disabled
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.black), // Black focused border
                                        ),
                                        labelStyle: TextStyle(color: Colors.black),
                                        hintStyle: TextStyle(color: Colors.black), // Hint text color (white for better contrast)
                                      ),



                                      enabled: false, //// Disable direct editing
                                      validator: (value) {
                                        // If no unit type is selected, show error
                                        bool isAnySelected = unitTypes.any((unit) => unit['isSelected']);
                                        if (!isAnySelected) {
                                          return 'Unit type is required';
                                        }
                                        return null; // No error
                                      },
                                    ),
                                  ),
                                ),

                                /*Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

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


                                ),*/

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
                                        padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                        child: GestureDetector(
                                          onTap: () => _openEmiratesDropdown(context), // Open the custom dropdown
                                          child: TextFormField(
                                            controller: TextEditingController(text: selectedEmirates),
                                            decoration: InputDecoration(
                                              hintText: 'Select Emirate',
                                              contentPadding: EdgeInsets.all(15),
                                              fillColor: isEmirateSelected ? Colors.transparent : Colors.transparent, // Set to black if selected
                                              filled: true, // Ensure the field is filled but transparent or black based on isSelected
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.black), // Black border
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.black), // Black border when enabled
                                              ),
                                              disabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.black), // Black border when disabled
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.black), // Black focused border
                                              ),
                                              labelStyle: TextStyle(color: Colors.black),
                                              hintStyle: TextStyle(color: Colors.black), // Hint text color (white for better contrast)
                                            ),



                                            enabled: false, //// Disable direct editing
                                            validator: (value) {
                                              // If no unit type is selected, show error
                                              bool isAnySelected = emirates.any((unit) => unit['isSelected']);
                                              if (!isAnySelected) {
                                                return 'Emirate is required';
                                              }
                                              return null; // No error
                                            },
                                          ),
                                        ),
                                      ),



                                      /*Padding(
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

                                          hint: Text('Select Emirate'), // Add a hint
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
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Emirate is required'; // Error message
                                            }
                                            return null; // No error if a value is selected
                                          },
                                        ),
                                      ),*/


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


                                          hint: Text('Select Assigned To'), // Add a hint
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

                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Assigned To is required'; // Error message
                                            }
                                            return null; // No error if a value is selected
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