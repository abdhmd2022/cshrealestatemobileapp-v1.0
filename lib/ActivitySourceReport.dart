import 'package:cshrealestatemobile/Settings.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ActivitySourceReport extends StatefulWidget {
  @override
  _ActivitySourceReportState createState() => _ActivitySourceReportState();
}

class _ActivitySourceReportState extends State<ActivitySourceReport> {
  List<dynamic> activitySource_list = [];
  bool isLoading = true;

  TextEditingController activitySourceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchActivitySources();
  }

  Future<void> sendActivitySources() async {

    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": activitySourceController.text,
    };

    String token = 'Bearer $Serial_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    const String url = "$BASE_URL_config/v1/activitySources";

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
        fetchActivitySources();

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

  Future<void> editActivitySource(int id, String activitysource_name ) async {
    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": activitysource_name,
    };

    print('jsonbody $jsonBody ');

    print('id $id ');

    String token = 'Bearer $Serial_Token'; // auth token for request


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    String url = "$BASE_URL_config/v1/activitySources/$id";

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
        fetchActivitySources();

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


  void showActivitySourceDialog() {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appbar_color[50],

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Activity Sources",
            style: TextStyle(color: appbar_color[900]),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextFormField(
                  controller: activitySourceController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                    {
                      return 'Please enter activity source name';
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Activity Source Name",
                    labelStyle: TextStyle(color: Colors.black54.withOpacity(0.5)),
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

                  sendActivitySources();
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

  void showEditActivitySourceDialog(int id, String old_activitysource_name) {
    final _formKey = GlobalKey<FormState>();

    TextEditingController activitySourceController = TextEditingController();

    activitySourceController.text = old_activitysource_name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appbar_color[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Edit Activity Source",
            style: TextStyle(color: appbar_color[900],
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextFormField(
                  controller: activitySourceController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                    {
                      return 'Please enter activity source name';
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Activity Source Name",
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

                  editActivitySource(id, activitySourceController.text) ;
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



  Future<void> fetchActivitySources() async {

    print('fetching activity sources');
    activitySource_list.clear();

    final url = '$BASE_URL_config/v1/activitySources'; // Replace with your API endpoint
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
          activitySource_list = data['data']['activitySources'];
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

  Future<void> deleteActivitySource(int id) async {
    final url = '$BASE_URL_config/v1/activitySources/$id'; // Replace with your API endpoint
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
            activitySource_list.removeWhere((activitysource) => activitysource['id'] == id);
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
        title: Text('Activity Sources',
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
          : activitySource_list.isEmpty
          ? Center(
        child: Text(
          'No data available',
          style: TextStyle(color: appbar_color.withOpacity(0.9), fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: activitySource_list.length,
        itemBuilder: (context, index) {
          final activitysource = activitySource_list[index];
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
                          activitysource['name'] ?? 'Unnamed',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: appbar_color[800],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),



                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        _buildDecentButton(
                          'Edit',
                          Icons.edit,
                          Colors.blue,
                              () {

                            showEditActivitySourceDialog(activitysource['id'],activitysource['name']);
                          },
                        ),
                        SizedBox(width:5),
                        _buildDecentButton(
                          'Delete',
                          Icons.delete,
                          Colors.redAccent,
                              () {

                            deleteActivitySource(activitysource['id']); },
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
          activitySourceController.clear();

          showActivitySourceDialog();
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


