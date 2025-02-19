import 'dart:convert';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'SalesInquiryReport.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_switch/flutter_switch.dart';

class InquiryStatus {
  final int id;
  final String name;
  final String category;

  InquiryStatus({
    required this.id,
    required this.name,
    required this.category
  });

  // Factory method to create a FollowUpStatus object from JSON
  factory InquiryStatus.fromJson(Map<String, dynamic> json) {
    return InquiryStatus(
      id: json['id'],
      name: json['name'],
        category: json['category'],
    );
  }
}

class ActivitySource {
  final int id;
  final String name;

  ActivitySource({
    required this.id,
    required this.name,
  });

  // Factory method to create a FollowUpStatus object from JSON
  factory ActivitySource.fromJson(Map<String, dynamic> json) {
    return ActivitySource(
      id: json['id'],
      name: json['name'],
    );
  }
}

class CreateSalesInquiry extends StatefulWidget {

  @override
  State<CreateSalesInquiry> createState() => _CreateSaleInquiryPageState();
}

class _CreateSaleInquiryPageState extends State<CreateSalesInquiry> {

  final _formKey = GlobalKey<FormState>();

  // text editing controllers intialization
  final customernamecontroller = TextEditingController();
  final customercontactnocontroller = TextEditingController();
  final whatsappnocontroller = TextEditingController();

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

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  String? selectedasignedto;

  bool isUnitSelected = false;

  bool isAllUnitsSelected = false;

  bool _useContactAsWhatsapp = true;


  double? range_min, range_max;

  InquiryStatus? selectedinquiry_status;

  ActivitySource? selectedactivity_source;

  DateTime? nextFollowUpDate;

  bool isEmirateSelected = false;

  bool isAreasSelected = false;

  RangeValues _currentRangeValues = RangeValues(0, 100); // Default values

  SharedPreferences? prefs;

  List<InquiryStatus> inquirystatus_list = [];

  List<ActivitySource> activitysource_list = [

  ];

  bool isAllEmiratesSelected = false;

  bool isAllAreasSelected = false;

  String? selectedEmirate;

  bool _isFocused_email = false,_isFocus_name = false;

  bool _isLoading = false;

  List<Map<String, dynamic>> emirates = [

  ];

  List<String> asignedto = [
    'Self',
  ];

  List<Map<String, dynamic>> unitTypes = [];

  Map<String, List<Map<String, dynamic>>> areas = {

  };

  String selectedUnitType = "Select Unit Types";
  String selectedEmiratesString = "Select Emirate";
  String selectedAreasString = "Select Area";

  List<Map<String, dynamic>> selectedEmiratesList = []; // Store objects with 'id' and 'label'
  List<Map<String, dynamic>> selectedAreas = []; // Store objects with 'id' and 'label'

  final List<Map<String, dynamic>> preferences = [];
  final List<Map<String, dynamic>> amenities = [];

   Set<int> selectedPreferences = {};
   Set<int> selectedAmenities = {};

  final List<String> interestTypes = ["Rent", "Buy"]; // List of options


  final List<String> propertyType = [
    'Residential',
    'Commercial',
  ];
  int? selectedInterestType = 0;




  List<int> selectedUnitIds = [];

  List<Map<String, dynamic>>? filteredEmirates;
  List<Map<String, dynamic>>? filteredAreas;

  List<Map<String, dynamic>> areasToDisplay = []; // Global variable

  String _selectedCountryCode = '+971'; // Default to UAE country code
  String _selectedCountryCodeWhatsapp = '+971'; // Default to UAE country code

  String _selectedCountryFlag = '🇦🇪'; // Default UAE flag emoji
  String _selectedCountryFlagWhatsapp = '🇦🇪'; // Default UAE flag emoji

  String _hintText = 'Enter Contact No'; // Default hint text

  String _hintTextWhatsapp = 'Enter Whatsapp No'; // Default hint text

  void updateAreasDisplay() {
    areasToDisplay.clear();

    selectedEmiratesList.forEach((emirate) {
      areasToDisplay.addAll(areas[emirate['label']] ?? []);
    });

    // Reset areas not belonging to the selected emirates
    areas.forEach((emirate, areaList) {
      if (!selectedEmiratesList.any((e) => e['label'] == emirate)) {
        areaList.forEach((area) {
          area['isSelected'] = false;
        });
      }
    });

    // Update selectedAreasString based on updated areasToDisplay
    final selectedAreaLabels = areasToDisplay
        .where((area) => area['isSelected'])
        .map((area) => area['label'] as String)
        .toList();

    selectedAreasString = selectedAreaLabels.isEmpty ? "Select Area" : selectedAreaLabels.join(', ');
  }

  void loadAreasFromJson(dynamic jsonResponse) {
    try {
      final areasFromResponse = jsonResponse['data']?['areas'] as List<dynamic>? ?? [];

      areas.clear(); // Clear existing areas

      for (var area in areasFromResponse) {
        final emirateName = area['state']?['name'] ?? '';
        if (emirateName.isNotEmpty) {
          areas.putIfAbsent(emirateName, () => []); // Add emirate key if not already present
          areas[emirateName]!.add({
            "label": area['name'] ?? '',
            "id": area['id'] ?? '',
            "isSelected": false,
          });
        }
      }

      print("Areas loaded successfully: $areas");
    } catch (e) {
      print("Error loading areas: $e");
    }
  }

  void populateEmiratesList(dynamic jsonResponse) {
    try {
      // Safely extract the "emirates" list
      final emiratesFromResponse = jsonResponse['data']?['states'] as List<dynamic>?;

      if (emiratesFromResponse == null || emiratesFromResponse.isEmpty) {
        print("No emirates data found in the response.");
        return; // Exit if there's no data
      }

      // Map the "state_name" into the "emirates" list format
      emirates = emiratesFromResponse.map((emirate) {
        return {

          "label": emirate['name'] ?? '', // Fallback to empty string if state_name is null
          "id": emirate['id'] ?? '',
          "isSelected": false, // Default to not selected
        };
      }).toList();

      print('Emirates list populated successfully. Total Emirates: ${emirates.length}');
    } catch (e) {
      // Log the error for debugging
      print('Error populating Emirates list: $e');
    }
  }

