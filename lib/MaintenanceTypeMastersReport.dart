import 'dart:io';
import 'package:cshrealestatemobile/Settings.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

class MaintenanceTypeMastersReport extends StatefulWidget {
  @override
  _MaintenanceTypeMastersReportState createState() => _MaintenanceTypeMastersReportState();
}

class _MaintenanceTypeMastersReportState extends State<MaintenanceTypeMastersReport> {
  List<dynamic> maintenance_types_list = [];
  bool isLoading = false;

  TextEditingController maintenanceTypeController = TextEditingController();

  String? selectedCategory;

  List<String> categories_list= [
    'MEP',
    'Pest Control',
    'Cleaning',
  ];

  @override
  void initState() {
    super.initState();
    if(hasPermission('canViewMaintenanceTypes')){
      fetchMaintenanceType();
    }
  }

  Future<void> sendMaintenanceType() async {
    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": maintenanceTypeController.text,
      "category": selectedCategory

    };

    String token = 'Bearer $Company_Token'; // auth token for request


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    final String url = "$baseurl/maintenance/maintenanceType";

    try{
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract code and message
        final String message = data['message'];

        // Display the message in a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$message'),
          ),);
        // Handle success
        fetchMaintenanceType();

      } else {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract code and message
        final String code = data['code'].toString();
        final String message = data['message'].toString();

        // Display the message in a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code: $code\nMessage: $message'),
            backgroundColor: code == 200 ? Colors.green : Colors.red,
          ),
        );
      }
    }
    catch (e)
    {

    }



  }

  Future<void> editMaintenaceType(int id, String maintenanceType_name,BuildContext contextt ) async {

    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": maintenanceType_name,
      "category" : selectedCategory
    };


    print('jsonbody $jsonBody ');

    print('id $id ');

    String token = 'Bearer $Company_Token'; // auth token for request


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    String url = "$baseurl/maintenance/maintenanceType/$id";

    try{
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        Navigator.pop(contextt);

        // Extract code and message
        final String message = data['message'];

        // Display the message in a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$message'),
          ),);

        // Handle success
        fetchMaintenanceType();

      } else {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract code and message
        final String code = data['code'].toString();
        final String message = data['message'].toString();

        // Display the message in a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code: $code\nMessage: $message'),
            backgroundColor: code == 200 ? Colors.green : Colors.red,
          ),
        );
      }
    }
    catch (e)
    {

    }



  }


  void showMaintenaceTypeDialog() {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appbar_color[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Maintenance Types",
            style: GoogleFonts.poppins(color: appbar_color[900]),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Category:",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black54,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          hint: Text(
                            "Select a category",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black54,
                          ),
                          isExpanded: true,
                          items: categories_list.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue;
                              Navigator.of(context).pop();
                              showMaintenaceTypeDialog();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                TextFormField(
                  controller: maintenanceTypeController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                    {
                      return 'Please enter maintenance type name';
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Maintenace Type Name",
                    labelStyle: GoogleFonts.poppins(color: Colors.black54),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54),
                    ),
                  ),
                ),


              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: appbar_color)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  sendMaintenanceType();
                  Navigator.pop(context);

                }

              },
              style: ElevatedButton.styleFrom(backgroundColor: appbar_color),
              child: Text("Submit",style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void showEditMaintenanceTypeDialog(int id, String old_followup_name) {
    final _formKey = GlobalKey<FormState>();


    TextEditingController maintenaceTypeController = TextEditingController();

    maintenaceTypeController.text = old_followup_name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appbar_color[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Edit Maintenance Type",
            style: GoogleFonts.poppins(color: appbar_color[900],
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Category:",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black54,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          hint: Text(
                            "Select a category",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black54,
                          ),
                          isExpanded: true,
                          items: categories_list.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue;
                              Navigator.of(context).pop();
                              showEditMaintenanceTypeDialog(id, old_followup_name);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                TextFormField(
                  controller: maintenaceTypeController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                    {
                      return 'Please enter maintenance type name';
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Maintenance Type Name",
                    fillColor: Colors.white70, // Background color set to white
                    filled: true, // Ensures the fill color is applied

                    labelStyle: GoogleFonts.poppins(color: Colors.black54),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54),
                    ),
                  ),
                ),


              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: appbar_color)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  editMaintenaceType(id, maintenaceTypeController.text,context) ;


                }

              },
              style: ElevatedButton.styleFrom(backgroundColor: appbar_color),
              child: Text("Submit",style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


  Future<void> fetchMaintenanceType() async {
    setState(() {
      isLoading = true;
    });

    print('fetching maintenance type');
    maintenance_types_list.clear();

    final url = '$baseurl/maintenance/maintenanceType'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    print('fetch url $url');
    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {
          print('response ${response.body}');
          maintenance_types_list = data['data']['maintenanceTypes'];
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> deleteMaintenanceType(int id) async {
    final url = '$baseurl/maintenance/maintenanceType/$id'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };    try {
      final response = await http.delete(Uri.parse(url),
          headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            maintenance_types_list.removeWhere((type) => type['id'] == id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        }
      } else {
        final data = json.decode(response.body);

        throw Exception(data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: ()
          {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),
        title: Text('Maintenance Types',
          style: GoogleFonts.poppins(
              color: Colors.white
          ),),
        backgroundColor: appbar_color.withOpacity(0.9),

      ),
      body: hasPermission('canViewMaintenanceTypes') ? (
      isLoading
          ? Center(
          child:Container(
            color: Colors.white,
            child: Platform.isIOS
                ? CupertinoActivityIndicator(radius: 15.0)
                : CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
              strokeWidth: 4.0,
            ),
          ))
          : maintenance_types_list.isEmpty
          ? Center(
          child: Container(
            color: Colors.white,
            child: Text(
              'No data available',
              style: GoogleFonts.poppins(color: appbar_color.withOpacity(0.9), fontSize: 18),
            ),
          ))
          : Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: 10),
        child: ListView.builder(
          itemCount: maintenance_types_list.length,
          itemBuilder: (context, index) {
            final type = maintenance_types_list[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 5),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12), // Rounded corners

                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  title: Container(
                    child:  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [
                            Icon(
                              Icons.assignment_ind,
                              color: appbar_color.withOpacity(0.9),
                            ),

                            SizedBox(width: 5,),
                            Text(
                              type['name'] ?? 'Unnamed',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.normal,
                                color: appbar_color[800],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),

                        Row(
                          children: [
                            Text(
                              'Category:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: appbar_color[800],
                              ),
                            ),

                            SizedBox(width: 5,),
                            Text(
                              type['category'] ?? 'Unnamed',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.normal,
                                color: appbar_color[800],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            if(hasPermission('canUpdateMaintenanceTypes'))...[
                              _buildDecentButton(
                                'Edit',
                                Icons.edit,
                                Colors.blue,
                                    () {
                                  selectedCategory = type['category'] ?? categories_list.first;
                                  showEditMaintenanceTypeDialog(type['id'],type['name']);
                                },
                              ),
                              SizedBox(width:5),
                            ],

                            if(hasPermission('canDeleteMaintenanceTypes'))...[
                              _buildDecentButton(
                                'Delete',
                                Icons.delete,
                                Colors.redAccent,
                                    () {

                                  deleteMaintenanceType(type['id']); },
                              ),
                              SizedBox(width:5)
                            ]
                          ],),
                      ],),
                  ),


                ),
              ),

            );
          },
        ),
      )
      ) :
      Expanded(
        child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "Access Denied",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "You don’t have permission to view maintenance types.",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
        ),
      ),

        floatingActionButton: hasPermission('canCreateMaintenanceTypes') ? FloatingActionButton(
        onPressed:()
        {
          maintenanceTypeController.clear();
          selectedCategory = categories_list.first;
          showMaintenaceTypeDialog();
        },
        backgroundColor: appbar_color.withOpacity(0.9),
        child: Icon(Icons.add,
            color: Colors.white),
      ) : null
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
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 7.0),
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
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}


