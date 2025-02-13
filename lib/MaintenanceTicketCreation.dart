import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/MaintenanceTicketReport.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'Sidebar.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:mime/mime.dart'; // For MIME type checking
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

class MaintanceType {
  final int id;
  final String name;
  final int serial_id;

  MaintanceType({
    required this.id,
    required this.name,
    required this.serial_id
  });

  // Factory method to create a FollowUpStatus object from JSON
  factory MaintanceType.fromJson(Map<String, dynamic> json) {
    return MaintanceType(
        id: json['id'],
        name: json['name'],
        serial_id:json['serial_id']
    );
  }
}


class MaintenanceTicketCreation extends StatefulWidget
{
  const MaintenanceTicketCreation({Key? key}) : super(key: key);
  @override
  _MaintenanceTicketCreationPageState createState() => _MaintenanceTicketCreationPageState();
}

class _MaintenanceTicketCreationPageState extends State<MaintenanceTicketCreation> with TickerProviderStateMixin {

  MaintanceType? selectedMaintenanceType;

  List<MaintanceType> maintenance_types_list = [];

  TextEditingController _descriptionController = TextEditingController();
  // TextEditingController _totalamountController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      isVisibleNoRoleFound = false;

  String name = "",email = "";

  bool selectAll = false;

   List<dynamic> flats = [];

  Map<String, dynamic>? selectedFlat; // Stores the selected flat object

  List<dynamic> _attachment = []; // List to store selected images

  final ImagePicker _picker = ImagePicker();