  void fetchFlatTypes(dynamic jsonResponse) {
    final data = jsonResponse is String
        ? jsonDecode(jsonResponse)
        : jsonResponse;

    if (data != null && data['data'] != null && data['data']['flatTypes'] != null) {
      final flatTypes = data['data']['flatTypes'] as List<dynamic>;

      unitTypes = flatTypes
          .map((flat) => {
        'label': flat['name'], // Flat type name
        'id': flat['id'], // ID value
        'isSelected': false, // Default selection state
      })
          .toList();
    } else {
      print('Error: Invalid data structure');
    }
  }


  Future<void> fetchEmirates() async {

    print('fetching emirates');

    emirates.clear();

    final url = '$BASE_URL_config/v1/masters/states'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {


        final data = jsonDecode(response.body);
        setState(() {
          populateEmiratesList(data);

        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }
  }

  Future<void> fetchAreas() async {

    print('fetching areas');

    areas.clear();

    final url = '$BASE_URL_config/v1/masters/areas'; // Replace with your API endpoint
    String token = 'Bearer $Company_Token'; // auth token for request

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };
    try {
      final response = await http.get(Uri.parse(url),
        headers: headers,);
      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        setState(() {
          loadAreasFromJson(data);

        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
        throw Exception('Failed to load data');
      }
    } catch (e) {


      print('Error fetching data: $e');
    }
  }


  void _updateRangeFromTextFields() {
    // Parse start and end values, defaulting to range_min and range_max if invalid
    double start = double.tryParse(startController.text) ?? range_min!;
    double end = double.tryParse(endController.text) ?? range_max!;

    // Constrain start and end to the min and max values
    start = start.clamp(range_min!, range_max!);
    end = end.clamp(range_min!, range_max!);

    // Ensure start value is less than or equal to end value
    if (start > end) {
      end = start;
    }

    setState(() {
      _currentRangeValues = RangeValues(start, end);
    });
  }

  String? selectedPropertyType;

  Future<void> sendCreateInquiryRequest() async {


    // converting amenities set to list
    final List<int> amenitiesList = selectedPreferences.union(selectedAmenities).toList();

    List<int> emiratesIds = selectedEmiratesList.map((emirate) => emirate['id'] as int).toList();

    List<int> areasIds = selectedAreas.map((area) => area['id'] as int).toList();

    //converting date to yyyy-MM-dd format
    String? formattedDate;
    if (nextFollowUpDate != null) {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      formattedDate = formatter.format(nextFollowUpDate!);
    } else {
      formattedDate = null;
    }

    // Replace with your API endpoint
    final String url = "$BASE_URL_config/v1/leads";

    var uuid = Uuid();

    // Generate a v4 (random) UUID
    String uuidValue = uuid.v4();

    // Constructing the JSON body
    final Map<String, dynamic> requestBody = {
      "uuid": uuidValue,
      "name": customernamecontroller.text,
      "email": emailcontroller.text,
      "mobile_no": '$_selectedCountryCode${customercontactnocontroller.text}',
      "areas": areasIds,
      "flatTypes": selectedUnitIds,
      "status_id": selectedinquiry_status!.id,
      "next_followup_date": formattedDate,
      "property_type": selectedPropertyType,
      "interest_type": interestTypes[selectedInterestType ?? 0],
      "max_price": _currentRangeValues!.end.round().toString(),
      "min_price": _currentRangeValues!.start.round().toString(),
      "amenities": amenitiesList,
      "description" : descriptioncontroller.text,
      'activity_source_id' : selectedactivity_source!.id
    };


    print('create request body $requestBody');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Company_Token",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Request was successful
        print("Response Data: ${response.body}");
        setState(() {

          _formKey.currentState?.reset();
          selectedasignedto = asignedto.first;
          selectedinquiry_status = null;
          selectedInterestType = 0;
          selectedPropertyType = null;
          selectedactivity_source = null;
          nextFollowUpDate = null;
          selectedUnitIds.clear();

          selectedUnitType = "Select Unit Types";
          selectedEmiratesString = "Select Emirate";
          selectedEmiratesList.clear();

          for (var emirate in emirates) {
            emirate['isSelected'] = false;
          }
          isAllEmiratesSelected = false;

          // Reset areas automatically
          clearAreas();



          updateAreasDisplay();

          updateAreasSelection();

          selectedAmenities.clear();
          selectedPreferences.clear();

          range_min = prefs!.getDouble('range_min') ?? 10000;
          range_max = prefs!.getDouble('range_max') ?? 100000;

          double range_start = range_min! + (range_min! / 0.8);
          double range_end = range_max! - (range_max! * 0.2);

          _currentRangeValues = RangeValues(range_start, range_end);

          startController.text = _currentRangeValues!.start.toStringAsFixed(0);
          endController.text = _currentRangeValues!.end.toStringAsFixed(0);

          isAllEmiratesSelected = false;

          _selectedCountryCode = '+971'; // Default to UAE country code
          _selectedCountryFlag = '🇦🇪'; // Default UAE flag emoji

          _selectedCountryCodeWhatsapp = '+971'; // Default to UAE country code
          _selectedCountryFlagWhatsapp = '🇦🇪'; // Default UAE flag emoji


          customernamecontroller.clear();
          customercontactnocontroller.clear();
          emailcontroller.clear();
          unittypecontroller.clear();
          areacontroller.clear();
          descriptioncontroller.clear();

        });

      } else {
        // Error occurred
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");

      }
    } catch (error) {
      print("Exception: $error");
    }
  }


