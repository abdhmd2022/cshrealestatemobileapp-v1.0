import 'dart:io';

import 'package:cshrealestatemobile/Settings.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

class AmentiesReport extends StatefulWidget {
  @override
  _AmentiesReportState createState() => _AmentiesReportState();
}

class _AmentiesReportState extends State<AmentiesReport> {
  List<dynamic> amenities = [];
  bool isLoading = true;

  bool isSpecial = false;
  TextEditingController amenitiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAmenities();
  }

  Future<void> sendAmenities() async {

    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": amenitiesController.text,
      "is_special": isSpecial ? 'true' : 'false',
    };

    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

     String url = "$baseurl/lead/amenity";

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
        fetchAmenities();

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

  Future<void> editAmenities(int id, String amenity_name, bool is_special ) async {

    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();
    final Map<String, dynamic> jsonBody = {
      "uuid": uuidValue,
      "name": amenity_name,
      "is_special": is_special ? 'true' : 'false',
    };

    print('jsonbody $jsonBody ');

    print('id $id ');

    String token = 'Bearer $Company_Token'; // auth token for request


    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    String url = "$baseurl/lead/amenity/$id";

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
        fetchAmenities();

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


  void showAmenitiesDialog() {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appbar_color[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Amenities",
            style: GoogleFonts.poppins(color: appbar_color[900]),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Preference", style: GoogleFonts.poppins(color: appbar_color[900])),
                    Switch(
                      value: isSpecial,
                      onChanged: (value) {
                        setState(() {
                          isSpecial = value;
                          Navigator.of(context).pop();
                          showAmenitiesDialog();
                        });
                      },
                      activeColor: appbar_color.withOpacity(0.9),
                    ),
                  ],
                ),

                SizedBox(height: 10,),
                TextFormField(
                  controller: amenitiesController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                    {
                      return 'Please enter amenity name';
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Amenity Name",

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

                  sendAmenities();
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

  void showEditAmenitiesDialog(int id, String old_amenity_name, String is_special) {
    final _formKey = GlobalKey<FormState>();

    bool isSpecial = false;

    if(is_special.toLowerCase() == "true")
    {
      isSpecial = true;

    }
    TextEditingController amenityController = TextEditingController();

    amenityController.text = old_amenity_name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appbar_color[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Edit Amenity",
            style: GoogleFonts.poppins(color: appbar_color[900],
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Preference", style: GoogleFonts.poppins(color: appbar_color[900])),
                    Switch(
                      value: isSpecial,
                      onChanged: (value) {
                        setState(() {
                          isSpecial = value;
                          Navigator.of(context).pop();
                          if(isSpecial == true)
                          {
                            is_special = "true";
                          }
                          else
                          {
                            is_special = "false";
                          }
                          showEditAmenitiesDialog(id, amenityController.text,is_special);
                        });
                      },
                      activeColor: appbar_color.withOpacity(0.9),
                    ),
                  ],
                ),

                SizedBox(height: 10,),
                TextFormField(
                  controller: amenityController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                    {
                      return 'Please enter amenity name';
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Amenity Name",
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

                  editAmenities(id, amenityController.text, isSpecial) ;
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


  Future<void> fetchAmenities() async {

    print('fetching amenities');
    amenities.clear();

    final url = '$baseurl/lead/amenity'; // Replace with your API endpoint
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
          amenities = data['data']['amenities'];
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

  Future<void> deleteAmenities(int id) async {
    final url = '$baseurl/lead/amenity/$id'; // Replace with your API endpoint
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
            amenities.removeWhere((amenity) => amenity['id'] == id);
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
        title: Text('Amenities',
          style: GoogleFonts.poppins(
              color: Colors.white
          ),),
        backgroundColor: appbar_color.withOpacity(0.9),

      ),
      body: isLoading
          ? Center(
        child: Container(
          color: Colors.white,
          child: Platform.isIOS
            ? CupertinoActivityIndicator(radius: 15.0)
            : CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
          strokeWidth: 4.0,
        ),
      ))
          : amenities.isEmpty
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
          itemCount: amenities.length,
          itemBuilder: (context, index) {
            final amenity = amenities[index];
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
                child:  ListTile(
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
                              amenity['name'] ?? 'Unnamed',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.normal,
                                color: appbar_color[800],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        Row(
                          children: [
                            Text('Preference: ',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold
                              ),),

                            if(amenity['is_special'] == 'true')
                              Text(
                                'Yes',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.normal,
                                  color: appbar_color[800],
                                ),
                              ),

                            if(amenity['is_special'] == 'false')
                              Text(
                                'No',
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

                            _buildDecentButton(
                              'Edit',
                              Icons.edit,
                              Colors.blue,
                                  () {

                                showEditAmenitiesDialog(amenity['id'],amenity['name'],amenity['is_special']);
                              },
                            ),
                            SizedBox(width:5),
                            _buildDecentButton(
                              'Delete',
                              Icons.delete,
                              Colors.redAccent,
                                  () {

                                deleteAmenities(amenity['id']); },
                            ),
                            SizedBox(width:5)
                          ],),

                      ],),
                  ),


                ),
              ),

            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed:()
        {
          amenitiesController.clear();
          isSpecial = false;
          showAmenitiesDialog();
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


