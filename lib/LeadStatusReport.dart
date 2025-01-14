import 'package:cshrealestatemobile/Settings.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LeadStatusReport extends StatefulWidget {
  @override
  _LeadStatusReportState createState() => _LeadStatusReportState();
}

class _LeadStatusReportState extends State<LeadStatusReport> {
  List<dynamic> leadStatuses = [];
  bool isLoading = true;

  bool isQualified = false;
  TextEditingController leadStatusController = TextEditingController();
  final String uuid = "6e35f08d-8285-45e3-ae32-a0e9efe5407e";

  @override
  void initState() {
    super.initState();
    fetchLeadStatus();
  }

  Future<void> fetchLeadStatus() async {

    print('fetching lead status');
    leadStatuses.clear();

    final url = '$BASE_URL_config/v1/leadStatus'; // Replace with your API endpoint
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
          leadStatuses = data['data']['leadStatus'];
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

  Future<void> deleteLeadStatus(int id) async {
    final url = '$BASE_URL_config/v1/leadstatus/$id'; // Replace with your API endpoint
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
            leadStatuses.removeWhere((lead) => lead['id'] == id);
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
        title: Text('Lead Status',
        style: TextStyle(
          color: Colors.white
        ),),
        backgroundColor: Colors.blueGrey,

      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.blueGrey,
        ),
      )
          : leadStatuses.isEmpty
          ? Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.blueGrey, fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: leadStatuses.length,
        itemBuilder: (context, index) {
          final lead = leadStatuses[index];
          final isQualified = lead['is_qualified'] == 'true';
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              title: Container(
                child:  Column(
                  children: [
                    Text(
                      lead['name'] ?? 'Unnamed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),

                    SizedBox(height: 10),

                    Row(children: [

                      _buildDecentButton(
                        'Edit',
                        Icons.edit,
                        Colors.blue,
                            () {},
                      ),
                      SizedBox(width:5),
                      _buildDecentButton(
                        'Delete',
                        Icons.delete,
                        Colors.redAccent,
                            () {

                          deleteLeadStatus(lead['id']); },
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
          leadStatusController.clear();
          isQualified = false;
          showLeadStatusDialog();
        },
        backgroundColor: Colors.blueGrey,
        child: Icon(Icons.add,
        color: Colors.white),
      ),
    );
  }
  Future<void> sendLeadStatus() async {
    final Map<String, dynamic> jsonBody = {
      "uuid": uuid,
      "name": leadStatusController.text,
      "is_qualified": isQualified ? 1 : 0,
    };

    String token = 'Bearer $Serial_Token'; // auth token for request


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    const String url = "$BASE_URL_config/v1/leadStatus";

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
        fetchLeadStatus();

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

  void showLeadStatusDialog() {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Lead Status",
            style: TextStyle(color: Colors.blueGrey[900]),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Is Qualified", style: TextStyle(color: Colors.blueGrey[900])),
                    Switch(
                      value: isQualified,
                      onChanged: (value) {
                        setState(() {
                          isQualified = value;
                          Navigator.of(context).pop();
                          showLeadStatusDialog();
                        });
                      },
                      activeColor: Colors.blueGrey,
                    ),
                  ],
                ),

                SizedBox(height: 10,),
                TextFormField(
                  controller: leadStatusController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                    {
                      return 'Please enter lead status name';
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Lead Status Name",
                    labelStyle: TextStyle(color: Colors.blueGrey),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey[200]!),
                    ),
                  ),
                ),


              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  sendLeadStatus();
                  Navigator.pop(context);

                }

              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: Text("Submit",style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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