  Future<void> fetchUnitTypes() async {

    print('fetching unit types');
    unitTypes.clear();

    final url = '$BASE_URL_config/v1/masters/flatTypes'; // Replace with your API endpoint
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
          fetchFlatTypes(data);

        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }


  }

  Future<void> fetchActivitySources() async {

    activitysource_list.clear();

    final url = '$BASE_URL_config/v1/activitySources'; // Replace with your API endpoint
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
          List<dynamic> activitySourceList = data['data']['activitySources'];

          for (var status in activitySourceList) {
            // Create a FollowUpStatus object from JSON
            ActivitySource activitySource = ActivitySource.fromJson(status);

            activitysource_list.add(activitySource);

            print('ID: ${activitySource.id}, Name: ${activitySource.name}');
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }
  }

  Future<void> fetchAmenities() async {

    amenities.clear();

    final url = '$BASE_URL_config/v1/amenities'; // Replace with your API endpoint
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


        setState(() {

          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> amenitiesData = data['data']['amenities'];

          for (var item in amenitiesData) {
            if (item['is_special'] == "true") {
              preferences.add(item);
            } else {
              amenities.add(item);
            }
          }
          setState(() {});

        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    };
  }

  Future<void> fetchLeadStatus() async {

    inquirystatus_list.clear();

    final url = '$BASE_URL_config/v1/leadStatus'; // Replace with your API endpoint
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

        print(data);

        setState(() {
          List<dynamic> leadStatusList = data['data']['leadStatus'];

          for (var status in leadStatusList) {
            // Create a FollowUpStatus object from JSON
            InquiryStatus followUpStatus = InquiryStatus.fromJson(status);

            // Add the object to the list
            inquirystatus_list.add(followUpStatus);


            // Optionally, you can print the object for verification
             }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {

      print('Error fetching data: $e');
    }


  }

  void updateEmiratesSelection() {
    setState(() {
      // Check if all Emirates are selected
      isAllEmiratesSelected = emirates.every((emirate) => emirate['isSelected']);

      // Update the selected Emirates text field
      selectedEmiratesString = emirates
          .where((emirate) => emirate['isSelected'])
          .map((emirate) => emirate['label'])
          .join(', ') ?? "Select Emirate";
    });
  }

  void updateAreasSelection() {
    // Reset selected areas if no Emirates are selected
    if (emirates.every((emirate) => !emirate['isSelected'])) {
      selectedAreas.clear();
      selectedAreasString = "Select Area";
    } else {
      selectedAreasString = selectedAreas.isNotEmpty
          ? selectedAreas.join(', ')
          : "Select Area";
    }

    // Update areas visibility based on selected Emirates
    for (var emirate in emirates) {
      if (emirate['isSelected']) {
        String emirateName = emirate['label'];
        // Check if all areas are selected for this emirate
        isAllAreasSelected = areas[emirateName]?.every((area) => area['isSelected']) ?? false;
      }
    }
    setState(() {});
  }

  void updateSelectedAreasString(List<Map<String, dynamic>> filteredAreas)  {
    final selectedAreaLabels = filteredAreas
        .where((area) => area['isSelected'])
        .map((area) => area['label'] as String)
        .toList();

    selectedAreasString = selectedAreaLabels.isEmpty ? "Select Area" : selectedAreaLabels.join(', ');
  }

  void clearAreas() {
    areasToDisplay.clear(); // Reset areas to display
    for (var areaList in areas.values) {
      for (var area in areaList) {
        area['isSelected'] = false;
      }
    }
    selectedAreas.clear();
    selectedAreasString = "Select Area(s)";
  }

  void _openUnitTypeDropdown(BuildContext context) async {
    final selectedItems = await showModalBottomSheet<Map<String, List<dynamic>>>(
      context: context,
      isDismissible: false, // Prevent closing by tapping outside
      enableDrag: false,    // Prevent closing by dragging
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
                      labelStyle: TextStyle(color: Colors.black54),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),

                        borderSide: BorderSide(color: appbar_color.withOpacity(0.5)), // BlueGrey border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color.withOpacity(0.5)),
                        // BlueGrey focused border color
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
                        activeColor: appbar_color,

                        value: isAllUnitsSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            isAllUnitsSelected = value ?? false;
                            // Update all unit types based on Select All
                            for (var unit in unitTypes) {
                              unit['isSelected'] = isAllUnitsSelected;
                            }
                          });}))),
                SizedBox(height: 15),
                Expanded(
                  child: ListView(
                    children: filteredUnitTypes.map((unit) {
                      return CheckboxListTile(
                        title: Text(unit['label']),
                        activeColor: appbar_color,
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
                      // Extract the IDs of all selected unit types
                      selectedUnitIds = unitTypes
                          .where((unit) => unit['isSelected'])
                          .map((unit) => unit['id'] as int)
                          .toList();

                      // Extract names of selected items
                      List<String> selectedNames = unitTypes
                          .where((unit) => unit['isSelected'])
                          .map((unit) => unit['label'] as String)
                          .toList();

                      if (selectedUnitIds.isEmpty) {
                        Navigator.of(context).pop(null); // Return null if no selection
                      } else {
                        // Return both IDs and names
                        Navigator.of(context).pop({'ids': selectedUnitIds, 'names': selectedNames});
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
        selectedUnitType = selectedItems['names']!.join(', ');
        print('unit types id $selectedUnitIds');
        isUnitSelected = true;  // Mark as selected
      });
    } else {
      setState(() {
        selectedUnitType = "Select Unit Types";  // Reset if no selection
        isUnitSelected = false;  // Mark as not selected
      });
    }
  }

  void _openEmirateDropdown(BuildContext context) async {
    final selectedItems = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        filteredEmirates = List.from(emirates);
        isAllEmiratesSelected = filteredEmirates!.every((a) => a['isSelected']);

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
                            .where((emirate) => emirate['label']
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Emirate(s)',
                      labelStyle: TextStyle(color: Colors.black54),
                      prefixIcon: Icon(Icons.search, color: Colors.black54),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.black54),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.black54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color.withOpacity(0.5), width: 2.0),
                      ),
                    ),
                    cursorColor: appbar_color,
                  ),
                ),
                CheckboxListTile(
                  title: Text("Select All"),
                  value: isAllEmiratesSelected,
                  activeColor: appbar_color,

                  onChanged: (bool? value) {
                    setState(() {
                      isAllEmiratesSelected = value ?? false;

                      // Update all emirates based on "Select All"
                      for (var emirate in filteredEmirates!) {
                        emirate['isSelected'] = isAllEmiratesSelected;
                      }
                    });
                  },
                ),
                Expanded(
                  child: ListView(
                    children: filteredEmirates!.map((emirate) {
                      return CheckboxListTile(
                        activeColor: appbar_color,
                        title: Text(emirate['label']),
                        value: emirate['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            emirate['isSelected'] = value!;

                            // Update the "Select All" checkbox
                            isAllEmiratesSelected = emirates.every((e) => e['isSelected']);

                            // Dynamically update the areas list
                            updateAreasDisplay();
                          });
                        },
                        contentPadding: EdgeInsets.symmetric(vertical: 0.0,horizontal: 20.0), // Adjust padding as needed
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    onPressed: () {
                      final selectedItems = emirates
                          .where((emirate) => emirate['isSelected'])
                          .map((emirate) => {
                        'id': emirate['id'],
                        'label': emirate['label'],
                      })
                          .toList();

                      Navigator.of(context).pop(selectedItems.isEmpty ? null : selectedItems);
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

    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        selectedEmiratesList = selectedItems;

        // Update the selectedEmirates string
        selectedEmiratesString = selectedItems.map((item) => item['label'] as String).join(', ');

        print('emirates list $selectedEmiratesList');

        // Refresh areas to display
        updateAreasDisplay();
      });
    } else {
      setState(() {
        selectedEmiratesList.clear();
        selectedEmiratesString = "Select Emirate";

        // Clear areas to display
        updateAreasDisplay();
      });
    }
  }
  // Area Dropdown based on selected emirates

  void _openAreaDropdown(BuildContext context) async {
    updateAreasDisplay(); // Ensure areasToDisplay is updated before opening

    final selectedItems = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
         filteredAreas = List.from(areasToDisplay);
        isAllAreasSelected = filteredAreas!.every((a) => a['isSelected']);


        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "Select Area(s)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        filteredAreas = areasToDisplay
                            .where((area) => area['label']
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Areas',
                      labelStyle: TextStyle(color: Colors.black54),

                      prefixIcon: Icon(Icons.search, color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.black54),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.black54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appbar_color.withOpacity(0.5), width: 2.0),
                      ),
                    ),
                    cursorColor: appbar_color,
                  ),
                ),
                CheckboxListTile(
                  title: Text("Select All"),
                  value: isAllAreasSelected,
                  activeColor: appbar_color,

                  onChanged: (bool? value) {
                    setState(() {
                      isAllAreasSelected = value ?? false;

                      // Update all areas based on "Select All"
                      for (var area in filteredAreas!) {
                        area['isSelected'] = isAllAreasSelected;
                      }
                    });
                  },
                ),
                Expanded(
                  child: ListView(
                    children: filteredAreas!.map((area) {
                      String? emirateName;
                      areas.forEach((key, value) {
                        if (value.contains(area)) {
                          emirateName = key;
                        }
                      });
                      return CheckboxListTile(
                        activeColor: appbar_color,
                        title: Text('${area['label']} - ${emirateName ?? "Unknown"}'), // Label with emirate name
                        value: area['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            area['isSelected'] = value!;
                            isAllAreasSelected = filteredAreas!.every((a) => a['isSelected']);
                            updateSelectedAreasString(filteredAreas!);
                          });
                        },
                        contentPadding: EdgeInsets.symmetric(vertical: 0.0,horizontal: 20.0), // Adjust padding as needed

                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    onPressed: () {
                      final selectedItems = filteredAreas!
                          .where((area) => area['isSelected'])
                          .map((area) => {
                        'id': area['id'],
                        'label': area['label'],
                      }).toList();

                      Navigator.of(context).pop(selectedItems.isEmpty ? null : selectedItems);
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

    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        selectedAreas = selectedItems;
        selectedAreasString = selectedItems.map((item) => item['label'] as String).join(', ');

        print('select areas $selectedAreas');

      });
    } else {
      setState(() {
        selectedAreas.clear();
        selectedAreasString = 'Select Area(s)';

      });
    }
  }

  @override
  void initState() {
    super.initState();

    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {

    prefs = await SharedPreferences.getInstance();
    setState(() {

      range_min = prefs!.getDouble('range_min') ?? 10000;
      range_max = prefs!.getDouble('range_max') ?? 100000;

      double range_start = range_min! + (range_min! / 0.8);
      double range_end = range_max! - (range_max! * 0.2);

      _currentRangeValues = RangeValues(range_start, range_end);

      startController.text = _currentRangeValues!.start.toStringAsFixed(0);
      endController.text = _currentRangeValues!.end.toStringAsFixed(0);
    });
    fetchActivitySources();
    fetchEmirates();
    fetchAreas();
    fetchUnitTypes();
    fetchLeadStatus();
    fetchAmenities();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          backgroundColor: appbar_color.withOpacity(0.9),
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
          title: Text('Create Inquiry',
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
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                child: Column(
                  children: [
                    /*Container(
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
                    ),*/

                    Container(
                        child:  Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              /*physics: NeverScrollableScrollPhysics(),*/
                                children: [

                                  Container(
                                    margin: EdgeInsets.only(left: 0, right: 0,top:10),
                                    padding: EdgeInsets.only(top:0,bottom:0),
                                    decoration: BoxDecoration(
                                    border: Border.all(color: Colors.transparent, width: 1),
                                    borderRadius: BorderRadius.circular(8),),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        Padding(
                                          padding: EdgeInsets.only(top:10,left: 20,right: 20,bottom: 10),

                                          child:  Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text("Interest Type:",
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
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Rent",
                                                  style: TextStyle(
                                                    color: selectedInterestType == 0 ? appbar_color : Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                FlutterSwitch(
                                                  width: 60,
                                                  height: 30,
                                                  toggleSize: 20,
                                                  borderRadius: 20,
                                                  activeColor: appbar_color.shade200, // Background color when Buy is selected
                                                  inactiveColor: appbar_color.shade200, // Background color when Rent is selected
                                                  value: selectedInterestType == 1, // true = Buy, false = Rent
                                                  onToggle: (bool value) {
                                                    setState(() {
                                                      selectedInterestType = value ? 1 : 0;
                                                    });
                                                  },
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  "Buy",
                                                  style: TextStyle(
                                                    color: selectedInterestType == 1 ? appbar_color : Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            )])),

                                        Container(
                                          padding: const EdgeInsets.only(left: 20.0, right: 20, top: 8,bottom:10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text("Property Type:",
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
                                              SizedBox(height: 5),
                                              SingleChildScrollView(
                                                child: Wrap(
                                                  spacing: 8.0,
                                                  runSpacing: 8.0,

                                                  children: propertyType.map((amenity) {
                                                    final isSelected = selectedPropertyType == amenity; // Single selection logic
                                                    return ChoiceChip(
                                                      label: Column(
                                                        children: [
                                                          if (amenity == "Residential")
                                                            Icon(
                                                              Icons.home,
                                                              color: isSelected ? Colors.white : Colors.black,
                                                            ),
                                                          if (amenity == "Commercial")
                                                            Icon(
                                                              Icons.business,
                                                              color: isSelected ? Colors.white : Colors.black,
                                                            ),
                                                          SizedBox(height: 5),
                                                          Text(
                                                            amenity,
                                                            style: TextStyle(
                                                              color: isSelected ? Colors.white : Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      selected: isSelected,
                                                      selectedColor: appbar_color.shade400,
                                                      onSelected: (bool selected) {
                                                        setState(() {
                                                          selectedPropertyType = selected ? amenity : null; // Ensure only one selection
                                                        });
                                                      },
                                                      showCheckmark: false,
                                                      backgroundColor: Colors.white,// Disable the checkmark

                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Padding(
                                            padding: EdgeInsets.only(top:10,left:20,right:20,bottom :10),

                                            child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [

                                                  DropdownButtonFormField<ActivitySource>(
                                                    value: selectedactivity_source,  // This should be an object of FollowUpStatus
                                                    decoration: InputDecoration(
                                                      hintText: 'Select Activity Source ',
                                                      label: Text(
                                                        'Activity Source',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.normal,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.black54),
                                                        borderRadius: BorderRadius.circular(10.0),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: appbar_color),
                                                        borderRadius: BorderRadius.circular(10.0),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(10.0),
                                                        borderSide: BorderSide(color: Colors.black54),
                                                      ),
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                                    ),
                                                    validator: (value) {
                                                      if (value == null) {
                                                        return 'Activity Source is required'; // Error message
                                                      }
                                                      return null; // No error if a value is selected
                                                    },
                                                    dropdownColor: Colors.white,
                                                    icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                                                    items: activitysource_list.map((ActivitySource status) {
                                                      return DropdownMenuItem<ActivitySource>(
                                                        value: status,
                                                        child: Text(
                                                          status.name,  // Display the 'name'
                                                          style: TextStyle(color: Colors.black87),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (ActivitySource? value) {
                                                      setState(() {
                                                        selectedactivity_source = value;

                                                      });
                                                    },
                                                  )

                                                  // Switch for isQualified

                                                ])),


                                        Padding(
                                            padding: EdgeInsets.only(top:10,left: 20,right: 20,bottom: 0),
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
                                                floatingLabelStyle: TextStyle(
                                                  color: appbar_color, // Change label color when focused
                                                  fontWeight: FontWeight.normal,
                                                ),
                                                hintText: 'Enter Name',
                                                label: Text('Name',
                                                ),
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
                                                    color:  appbar_color, // Set the focused border color
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


              Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: customercontactnocontroller,

                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        
                        return 'Contact No. is required';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      floatingLabelStyle: TextStyle(
                        color: appbar_color, // Change label color when focused
                        fontWeight: FontWeight.normal,
                      ),
                      hintText: _hintText,
                      contentPadding: EdgeInsets.all(15),
                      label: Text('Contact No',
                          style: TextStyle(fontWeight: FontWeight.normal)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: appbar_color),
                      ),
                      prefixIcon: GestureDetector(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: true,
                            onSelect: (Country country) {
                              setState(() {
                                _selectedCountryCode = '+${country.phoneCode}';
                                _selectedCountryFlag = country.flagEmoji;
                              });
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedCountryFlag, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 5),
                              Text('$_selectedCountryCode', style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _useContactAsWhatsapp = !_useContactAsWhatsapp;
                            if (_useContactAsWhatsapp) {
                              whatsappnocontroller.text = customercontactnocontroller.text;
                              _selectedCountryCodeWhatsapp = _selectedCountryCode;
                              _selectedCountryFlagWhatsapp = _selectedCountryFlag;
                            } else {
                              whatsappnocontroller.clear();
                            }
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: _useContactAsWhatsapp ? appbar_color : Colors.black, width: 1),
                                color: _useContactAsWhatsapp ? appbar_color : Colors.transparent,
                              ),
                              child: _useContactAsWhatsapp
                                  ? Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                            SizedBox(width: 8),


                            Icon(FontAwesomeIcons.whatsapp,
                                color: Colors.green
                            ),

                            SizedBox(width: 8),



                          ],
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (_useContactAsWhatsapp) {
                        setState(() {
                          whatsappnocontroller.text = value;
                          _selectedCountryCodeWhatsapp = _selectedCountryCode;
                          _selectedCountryFlagWhatsapp = _selectedCountryFlag;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            if (!_useContactAsWhatsapp)
              Padding(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 0),
                child: TextFormField(
                  controller: whatsappnocontroller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(
                      color: appbar_color, // Change label color when focused
                      fontWeight: FontWeight.normal,
                    ),
                    hintText: _hintTextWhatsapp,
                    contentPadding: EdgeInsets.all(15),
                    label: Text('WhatsApp No',
                        style: TextStyle(fontWeight: FontWeight.normal)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: appbar_color),
                    ),

                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        const SizedBox(width: 8),
                        Icon(FontAwesomeIcons.whatsapp,
                            color: Colors.green
                        ),
                        SizedBox(width: 8),





                      ],
                    ),

                    prefixIcon: GestureDetector(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountryCodeWhatsapp = '+${country.phoneCode}';
                              _selectedCountryFlagWhatsapp = country.flagEmoji;
                            });
                          },
                        );
                      },


                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedCountryFlagWhatsapp, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 5),
                            Text('$_selectedCountryCodeWhatsapp', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),


            /*Padding(

                                            padding: EdgeInsets.only(top:20,left: 20,right: 20,bottom: 0),

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
                                                label: Text('Contact No.',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.normal,
                                                      color: Colors.black
                                                  ),),
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

                                            )),*/


                                        Padding(

                                            padding: EdgeInsets.only(top:20,left: 20,right: 20,bottom: 0),

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
                                                floatingLabelStyle: TextStyle(
                                                  color: appbar_color, // Change label color when focused
                                                  fontWeight: FontWeight.normal,
                                                ),
                                                label: Text('Email Address',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.normal,

                                                  ),),
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
                                                    color:  appbar_color, // Set the focused border color

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
                                      ],
                                    )
                                  ),

                                  Container(
                                    child: Column(

                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [

                                          Padding(
                                            padding: EdgeInsets.only(top:20,left:20,right:20,bottom :0),

                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [

                                                DropdownButtonFormField<InquiryStatus>(
                                                  value: selectedinquiry_status,  // This should be an object of FollowUpStatus
                                                  decoration: InputDecoration(
                                                    hintText: 'Select Inquiry Status (required)',
                                                    label: Text(
                                                      'Inquiry Status',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.normal,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.black54),
                                                      borderRadius: BorderRadius.circular(10.0),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(color: appbar_color),
                                                      borderRadius: BorderRadius.circular(10.0),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10.0),
                                                      borderSide: BorderSide(color: Colors.black54),
                                                    ),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null) {
                                                      return 'Inquiry Status is required'; // Error message
                                                    }
                                                    return null; // No error if a value is selected
                                                  },
                                                  dropdownColor: Colors.white,
                                                  icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                                                  items: inquirystatus_list.map((InquiryStatus status) {
                                                    return DropdownMenuItem<InquiryStatus>(
                                                      value: status,
                                                      child: Text(
                                                        status.name,  // Display the 'name'
                                                        style: TextStyle(color: Colors.black87),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (InquiryStatus? value) {
                                                    setState(() {
                                                      selectedinquiry_status = value;

                                                      if(selectedinquiry_status!='Normal')
                                                        {
                                                          nextFollowUpDate = null;
                                                        }



                                                    });
                                                  },
                                                )

                                                // Switch for isQualified

                                                ]))]),
                                  ), // folowup status

                                  /*if (selectedinquiry_status == 'In Follow-Up' || selectedinquiry_status == 'Contact Later') // Conditionally render based on status
                                    */

                                  if(selectedinquiry_status!=null && selectedinquiry_status!.category == 'Normal')
                                    Container(
                                      padding: EdgeInsets.only(top: 15, left: 20, right: 20),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Next Follow-Up:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () async {
                                              DateTime? pickedDate = await showDatePicker(
                                                context: context,
                                                initialDate: nextFollowUpDate ?? DateTime.now().add(Duration(days: 1)),
                                                firstDate: DateTime.now().add(Duration(days: 1)), // Restrict past dates
                                                lastDate: DateTime(2100),
                                                builder: (BuildContext context, Widget? child) {
                                                  return Theme(
                                                    data: ThemeData.light().copyWith(
                                                      colorScheme: ColorScheme.light(
                                                        primary: appbar_color, // Header background and selected date color
                                                        onPrimary: Colors.white, // Header text color
                                                        onSurface: Colors.black, // Calendar text color
                                                      ),
                                                      textButtonTheme: TextButtonThemeData(
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: appbar_color, // Button text color
                                                        ),
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );

                                              if (pickedDate != null) {
                                                setState(() {
                                                  nextFollowUpDate = pickedDate; // Save selected date
                                                });
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                if(nextFollowUpDate != null)
                                                  Row(children:[
                                                    Text(
                                                      nextFollowUpDate != null
                                                          ? DateFormat("dd-MMM-yyyy").format(nextFollowUpDate!) // Formatting date
                                                          : "",
                                                      style: TextStyle(fontSize: 16, color: Colors.black87),
                                                    ),
                                                    SizedBox(width: 10),

                                                  ]),
                                                Icon(FontAwesomeIcons.calendarPlus, color: Colors.black87, size: 28),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  /*Container(

                                    child: Column(

                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(padding: EdgeInsets.only(top: 15,left:20),

                                          child:Row(
                                            children: [
                                              Text("Next Follow-Up:",
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16

                                                  )
                                              ),
                                              */
                                  /*SizedBox(width: 2),
                                              Text(
                                                '*', // Red asterisk for required field
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.red, // Red color for the asterisk
                                                ),
                                              ),*//*
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: 5),

                                        Padding(
                                          padding: EdgeInsets.only(top: 0, left: 20, right: 20),
                                          child: GestureDetector(
                                            onTap: () async {
                                              DateTime? pickedDate = await showDatePicker(
                                                context: context,

                                                initialDate: nextFollowUpDate ?? DateTime.now().add(Duration(days:1)),
                                                firstDate: DateTime.now().add(Duration(days:1)), // Restrict past dates
                                                lastDate: DateTime(2100),
                                                builder: (BuildContext context, Widget? child) {
                                                  return Theme(
                                                    data: ThemeData.light().copyWith(
                                                      colorScheme: ColorScheme.light(
                                                        primary: appbar_color, // Header background and selected date color
                                                        onPrimary: Colors.white, // Header text color
                                                        onSurface: Colors.black, // Calendar text color
                                                      ),
                                                      textButtonTheme: TextButtonThemeData(
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: appbar_color, // Button text color
                                                        ),
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );

                                              if (pickedDate != null) {
                                                setState(() {
                                                  nextFollowUpDate = pickedDate; // Save selected date
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.black54),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Icon(Icons.calendar_today, color: Colors.black54),
                                                  SizedBox(width: 10,),
                                                  Text(
                                                    nextFollowUpDate != null
                                                        ? "${nextFollowUpDate!.day}-${nextFollowUpDate!.month}-${nextFollowUpDate!.year}"
                                                        : "Select Next Follow-Up Date",
                                                    style: TextStyle(fontSize: 16, color: Colors.black54),
                                                  ),

                                                ],
                                              ),
                                            ),
                                          ),
                                        ),


                                      ],
                                    ),
                                  ),*/


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
                                          ))])), // unit type

                                  Padding(
                                    padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                    child: GestureDetector(
                                      onTap: () => _openUnitTypeDropdown(context), // Open the custom dropdown
                                      child: TextFormField(
                                        controller: TextEditingController(text: selectedUnitType),
                                        decoration: InputDecoration(
                                          floatingLabelStyle: TextStyle(
                                            color: appbar_color, // Change label color when focused
                                            fontWeight: FontWeight.normal,
                                          ),
                                          hintText: 'Select Unit Type(s)',
                                          contentPadding: EdgeInsets.all(15),
                                          fillColor: isUnitSelected ? Colors.transparent : Colors.transparent, // Set to black if selected
                                          filled: true, // Ensure the field is filled but transparent or black based on isSelected
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.black54), // Black border
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.black54), // Black border when enabled
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.black54), // Black border when disabled
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color:appbar_color), // Black focused border
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
                                        Padding(padding: EdgeInsets.only(top: 10,left:20),
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
                                                ))])),

                                        Padding(
                                          padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                          child: GestureDetector(
                                            onTap: () => _openEmirateDropdown(context), // Open the custom dropdown
                                            child: Container(
                                              width: double.infinity, // Make the container expand to full width
                                              padding: EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: Colors.transparent, // Set it to transparent
                                                border: Border.all(color: Colors.black54), // Black border
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
                                                children: [
                                                  // Column to display selected emirates
                                                  Expanded(
                                                    child: selectedEmiratesString.isNotEmpty
                                                        ? Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: selectedEmiratesString.split(', ').map((emirate) {
                                                        return Text(
                                                          emirate, // Display each emirate on a new line
                                                          style: TextStyle(fontSize: 16, color: Colors.grey),
                                                        );
                                                      }).toList(),
                                                    )
                                                        : Text(
                                                      'Select Emirate', // Placeholder text when no emirates are selected
                                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                                    ),
                                                  ),
                                                  // Down arrow icon
                                                  Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.grey, // Adjust the color of the arrow
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )

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
                                    margin: EdgeInsets.only( top:10,
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

                                  Padding(
                                    padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                    child: GestureDetector(
                                      onTap: selectedEmiratesList.isNotEmpty
                                          ? () => _openAreaDropdown(context) // Open the custom dropdown
                                          : null, // Disable if no emirates are selected
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.transparent, // Set it to transparent as per your requirement
                                          border: Border.all(color: Colors.black54), // Black border
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
                                          children: [
                                            // Column to display selected emirates
                                            Expanded(
                                              child: selectedAreasString.isNotEmpty
                                                  ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: selectedAreasString.split(', ').map((emirate) {
                                                  return Text(
                                                    emirate, // Display each emirate on a new line
                                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                                  );
                                                }).toList(),
                                              )
                                                  : Text(
                                                'Select Area(s)', // Placeholder text when no emirates are selected
                                                style: TextStyle(fontSize: 16, color: Colors.grey),
                                              ),
                                            ),
                                            // Down arrow icon
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey, // Adjust the color of the arrow
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("Amenities:",
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
                                        SizedBox(height: 5),

                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          margin: EdgeInsets.only(left: 0, right: 0, bottom: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,

                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.black54, width: 0.75),
                                          ),
                                          child: MultiSelectDialogField(
                                            items: amenities
                                                .map((amenity) =>
                                                MultiSelectItem<int>(amenity['id'], amenity['name']))
                                                .toList(),

                                            initialValue: selectedAmenities.toList(),
                                            title: Text("Amenities"),
                                            searchable: true,
                                            selectedColor: appbar_color,
                                            checkColor: Colors.white,
                                            confirmText: Text(
                                              "Confirm",

                                              style: TextStyle(color: appbar_color), // Custom confirm button
                                            ),
                                            cancelText: Text(
                                              "Cancel",
                                              style: TextStyle(color: appbar_color), // Custom cancel button
                                            ),
                                            buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                                            buttonText: Text(
                                              "Select Amenities",
                                              style: TextStyle(color: Colors.black54, fontSize: 16),
                                            ),
                                            onConfirm: (values) {
                                              setState(() {
                                                selectedAmenities = Set<int>.from(values);
                                              });
                                            },



                                            chipDisplay: MultiSelectChipDisplay(
                                              items: selectedAmenities
                                                  .map((id) => MultiSelectItem<int>(
                                                  id, amenities.firstWhere((item) => item['id'] == id)['name']))
                                                  .toList(),
                                              onTap: (value) {
                                                setState(() {
                                                  selectedAmenities.remove(value);
                                                });
                                              },
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.transparent),
                                            )))])),

                                  Container(
                                    padding: const EdgeInsets.only(left: 20.0, right: 20, top: 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("Preferences:",
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
                                    SizedBox(height: 5),

                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      margin: EdgeInsets.only(left: 0, right: 0, bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.black54, width: 0.75),
                                      ),
                                      child:  MultiSelectDialogField(
                                        items: preferences
                                            .map((amenity) =>
                                            MultiSelectItem<int>(amenity['id'], amenity['name']))
                                            .toList(),
                                        initialValue: selectedPreferences.toList(),
                                        title: Text("Preference"),
                                        searchable: true,
                                        selectedColor: appbar_color,
                                        checkColor: Colors.white,
                                        confirmText: Text(
                                          "Confirm",
                                          style: TextStyle(color: appbar_color),
                                        ),
                                        cancelText: Text(
                                          "Cancel",
                                          style: TextStyle(color: appbar_color),
                                        ),
                                        buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                                        buttonText: Text(
                                          "Select Preferences",
                                          style: TextStyle(color: Colors.black54, fontSize: 16),
                                        ),
                                        onConfirm: (values) {
                                          setState(() {
                                            selectedPreferences = Set<int>.from(values);
                                          });
                                        },
                                        chipDisplay: MultiSelectChipDisplay(

                                          items: selectedPreferences
                                              .map((id) => MultiSelectItem<int>(
                                              id,
                                              preferences
                                                  .firstWhere((feature) => feature['id'] == id)['name']))
                                              .toList(),
                                          onTap: (value) {
                                            setState(() {
                                              selectedPreferences.remove(value);
                                            });
                                          },
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.transparent),
                                        )))])),

                                  Container(
                                    padding: const EdgeInsets.only(left: 20.0, right: 20, top: 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("Price Range:",
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
                                        
                                        SizedBox(height:5),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                validator: (value) {
                                                  if (value!.isEmpty) {
                                                    return 'From Price is required';
                                                  }

                                                  return null;
                                                },
                                                controller: startController,
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  label: Text('From'),
                                                  floatingLabelStyle: TextStyle(
                                                    color: Colors.black, // Change label color when focused
                                                    fontWeight: FontWeight.normal,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: Colors.black54),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: Colors.black54),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: appbar_color),
                                                  ),
                                                ),
                                                onChanged: (value) => _updateRangeFromTextFields(),
                                              ),
                                            ),
                                            SizedBox(width: 5),

                                            Text('to'),

                                            SizedBox(width: 5),

                                            Expanded(
                                              child: TextFormField(
                                                validator: (value) {
                                                  if (value!.isEmpty) {
                                                    return 'To Price is required';
                                                  }
                                                  return null;
                                                },
                                                controller: endController,
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  label: Text('To'),
                                                  floatingLabelStyle: TextStyle(
                                                    color: Colors.black, // Change label color when focused
                                                    fontWeight: FontWeight.normal,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: Colors.black54),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: Colors.black54),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: appbar_color),
                                                  ),
                                                ),
                                                onChanged: (value) => _updateRangeFromTextFields(),
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height:10),

                                        RangeSlider(
                                          activeColor: appbar_color,
                                          inactiveColor: appbar_color.withOpacity(0.4),
                                          values: _currentRangeValues!,
                                          min: range_min!,
                                          max: range_max!,
                                          divisions: 20,
                                          onChanged: (RangeValues values) {
                                            setState(() {
                                              _currentRangeValues = values;
                                              startController.text = values.start.toStringAsFixed(0);
                                              endController.text = values.end.toStringAsFixed(0);
                                            });
                                          })])),

                                 /*Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

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


                                ),*/

                                 /* Container(
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
                                  ),*/

                                 /* Container(
                                    margin: EdgeInsets.only( top:10,
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
                                  ),*/

                                  Padding(padding: EdgeInsets.only(top:10,left: 20,right: 20,bottom: 0),

                                      child: TextFormField(
                                        controller: descriptioncontroller,
                                        maxLength: 500, // Limit input to 500 characters
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'Description is required';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Enter Description',
                                          labelText: 'Description',
                                          floatingLabelStyle: TextStyle(
                                            color: appbar_color, // Change label color when focused
                                            fontWeight: FontWeight.normal,
                                          ),
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
                                              color:  appbar_color, // Set the focused border color
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
                                                  selectedinquiry_status = null;
                                                  selectedInterestType = 0;
                                                  selectedPropertyType = null;
                                                  selectedactivity_source = null;
                                                  nextFollowUpDate = null;
                                                  selectedUnitIds.clear();

                                                  selectedUnitType = "Select Unit Types";
                                                  selectedEmiratesString = "Select Emirate";
                                                  selectedEmiratesList.clear();

                                                  for (var emirate in emirates) {
                                                    emirate['isSelected'] = false;
                                                  }
                                                  isAllEmiratesSelected = false;

                                                  // Reset areas automatically
                                                  clearAreas();

                                                  updateAreasDisplay();

                                                  updateAreasSelection();

                                                  selectedAmenities.clear();
                                                  selectedPreferences.clear();

                                                  range_min = prefs!.getDouble('range_min') ?? 10000;
                                                  range_max = prefs!.getDouble('range_max') ?? 100000;

                                                  double range_start = range_min! + (range_min! / 0.8);
                                                  double range_end = range_max! - (range_max! * 0.2);

                                                  _currentRangeValues = RangeValues(range_start, range_end);

                                                  startController.text = _currentRangeValues!.start.toStringAsFixed(0);
                                                  endController.text = _currentRangeValues!.end.toStringAsFixed(0);

                                                  isAllEmiratesSelected = false;

                                                   _selectedCountryCode = '+971'; // Default to UAE country code
                                                   _selectedCountryFlag = '🇦🇪'; // Default UAE flag emoji

                                                  customernamecontroller.clear();
                                                  customercontactnocontroller.clear();
                                                  emailcontroller.clear();
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

                                                if(selectedInterestType == null)
                                                {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Select Interest Type'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                                else
                                                {

                                                  if(selectedPropertyType == null)
                                                    {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Select Property Type'),
                                                          backgroundColor: Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  else
                                                    {

                                                      if (_formKey.currentState != null &&
                                                          _formKey.currentState!.validate()) {
                                                        _formKey.currentState!.save();

                                                        setState(() {
                                                          _isFocused_email = false;
                                                          _isFocus_name = false;
                                                        });


                                                        sendCreateInquiryRequest();



                                                      }
                                                    }

                                                }

                                                },
                                              child: Text('Create'),
                                            ),
                                          ],)
                                    ),)
                                ]))
                    )
                  ],
                )
              ),)
          ],
        ) ,);}}