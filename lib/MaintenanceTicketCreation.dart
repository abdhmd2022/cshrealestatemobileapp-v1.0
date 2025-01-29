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
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:uuid/uuid.dart';
import 'Sidebar.dart';
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

  List<MaintanceType> selectedMaintenanceTypes = [];

   List<MaintanceType> maintenance_types_list = [

  ];

  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _totalamountController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoRoleFound = false;

  String name = "",email = "";

  bool selectAll = false;

   List<dynamic> flats = [];

  Map<String, dynamic>? selectedFlat; // Stores the selected flat object

  void _showFlatPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height/2,
        width: double.infinity, // Ensure the modal occupies full width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Picker Header
            Padding(
              padding: const EdgeInsets.all(26.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unit(s)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: appbar_color.withOpacity(1.0),),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        color: appbar_color.withOpacity(1.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cupertino Picker
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: flats.indexOf(selectedFlat), // Pre-select current flat
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedFlat = flats[index]; // Update the selected flat
                    print('selected id of flat ${flats[index]['cost_centre_masterid']}');
                  });
                },
                children: flats.map((flat) {
                  return Center(
                    child: Text(
                      'Unit ${flat['flat_name']} | Building ${flat['building_masterid']}',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ))])));}


  Future<void> fetchMaintenanceTypes() async {

    maintenance_types_list.clear();

    final url = '$BASE_URL_config/v1/maintenanceTypes'; // Replace with your API endpoint
    String token = 'Bearer $Serial_Token'; // auth token for request

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

    final url = '$BASE_URL_config/v1/serials/flats'; // Replace with your API endpoint
    String token = 'Bearer $Serial_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          flats = data['data']['flats'];
          selectedFlat = flats[0];
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }
  }
  
  // Function to toggle Select All option
  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      if (selectAll) {
        selectedMaintenanceTypes = List<MaintanceType>.from(maintenance_types_list);
      } else {
        selectedMaintenanceTypes.clear();
      }
    });




  }


  List<File> _attachment = []; // List to store selected images
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages(ImageSource source) async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(); // Pick multiple images
    if (pickedFiles != null) {
      setState(() {
        for (var file in pickedFiles) {
          File newFile = File(file.path);

          // Debug print to check paths
          print('Existing paths: ${_attachment.map((file) => file.path).toList()}');
          print('New file path: ${newFile.path}');

          // Check if the image is already in the list
          if (!_attachment.any((existingFile) => existingFile.path == newFile.path)) {
            _attachment.add(newFile); // Add the image if it's not a duplicate
            print('Added: ${newFile.path}'); // Debug to confirm addition
          } else {
            print('Skipped duplicate: ${newFile.path}'); // Debug for duplicates
          }
        }
      });
    }
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
                            color: Colors.white, // Set the background color
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
                          child: Icon(Icons.upload, size: 40, color: Colors.blueAccent),
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
                            color: Colors.white, // Set the background color
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
                          child: Icon(Icons.camera_alt, size: 40, color: Colors.blueAccent),
                        ),
                        SizedBox(height: 8),
                        Text('Capture'),
                      ],
                    ),
                  ),
                ],
              ),
            ] ));});}

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
            Username: name,
            Email: email,
            tickerProvider: this),

        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
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
                      padding: EdgeInsets.only(top:20),
                      child:GestureDetector(
                        onTap: ()
                          {
                            _showFlatPicker(context);
                          },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color: Colors.blue.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Unit ${selectedFlat?['flat_name']} | Building ${selectedFlat?['building_masterid']}',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.blue),
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
                          child: MultiSelectDialogField(

                            items: maintenance_types_list
                                .map((type) => MultiSelectItem<MaintanceType>(type, type.name))
                                .toList(),
                            initialValue: selectedMaintenanceTypes,
                            title: Text("Maintenance Type(s)"),
                            searchable: true,
                            selectedColor: appbar_color,
                            confirmText: Text(
                              "Confirm",
                              style: TextStyle(color: appbar_color), // Custom confirm button text color
                            ),
                            cancelText: Text(
                              "Cancel",
                              style: TextStyle(color: appbar_color), // Custom cancel button text color
                            ),
                            buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                            buttonText: Text(
                              "Select Maintenance Type(s)",
                              style: TextStyle(color: Colors.black54, fontSize: 16),
                            ),
                            onConfirm: (values) {
                              setState(() {
                                selectedMaintenanceTypes = List<MaintanceType>.from(values); // Correct type
                              });
                            },
                            chipDisplay: MultiSelectChipDisplay(
                              onTap: (value) {
                                setState(() {
                                  selectedMaintenanceTypes.remove(value);
                                });
                              },
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                            ),
                            // We manage Select All outside of MultiSelectDialogField
                          ),
                        )
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
                      ],
                    ),),

                    Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[

                          Container(
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
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10), // Set the border radius
                                      borderSide: BorderSide(
                                        color: Colors.black, // Set the border color
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
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
                                            File attachment = entry.value;
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
                                                    child: Image.file(
                                                      attachment, // Use Image.file for actual file
                                                      width: 75,
                                                      height: 75,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
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
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
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
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: CircleBorder(),
                                          padding: EdgeInsets.all(16),
                                          elevation: 8,
                                          backgroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          _showAttachmentOptions(context);
                                        },
                                        child: Icon(
                                          Icons.attach_file,
                                          size: 30,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text('No attachment selected'),
                                    ],
                                  ),
                              ],
                            ),
                          )





                        ]),

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
                    ),)
                  ])
            )
            )
    );}


  bool isValidImage(File file) {
    final validExtensions = ['jpg', 'jpeg', 'png'];
    final extension = file.path.split('.').last.toLowerCase();
    return validExtensions.contains(extension);
  }

  Future<void> sendFormData() async {

    // Send the request
    try {
    final String url = "$BASE_URL_config/v1/maintenance";

    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();

    final Map<String, dynamic> requestBody = {
      "uuid": uuidValue,
      "maintenance_type_id": selectedMaintenanceTypes.map((type) => type.id).join(','),
      "flat_masterid": selectedFlat?['cost_centre_masterid'],
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

        print('ticket successful');
        Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        int ticketId = decodedResponse['data']['ticket']['id'];
        sendImageData(ticketId);

      }
      else {
        print('Upload failed with status code: ${response.statusCode}');
        print('Upload failed with status body: ${response.request}');

      }
    } catch (e) {
      print('Error during upload: $e');
    }
  }

  Future<void> sendImageData(int id) async {

    final String urll = "$BASE_URL_config/v1/maintenance/uploads/$id";

    final url = Uri.parse(urll); // Replace with your API URL

    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Authorization': 'Bearer $Company_Token', // Replace with your token
      'Content-Type': 'multipart/form-data', // Optional, depends on the server
    });

    _attachment = _attachment.where(isValidImage).toList();

    // Add images from _attachment
    for (var file in _attachment) {
      request.files.add(await http.MultipartFile.fromPath(
        'images', // The field name the backend expects
        file.path,
        filename: basename(file.path),
        contentType: MediaType('image', 'jpeg'), // Specify MIME type (e.g., 'image/jpeg', 'image/png')
      ));
    }

    print('\nRequest Files:');
    for (var file in request.files) {
      print('Field Name: ${file.field}');
      print('File Name: ${file.filename}');
      print('File Length: ${file.length}');
    }

    // Send the request
    try {
      final response = await request.send();
      if (response.statusCode == 201) {
        print('Upload successful');
      } else {
        print('Upload failed with status code: ${response.statusCode}');
        print('Upload failed with status body: ${response.request}');

      }
    } catch (e) {
      print('Error during upload: $e');
    }
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