  void _showFlatPicker(BuildContext context) {
    if (flats == null || flats.isEmpty) {
      print("Flats list is empty or null: $flats"); // Debugging statement
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No flats available to select."))
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height / 2,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unit(s)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: appbar_color),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Done',
                      style: TextStyle(fontSize: 16, color: appbar_color, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[300]),

            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: flats.indexWhere((flat) =>
                  flat['flat_masterid'] == (selectedFlat?['flat_masterid'] ?? 0)),
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedFlat = flats[index];
                    print('Selected flat ID: ${flats[index]['flat_masterid']}');
                  });
                },
                children: flats.map((flat) {
                  return Center(
                    child: Text(
                      '${flat['flats']['flat_name'] ?? "Unknown"} | '
                          '${flat['flats']['building_masterid']?.toString() ?? "N/A"}',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchMaintenanceTypes() async {

    maintenance_types_list.clear();

    final url = '$BASE_URL_config/v1/maintenanceTypes'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

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
          List<dynamic> followuplist = data['data']['maintenanceTypes'];

          for (var followup in followuplist) {

            MaintanceType maintenanceType = MaintanceType.fromJson(followup);

            // Add the object to the list
            maintenance_types_list.add(maintenanceType);

          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }
  }

  Future<void> fetchUnits() async {

    flats.clear();

    print('user id $user_id');

    final url = '$BASE_URL_config/v1/users/$user_id?company_id=$company_id'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    print('url $url');

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final Map<String, dynamic> data = json.decode(response.body);
        print('data: $data');
        setState(() {
          Map<String, dynamic> user = data['data']['user'];

           flats = user['allowed_flats'];

          // Select first flat
           selectedFlat = flats.isNotEmpty ? flats[0] : {};

        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }
  }

  Future<void> _pickImages({bool fromCamera = false}) async {
    List<XFile>? pickedFiles;

    if (fromCamera) {
      // Capture a single image
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        pickedFiles = [file]; // Convert single file to a list
      }
    } else {
      // Pick multiple images from gallery (works for Web & Mobile)
      pickedFiles = await _picker.pickMultiImage();
    }

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        setState(() {
          if (kIsWeb) {
            _handleWebFile(file);
          } else {
            _handleMobileFile(file);
          }
        });
      }
    }
  }

  void _handleMobileFile(XFile file) {
    File newFile = File(file.path);

    setState(() {
      if (!_attachment.any((existingFile) => existingFile is File && existingFile.path == newFile.path)) {
        _attachment.add(newFile);
      }
    });
  }

  Future<void> _handleWebFile(XFile file) async {
    Uint8List bytes = await file.readAsBytes();

    setState(() {
      if (!_attachment.any((existingFile) => existingFile is Uint8List && listEquals(existingFile, bytes))) {
        _attachment.add(bytes);
      }
    });
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16, top: 20, right: 20, bottom: 50),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachmentOption(
                    icon: Icons.upload,
                    label: 'Upload',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(); // Pick images from gallery (works for Web & Mobile)
                    },
                  ),
                  if (!kIsWeb) // Camera option is not supported on Web
                    _attachmentOption(
                      icon: Icons.camera_alt,
                      label: 'Capture',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImages(fromCamera: true); // Capture image using camera
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /*void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Control the height based on content
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16,top: 20,right: 20,bottom: 50),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.upload, size: 40, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Upload'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(ImageSource.gallery); // Open gallery to pick multiple images
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black, // Set the background color
                            shape: BoxShape.circle, // Make it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Shadow color
                                blurRadius: 8, // Shadow blur
                                offset: Offset(4, 4), // Shadow position
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.camera_alt, size: 40, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Capture'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }*/

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {

    fetchUnits();
    fetchMaintenanceTypes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
        backgroundColor: const Color(0xFFF2F4F8),
        appBar: AppBar(
          backgroundColor: appbar_color.withOpacity(0.9),
          automaticallyImplyLeading: false,
          leading: GestureDetector(
            onTap: ()
            {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MaintenanceTicketReport()),
              );
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),),

          title: Text('Maintenance Ticket',
            style: TextStyle(
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
            color: Colors.white,
            /*decoration:BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Color(0xFFD9FCF6),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
              ),
            ),*/
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /*Container(
                      margin: EdgeInsets.only(left: 20,right: 20,bottom: 3,top: 20),
                      child: Text("Ticket Creation",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28
                      ),)
                    ),

                    Container(
                      margin: EdgeInsets.only(left: 20,right: 20,bottom: 30),
                      child: Text("Create your maintenance ticket",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54
                      ),),
                    ),*/

                    Container(
                      padding: EdgeInsets.only(top: 20),
                      child: GestureDetector(
                        onTap: () {
                          _showFlatPicker(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color: appbar_color.withOpacity(0.1),
                            border: Border.all(
                              color: appbar_color.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedFlat != null && selectedFlat!['flats'] != null ? selectedFlat!['flats']['flat_name'] ?? "Select Flat" : "Select Flat"}'
                                    ' | '
                                    '${selectedFlat != null && selectedFlat!['flats'] != null ? selectedFlat!['flats']['building_masterid']?.toString() ?? "N/A" : "N/A"}',
                                style: TextStyle(
                                  color: appbar_color.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: appbar_color),
                            ])))),

                    Container(
                      margin: EdgeInsets.only(left: 20,right: 20,top: 0),
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
                              Text("Maintenance Type:",
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

                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          margin: EdgeInsets.only(left: 0, right: 0, bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 0.75),
                          ),
                          child: DropdownButtonFormField<MaintanceType>(
                            value: selectedMaintenanceType, // Single selected value
                            items: maintenance_types_list.map((type) {
                              return DropdownMenuItem<MaintanceType>(
                                value: type,
                                child: Text(type.name),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              border: InputBorder.none, // Remove the default border
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                            hint: Text(
                              "Select Maintenance Type",
                              style: TextStyle(color: Colors.black54, fontSize: 16),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedMaintenanceType = value; // Store a single value
                              });}))

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
                        ),*/])),

                    Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          /*Container(
                            margin: EdgeInsets.only( top:0,
                                bottom: 5,
                                left: 20,
                                right: 20),
                            child: Row(
                              children: [
                                Text("Description:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                    )),
                                SizedBox(width: 2),
                                Text(
                                  '*', // Red asterisk for required field
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.red, // Red color for the asterisk
                                  ))])),*/

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
                                  maxLength: 500, // Limit input to 500 characters
                                  maxLines: 3, // A
                                  decoration: InputDecoration(
                                    hintText: 'Enter Description',
                                    labelText: 'Description',
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(11), // Set the border radius
                                      borderSide: BorderSide(
                                        color: Colors.black, // Set the border color
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(11), // Set the border radius
                                      borderSide: BorderSide(
                                        color:  appbar_color, // Set the focused border color
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ))),

                          Container(
                            margin: EdgeInsets.only(left: 20, right: 20),
                            child: Row(
                              children: [
                                Text(
                                  'Attachments',
                                  style: TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.bold,),
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

                          SizedBox(height: 20),

                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_attachment.isNotEmpty)
                                  Column(
                                    children: [
                                      Wrap(
                                        spacing: 12.0, // Horizontal space between items
                                        runSpacing: 12.0, // Vertical space between rows
                                        children: [
                                          ..._attachment.asMap().entries.map((entry) {
                                            int index = entry.key;
                                            var attachment = entry.value; // Can be File (mobile) or Uint8List (web)

                                            return Stack(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey.withOpacity(0.5),
                                                        spreadRadius: 2,
                                                        blurRadius: 5,
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: attachment is File
                                                        ? Image.file(
                                                      attachment, // ✅ Use Image.file for Mobile (File)
                                                      width: 75,
                                                      height: 75,
                                                      fit: BoxFit.cover,
                                                    )
                                                        : Image.memory(
                                                      attachment as Uint8List, // ✅ Use Image.memory for Web (Uint8List)
                                                      width: 75,
                                                      height: 75,
                                                      fit: BoxFit.cover,
                                                    ))),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _attachment.removeAt(index);
                                                      });
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.black.withOpacity(0.7), // Semi-transparent black
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.3), // Soft shadow
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                      padding: EdgeInsets.all(4), // Slightly larger padding for better touch target
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 15,
                                                        color: Colors.white70, // Soft white color for the icon
                                                      ))))]);}).toList(),

                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              shape: CircleBorder(),
                                              padding: EdgeInsets.all(16),
                                              elevation: 5,
                                              backgroundColor: Colors.white,
                                            ),
                                            onPressed: () {
                                              _showAttachmentOptions(context);
                                            },
                                            child: Icon(
                                              Icons.add,
                                              size: 30,
                                              color: appbar_color,
                                            ))])])
                                else
                                  Column(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: CircleBorder(),
                                          padding: EdgeInsets.all(16),
                                          elevation: 8,
                                          backgroundColor: appbar_color,
                                        ),
                                        onPressed: () {
                                          _showAttachmentOptions(context);
                                        },

                                        child: Icon(
                                          Icons.attach_file,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text('No attachment selected'),
                                    ])]))]),

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
                                style: TextStyle(
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
                                  style: TextStyle(
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
                          sendFormData();
                        }
                      },
                      child: Text('Submit',
                          style: TextStyle(
                              color: Colors.white
                          )),
                    ))
                    ])
                    )
                    )
                    );}


          bool isValidImage(dynamic file) {
            final validExtensions = ['jpg', 'jpeg', 'png'];

            if (file is File) {
              // For mobile, check the file extension

              final extension = file.path.split('.').last.toLowerCase();
              return validExtensions.contains(extension);
            } else if (file is Uint8List) {
              // For web, check the MIME type
              final mimeType = lookupMimeType('', headerBytes: file);
              return mimeType != null && mimeType.startsWith('image/');
            }
            return false;
          }

          Future<void> sendFormData() async {

          try {
            final String url = "$BASE_URL_config/v1/maintenance";

            var uuid = Uuid();
            String uuidValue = uuid.v4();

            final Map<String, dynamic> requestBody = {
              "uuid": uuidValue,
              "maintenance_type_id": selectedMaintenanceType!.id,
              "flat_masterid": selectedFlat?['flat_masterid'],
              "description": _descriptionController.text,
            };

            final response = await http.post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $Company_Token",
              },
              body: jsonEncode(requestBody),
            );

            if (response.statusCode == 201) {
              print('Ticket successful');
              Map<String, dynamic> decodedResponse = jsonDecode(response.body);
              int ticketId = decodedResponse['data']['ticket']['id'];

              // ✅ Call sendImageData in a separate request
              await sendImageData(ticketId);
            } else {
              print('Upload failed with status code: ${response.statusCode}');
              print('Upload failed with response: ${response.body}');
            }
          } catch (e) {
            print('Error during upload: $e');
          }
        }

        String getMimeType(String path) {
          final mimeType = lookupMimeType(path);
          return mimeType?.split('/').last ?? 'jpeg'; // Default to JPEG
        }

  Future<void> sendImageData(int id) async {
    try {
      final String urll = "$BASE_URL_config/v1/maintenance/uploads/$id";
      final url = Uri.parse(urll);

      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $Company_Token', // Authentication token
      });

      // ✅ Ensure only valid images are uploaded
      _attachment = _attachment.where(isValidImage).toList();

      for (var file in _attachment) {
        if (file is File) {
          // ✅ Mobile (iOS & Android) - Use file path
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              file.path,
              filename: basename(file.path),
              contentType: MediaType('image', getMimeType(file.path)),
            ),
          );
        } else if (file is Uint8List) {
          // ✅ Web - Use in-memory file
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              file,
              filename: 'web_image_${DateTime.now().millisecondsSinceEpoch}.png',
              contentType: MediaType('image', 'png'), // Defaulting to PNG
            ),
          );
        }
      }

      // ✅ Send request & handle response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        print('Image upload successful');
      } else {
        print('Upload failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error during upload: $e');
    }
  }

// Helper widget for attachment options
Widget _attachmentOption({required IconData icon, required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(4, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Icon(icon, size: 40, color: appbar_color),
        ),
        SizedBox(height: 8),
        Text(label),
      ],
    ),
  );
}}