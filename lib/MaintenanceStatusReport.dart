import 'package:cshrealestatemobile/Settings.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class MaintenanceStatusReport extends StatefulWidget {
  @override
  _MaintenanceStatusReportState createState() => _MaintenanceStatusReportState();
}

class _MaintenanceStatusReportState extends State<MaintenanceStatusReport> {
  List<dynamic> maintenanceStatuses = [];
  List<String> categories_list= [
    'Normal',
    'Close'
  ];

  String? selectedCategory;
  bool isLoading = true;

  TextEditingController maintenanceStatusController = TextEditingController();


  @override
  void initState() {
    super.initState();
    fetchMaintenanceStatus();
  }

  Future<void> sendMaintenanceStatus() async {
    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": maintenanceStatusController.text,
      'category': selectedCategory,
    };

    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    final String url = "$baseurl/maintenance/status";

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
        fetchMaintenanceStatus();

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

  Future<void> editMaintenanceStatus(int id, String status_name, String category) async {

    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": status_name,
      "category": selectedCategory,


    };

    print('jsonbody $jsonBody ');

    print('id $id ');

    String token = 'Bearer $Company_Token'; // auth token for request


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    final String url = "$baseurl/maintenance/status/$id";

    try{
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract code and message
        final String message = data['message'];

        // Display the message in a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$message'),
          ),);
        // Handle success
        fetchMaintenanceStatus();

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


  void showMaintenanceStatusDialog() {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appbar_color[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Maintenance Status",
            style: TextStyle(color: appbar_color[900]),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                // Dropdown for Categories
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Category:",
                      style: TextStyle(
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
                            style: TextStyle(
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
                                style: TextStyle(
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
                              showMaintenanceStatusDialog();

                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Maintenance Status Name Input Field
                TextFormField(
                  controller: maintenanceStatusController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter maintenance status name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Maintenance Status Name",
                    fillColor: Colors.white70, // Background color set to white
                    filled: true, // Ensures the fill color is applied
                    labelStyle: TextStyle(color: Colors.black54),
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
              child: Text("Cancel", style: TextStyle(color: appbar_color)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  sendMaintenanceStatus();
                  Navigator.pop(context);

                }

              },
              style: ElevatedButton.styleFrom(backgroundColor: appbar_color),
              child: Text("Submit",style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void showEditMaintenanceStatusDialog(int id, String old_status_name, String category) {
    final _formKey = GlobalKey<FormState>();

    TextEditingController MaintenanceStatusController = TextEditingController();

    MaintenanceStatusController.text = old_status_name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appbar_color[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Edit Maintenance Status",
            style: TextStyle(color: appbar_color[900],
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                // Dropdown for Categories
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Category:",
                      style: TextStyle(
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
                            style: TextStyle(
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
                                style: TextStyle(
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
                              showEditMaintenanceStatusDialog(id, old_status_name, category);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Maintenance Status Name Input Field
                TextFormField(
                  controller: MaintenanceStatusController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter maintenance status name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Maintenance Status Name",
                    fillColor: Colors.white70, // Background color set to white
                    filled: true, // Ensures the fill color is applied
                    labelStyle: TextStyle(color: Colors.black54),
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
              child: Text("Cancel", style: TextStyle(color: appbar_color)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  editMaintenanceStatus(id, MaintenanceStatusController.text, category) ;
                  Navigator.pop(context);

                }

              },
              style: ElevatedButton.styleFrom(backgroundColor: appbar_color),
              child: Text("Submit",style: TextStyle(color: Colors.white)),
            ),
          ],

        );
      },
    );
  }


  Future<void> fetchMaintenanceStatus() async {

    print('fetching Maintenance status');
    maintenanceStatuses.clear();

    final url = '$baseurl/maintenance/status'; // Replace with your API endpoint
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
          maintenanceStatuses = data['data']['maintenanceStatus'];
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

  Future<void> deleteMaintenanceStatus(int id) async {
    final url = '$baseurl/maintenance/status/$id'; // Replace with your API endpoint
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
            maintenanceStatuses.removeWhere((maintenance) => maintenance['id'] == id);
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
        title: Text('Maintenance Status',
          style: TextStyle(
              color: Colors.white
          ),),
        backgroundColor: appbar_color.withOpacity(0.9),

      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: appbar_color.withOpacity(0.9),
        ),
      )
          : maintenanceStatuses.isEmpty
          ? Center(
        child: Text(
          'No data available',
          style: TextStyle(color: appbar_color.withOpacity(0.9), fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: maintenanceStatuses.length,
        itemBuilder: (context, index) {
          final maintenance = maintenanceStatuses[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 5),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                          maintenance['name'] ?? 'Unnamed',
                          style: TextStyle(
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: appbar_color[800],
                          ),
                        ),

                        SizedBox(width: 5,),
                        Text(
                          maintenance['category'] ?? 'Unnamed',
                          style: TextStyle(
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

                        _buildDecentButton(
                          'Edit',
                          Icons.edit,
                          Colors.blue,
                              () {
                            setState(() {
                              selectedCategory = maintenance['category'] ?? 'Normal';
                            });

                            showEditMaintenanceStatusDialog(maintenance['id'],maintenance['name'],maintenance['category']);
                          },
                        ),
                        SizedBox(width:5),
                        _buildDecentButton(
                          'Delete',
                          Icons.delete,
                          Colors.redAccent,
                              () {

                            deleteMaintenanceStatus(maintenance['id']); },
                        ),
                        SizedBox(width:5)
                      ],),

                  ],),
              ),


            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:()
        {
          maintenanceStatusController.clear();
          selectedCategory = categories_list.first;

          showMaintenanceStatusDialog();
        },
        backgroundColor: appbar_color.withOpacity(0.9),

        child: Icon(Icons.add,
            color: Colors.white),
      ),
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


