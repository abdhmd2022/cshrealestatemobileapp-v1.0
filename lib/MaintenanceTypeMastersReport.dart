import 'package:cshrealestatemobile/Settings.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class MaintenanceTypeMastersReport extends StatefulWidget {
  @override
  _MaintenanceTypeMastersReportState createState() => _MaintenanceTypeMastersReportState();
}

class _MaintenanceTypeMastersReportState extends State<MaintenanceTypeMastersReport> {
  List<dynamic> maintenance_types_list = [];
  bool isLoading = true;

  TextEditingController maintenanceTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMaintenanceType();
  }

  Future<void> sendMaintenanceType() async {
    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": maintenanceTypeController.text,
    };

    String token = 'Bearer $Serial_Token'; // auth token for request


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    const String url = "$BASE_URL_config/v1/maintenanceTypes";

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
    };

    print('jsonbody $jsonBody ');

    print('id $id ');

    String token = 'Bearer $Serial_Token'; // auth token for request


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    String url = "$BASE_URL_config/v1/maintenanceTypes/$id";

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
            style: TextStyle(color: appbar_color[900]),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

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
                    labelStyle: TextStyle(color: Colors.black54),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54!),
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

                  sendMaintenanceType();
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
            "Edit Lead Follow-up",
            style: TextStyle(color: appbar_color[900],
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

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
                    labelStyle: TextStyle(color: Colors.black54),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black54!),
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

                  editMaintenaceType(id, maintenaceTypeController.text,context) ;


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


  Future<void> fetchMaintenanceType() async {

    print('fetching lead type');
    maintenance_types_list.clear();

    final url = '$BASE_URL_config/v1/maintenanceTypes'; // Replace with your API endpoint
    String token = 'Bearer $Serial_Token'; // auth token for request

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
    final url = '$BASE_URL_config/v1/maintenanceTypes/$id'; // Replace with your API endpoint
    String token = 'Bearer $Serial_Token'; // auth token for request

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
          : maintenance_types_list.isEmpty
          ? Center(
        child: Text(
          'No data available',
          style: TextStyle(color: appbar_color.withOpacity(0.9), fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: maintenance_types_list.length,
        itemBuilder: (context, index) {
          final lead = maintenance_types_list[index];
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
                          lead['name'] ?? 'Unnamed',
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

                            showEditMaintenanceTypeDialog(lead['id'],lead['name']);
                          },
                        ),
                        SizedBox(width:5),
                        _buildDecentButton(
                          'Delete',
                          Icons.delete,
                          Colors.redAccent,
                              () {

                            deleteMaintenanceType(lead['id']); },
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
          maintenanceTypeController.clear();
          showMaintenaceTypeDialog();
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


