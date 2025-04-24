import 'dart:convert';
import 'dart:io';
import 'package:cshrealestatemobile/MaintenanceTicketReport.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'Sidebar.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:mime/mime.dart'; // For MIME type checking
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:google_fonts/google_fonts.dart';


class MaintanceType {
  final int id;
  final String name;
  final String category;

  MaintanceType({
    required this.id,
    required this.name,
    required this.category
  });

  // Factory method to create a FollowUpStatus object from JSON
  factory MaintanceType.fromJson(Map<String, dynamic> json) {
    return MaintanceType(
        id: json['id'],
        name: json['name'],
        category:json['category']
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

  List<MaintanceType>? selectedMaintenanceType = [];

  late SharedPreferences prefs;

  List<MaintanceType> maintenance_types_list = [];
  List<int> selectedMaintenanceTypeIds = []; // Store selected maintenance type IDs

late int loaded_flat_id;
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
    if (flats.isEmpty) {
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
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: appbar_color),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(fontSize: 16, color: appbar_color, fontWeight: FontWeight.bold),
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
                  flat['flat_id'] == (selectedFlat?['flat_id'] ?? 0)),
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedFlat = flats[index];
                    print('Selected Flat ID: ${flats[index]['flat_id']}');
                    print('Selected Contract ID: ${flats[index]['contract_id']}');
                  });
                },
                children: flats.map((flat) {
                  // Extract building name if available
                  String buildingName = flat['building_name'].toString() ?? "Unknown";

                  return Center(
                    child: Text(
                      '${flat['tenant_name']} | ${flat['flat_name'] ?? "Unknown"} | '
                          '$buildingName',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }).toList(),
              ))])));
  }

  Future<void> fetchMaintenanceTypes() async {

    maintenance_types_list.clear();

    final url = '$baseurl/maintenance/maintenanceType'; // Replace with your API endpoint
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
          List<dynamic> maintenanceTypes = data['data']['maintenanceTypes'];

          for (var type in maintenanceTypes) {

            MaintanceType maintenanceType = MaintanceType.fromJson(type);

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

    String url = is_admin
        ? '$baseurl/tenant'
        : '$baseurl/tenant/$user_id';

    String token = 'Bearer $Company_Token'; // Auth token for request

    print('url $url');

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('code ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('data: $data');

        setState(() {
          flats.clear();

          if (is_admin) {
            // Case when is_admin = true
            List<dynamic> tenants = data['data']['tenants'];

            for (var tenant in tenants) {
              String tenantName = tenant['name'];

              if (tenant['contracts'] != null && tenant['contracts'].isNotEmpty) {
                for (var contract in tenant['contracts']) {
                  int contractId = contract['id']; // Extract contract ID

                  if (contract['flats'] != null) {
                    for (var flatData in contract['flats']) {
                      var flat = flatData['flat'];
                      flats.add({
                        'tenant_name': tenantName,
                        'flat_id': flat['id'],
                        'flat_name': flat['name'],
                        'building_name': flat['building']['name'], // Store building ID
                        'contract_id': contractId, // Include contract ID
                      });
                    }
                  }
                }
              }
            }
          } else {
            // Case when is_admin = false
            var tenant = data['data']['tenant'];

            if (tenant != null) {
              String tenantName = tenant['name'];
              if (tenant['contracts'] != null) {
                for (var contract in tenant['contracts']) {
                  int contractId = contract['id']; // Extract contract ID

                  if (contract['flats'] != null) {
                    for (var flatData in contract['flats']) {
                      var flat = flatData['flat'];
                      flats.add({
                        'tenant_name': tenantName,
                        'flat_id': flat['id'],
                        'flat_name': flat['name'],
                        'building_name': flat['building']['name'], // Store building ID
                        'contract_id': contractId, // Include contract ID
                      });
                    }}}
              }}
          }

          // Select first flat if available
          selectedFlat = flats.firstWhere(
                (flat) => flat['flat_id'] == loaded_flat_id ,
            orElse: () => flats.isNotEmpty ? flats[0] : {},
          );
        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchContracts() async {
    flats.clear();

    print('user id $user_id');

    String url = is_admin
        ? '$adminurl/tenant'
        : '$adminurl/tenant/$user_id';

    String token = 'Bearer $Company_Token'; // auth token for request

    print('url $url');

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('code ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('data: $data');

        setState(() {
          flats.clear();

          if (is_admin) {
            // Handle multiple tenants case
            List<dynamic> tenants = data['data']['tenants'];
            for (var tenant in tenants) {
              String tenantName = tenant['name'];

              if (tenant['flats'] != null) {
                for (var flatData in tenant['flats']) {
                  var flat = flatData['flat'];
                  flats.add({
                    'tenant_name': tenantName,
                    'flat_id': flat['id'],
                    'flat_name': flat['name'],
                    'building_name': flat['building_name'],
                  });
                }
              }
            }
          } else {
            // Handle single tenant case
            var tenant = data['data']['tenant'];
            if (tenant != null) {
              String tenantName = tenant['name'];

              if (tenant['flats'] != null) {
                for (var flatData in tenant['flats']) {
                  var flat = flatData['flat'];
                  flats.add({
                    'tenant_name': tenantName,
                    'flat_id': flat['id'],
                    'flat_name': flat['name'],
                    'building_name': flat['building_name'],
                  });
                }
              }
            }
          }

          // Select first flat if any
          selectedFlat = flats.isNotEmpty ? flats[0] : {};
        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  /*Future<void> fetchUnits() async {
    flats.clear();

    print('user id $user_id');

    String url = is_admin
        ? '$adminurl/tenant'
        : '$adminurl/tenant/$user_id';

    String token = 'Bearer $Company_Token'; // auth token for request

    print('url $url');

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('code ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('data: $data');

        setState(() {
          flats.clear();
          List<dynamic> tenants = data['data']['tenant'];

          for (var tenant in tenants) {
            String tenantName = tenant['name']; // Get tenant name

            if (tenant['flats'] != null) {
              for (var flatData in tenant['flats']) {
                var flat = flatData['flat'];
                flats.add({
                  'tenant_name': tenantName,
                  'flat_id': flat['id'],
                  'flat_name': flat['name'],
                  'building_name': flat['building_name'],
                });
              }
            }
          }

          // Select first flat if any
          selectedFlat = flats.isNotEmpty ? flats[0] : {};
        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }*/

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
     prefs = await SharedPreferences.getInstance();
     loaded_flat_id = prefs.getInt('flat_id') ?? 0;

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
            style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 28
                      ),)
                    ),

                    Container(
                      margin: EdgeInsets.only(left: 20,right: 20,bottom: 30),
                      child: Text("Create your maintenance ticket",
                      style: GoogleFonts.poppins(
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
                              Flexible(
                                child: Text(
                                  selectedFlat != null
                                      ? '${selectedFlat!['tenant_name'] ?? "Unknown Tenant"} | '
                                      '${selectedFlat!['flat_name'] ?? "Unknown Flat"} | '
                                      '${selectedFlat?['building_name'] ?? "Unknown Building"}'
                                      : "Select Flat",
                                  style: GoogleFonts.poppins(
                                    color: appbar_color.shade700,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Truncate if too long
                                  maxLines: 1, // Ensure it stays on one line
                                  softWrap: false, // Prevents text from wrapping to a new line
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: appbar_color),
                            ],
                          ),
                        ),
                      ),
                    ),



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
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16

                                  )
                              ),
                              SizedBox(width: 2),
                              Text(
                                '*', // Red asterisk for required field
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  color: Colors.red, // Red color for the asterisk
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                            margin: EdgeInsets.only(left: 0, right: 0, bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black54, width: 0.75),
                            ),
                            child: MultiSelectDialogField<MaintanceType>(
                              items: maintenance_types_list
                                  .map((type) => MultiSelectItem<MaintanceType>(type, type.name))
                                  .toList(),
                              title: Text("Maintenance Types"),
                              selectedColor: appbar_color,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(8))
                              ),
                              buttonIcon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.black,
                              ),
                              buttonText: Text(
                                "Select Maintenance Type",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                                initialValue: selectedMaintenanceType!, // ✅ Keeps selected values

                                onConfirm: (List<MaintanceType> values) {
                                setState(() {
                                  selectedMaintenanceType = values; // ✅ Stores selected values


                                selectedMaintenanceTypeIds = values.map((type) => type.id).toList();
                                });
                              }))
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
                        ),*/
                      ])),

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
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                    )),
                                SizedBox(width: 2),
                                Text(
                                  '*', // Red asterisk for required field
                                  style: GoogleFonts.poppins(
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
                                    floatingLabelStyle: GoogleFonts.poppins(
                                      color: appbar_color, // Change label color when focused
                                      fontWeight: FontWeight.normal,
                                    ),
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
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ))),

                          Container(
                            margin: EdgeInsets.only(left: 20, right: 20),
                            child: Row(
                              children: [
                                Text(
                                  'Attachments',
                                  style: GoogleFonts.poppins(fontSize: 16,
                                    fontWeight: FontWeight.bold,),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '*', // Red asterisk for required field
                                  style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                                  style: GoogleFonts.poppins(
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
                          if(maintenance_types_list.isEmpty)
                            {
                              String message = 'Select atleast 1 maintenance type';
                              Fluttertoast.showToast(
                                msg: message,
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 16.0,
                              );
                            }
                          else if(_descriptionController.text.isEmpty)
                            {
                              String message = 'Enter description';
                              Fluttertoast.showToast(
                                msg: message,
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 16.0,
                              );
                            }
                          else if(_attachment.isEmpty)
                            {
                              String message = 'Attachment is missing';
                              Fluttertoast.showToast(
                                msg: message,
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM, // Change to CENTER or TOP if needed
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 16.0,
                              );
                            }
                          else
                            {
                              sendFormData(context);
                            }
                        }
                      },
                      child: Text('Submit',
                          style: GoogleFonts.poppins(
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

          Future<void> sendFormData(BuildContext context) async {

          try {

            String url = is_admin
                ? "$baseurl/maintenance/ticket"
                : "$baseurl/maintenance/ticket";

            var uuid = Uuid();
            String uuidValue = uuid.v4();

            print('type list ${selectedMaintenanceTypeIds}');

            final Map<String, dynamic> requestBody = {
              "uuid": uuidValue,
              "flat_id": selectedFlat?['flat_id'], // Updated key from flat_masterid to flat_id
              "description": _descriptionController.text,
              "types": selectedMaintenanceTypeIds, // Converts the list of objects to a list of IDs
              "contract_id": selectedFlat?['contract_id']
            };

            final response = await http.post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $Company_Token",
              },
              body: jsonEncode(requestBody),
            );

            print('body: ${jsonEncode(requestBody)}');
            Map<String, dynamic> decodedResponse = jsonDecode(response.body);
            if (response.statusCode == 201) {

              setState(() {
                selectedMaintenanceType = [];
                selectedMaintenanceTypeIds = [];
                _descriptionController.clear();
                selectedFlat = flats[0];
                _attachment.clear();
              });
              showResponseSnackbar(context, decodedResponse);

              int ticketId = decodedResponse['data']['ticket']['id'];

              // ✅ Call sendImageData in a separate request
              await sendImageData(ticketId,context);
            } else {

              showResponseSnackbar(context, decodedResponse);

              /*showSnackBar("Status Code: ${response.statusCode} and Response: ${response.body}");*/
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

  Future<void> sendImageData(int id,BuildContext context) async {
    try {
      final String urll = "$baseurl/uploads/ticket/$id";
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
      Map<String, dynamic> decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 201) {




        setState(() {
          selectedMaintenanceType = [];
          selectedMaintenanceTypeIds = [];
          _descriptionController.clear();
          selectedFlat = flats[0];
          _attachment.clear();
        });
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
}

}

