import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SalesInquiryReport.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;


class FollowUpStatus {
  final int id;
  final String name;
  final bool isQualified;

  FollowUpStatus({
    required this.id,
    required this.name,
    required this.isQualified,
  });

  // Factory method to create a FollowUpStatus object from JSON
  factory FollowUpStatus.fromJson(Map<String, dynamic> json) {
    return FollowUpStatus(
      id: json['id'],
      name: json['name'],
      isQualified: json['is_qualified'] == 'true',  // Convert to bool
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

  double? range_min, range_max;

  FollowUpStatus? selectedinquiry_status;

  ActivitySource? selectedactivity_source;


  DateTime? nextFollowUpDate;

  bool isEmirateSelected = false;

  bool isAreasSelected = false;

  RangeValues? _currentRangeValues;

  SharedPreferences? prefs;


  List<String> followuptype_list = [
    'Email',
    'Phone Call',
    'Whatsapp',
    'Social Media'
  ];

  List<FollowUpStatus> inquirystatus_list = [];

  List<ActivitySource> activitysource_list = [

  ];

  bool isAllEmiratesSelected = false;

  bool isAllAreasSelected = false;

  String? selectedEmirate;

  bool _isFocused_email = false,_isFocus_name = false;

  bool _isLoading = false;

  List<Map<String, dynamic>> emirates = [
    {"label": "Abu Dhabi", "isSelected": false},
    {"label": "Dubai", "isSelected": false},
    {"label": "Sharjah", "isSelected": false},
    {"label": "Ajman", "isSelected": false},
    {"label": "Umm Al Quwain", "isSelected": false},
    {"label": "Ras Al Khaimah", "isSelected": false},
    {"label": "Fujairah", "isSelected": false},
  ];

  List<String> asignedto = [
    'Self',
  ];

  List<Map<String, dynamic>> unitTypes = [];

  Map<String, List<Map<String, dynamic>>> areas = {
    'Dubai': [
      {'label': 'Downtown Dubai', 'isSelected': false},
      {'label': 'Jumeirah', 'isSelected': false},
      {'label': 'Bur Dubai', 'isSelected': false},
      {'label': 'Dubai Marina', 'isSelected': false},
      {'label': 'Al Qusais', 'isSelected': false},
    ],
    'Abu Dhabi': [
      {'label': 'Al Ain', 'isSelected': false},
      {'label': 'Al Dhafra', 'isSelected': false},
      {'label': 'Abu Dhabi City', 'isSelected': false},
      {'label': 'Bani Yas', 'isSelected': false},
    ],
    'Sharjah': [
      {'label': 'Al Qasba', 'isSelected': false},
      {'label': 'Al Khan', 'isSelected': false},
      {'label': 'Al Nahda', 'isSelected': false},
      {'label': 'Al Majaz', 'isSelected': false},
    ],
    'Ajman': [
      {'label': 'Ajman City', 'isSelected': false},
      {'label': 'Al Nuaimiya', 'isSelected': false},
      {'label': 'Rashidiya', 'isSelected': false},
    ],
    'Fujairah': [
      {'label': 'Fujairah City', 'isSelected': false},
      {'label': 'Dibba', 'isSelected': false},
    ],
    'Ras Al Khaimah': [
      {'label': 'Ras Al Khaimah City', 'isSelected': false},
      {'label': 'Al Jazeera', 'isSelected': false},
    ],
    'Umm Al Quwain': [
      {'label': 'Umm Al Quwain City', 'isSelected': false},
      {'label': 'Al Salama', 'isSelected': false},
    ],
  };

  String selectedUnitType = "Select Unit Types";
  String selectedEmirates = "Select Emirate";
  String selectedAreasString = "Select Area";
  List<String> selectedEmiratesList = [];
  List<String> selectedAreas = [];

  final List<Map<String, dynamic>> specialfeatures = [];
  final List<Map<String, dynamic>> amenities = [];
  final Set<int> selectedSpecialFeatures = {};
  final Set<int> selectedAmenities = {};

  final List<String> interestTypes = ["Rent", "Buy"]; // List of options


  final List<String> propertyType = [
    'Residential',
    'Commercial',
  ];

  List<int> selectedUnitIds = [];

  void fetchFlatTypes(dynamic jsonResponse) {
    final data = jsonResponse is String
        ? jsonDecode(jsonResponse)
        : jsonResponse;

    if (data != null && data['data'] != null && data['data']['flatTypes'] != null) {
      final flatTypes = data['data']['flatTypes'] as List<dynamic>;

      unitTypes = flatTypes
          .map((flat) => {
        'label': flat['flat_type'], // Flat type name
        'id': flat['cost_centre_masterid'], // ID value
        'isSelected': false, // Default selection state
      })
          .toList();
    } else {
      print('Error: Invalid data structure');
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
    final List<int> amenitiesList = selectedSpecialFeatures.union(selectedAmenities).toList();

    //converting date to yyyy-MM-dd format
    String? formattedDate;
    if (nextFollowUpDate != null) {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      formattedDate = formatter.format(nextFollowUpDate!);
    } else {
      formattedDate = null;
    }

    // Replace with your API endpoint
    final String url = "https://yourapiendpoint.com/create";

    // Constructing the JSON body
    final Map<String, dynamic> requestBody = {
      "uuid": uuid,
      "name": customernamecontroller.text,
      "email": emailcontroller.text,
      "mobile_no": customercontactnocontroller.text,
      "areas": [1, 2],
      "flatTypes": selectedUnitIds,
      "lead_status_id": selectedinquiry_status!.id,
      "next_followup_date": formattedDate,
      "property_type": selectedPropertyType,
      "interest_type": interestTypes[selectedInterestType ?? 0],
      "max_price": _currentRangeValues!.end.round().toString(),
      "min_price": _currentRangeValues!.start.round().toString(),
      "amenities": amenitiesList,
      "description" : descriptioncontroller.text
    };

    print('create request body $requestBody');


    /*try {
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
      } else {
        // Error occurred
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
      }
    } catch (error) {
      print("Exception: $error");
    }*/
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

        print(data);
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
          List<dynamic> activitySourceList = data['data']['activitySources'];

          for (var status in activitySourceList) {
            // Create a FollowUpStatus object from JSON
            ActivitySource activitySource = ActivitySource.fromJson(status);

            // Add the object to the list
            activitysource_list.add(activitySource);


            // Optionally, you can print the object for verification
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


        setState(() {

          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> amenitiesData = data['data']['amenities'];

          for (var item in amenitiesData) {
            if (item['is_special'] == "true") {
              specialfeatures.add(item);
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
          List<dynamic> leadStatusList = data['data']['leadStatus'];

          for (var status in leadStatusList) {
            // Create a FollowUpStatus object from JSON
            FollowUpStatus followUpStatus = FollowUpStatus.fromJson(status);

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
      selectedEmirates = emirates
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

  void updateSelectedAreasString() {
    setState(() {
      // Create a list of area strings with their corresponding emirate names
      List<String> areaWithEmirates = [];

      areas.forEach((emirate, areaList) {
        for (var area in areaList) {
          if (area['isSelected']) {
            areaWithEmirates.add("${area['label']} - $emirate");
          }
        }
      });

      // Join the area strings with commas
      selectedAreasString = areaWithEmirates.isNotEmpty
          ? areaWithEmirates.join(', ')
          : "Select Area";
    });
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
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey), // BlueGrey border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey), // BlueGrey focused border color
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
                        activeColor: Colors.blueGrey,
                        value: isAllUnitsSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            isAllUnitsSelected = value ?? false;
                            // Update all unit types based on Select All
                            for (var unit in unitTypes) {
                              unit['isSelected'] = isAllUnitsSelected;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                SizedBox(height: 15),
                Expanded(
                  child: ListView(
                    children: filteredUnitTypes.map((unit) {
                      return CheckboxListTile(
                        title: Text(unit['label']),
                        activeColor: Colors.blueGrey,
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
    final selectedItems = await showModalBottomSheet<List<String>>(
      context: context,
      isDismissible: false, // Prevent closing by tapping outside
      enableDrag: false,    // Prevent closing by dragging
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, dynamic>> filteredEmirates = List.from(emirates);

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
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: CheckboxListTile(
                      title: Text("Select All",
                        style: TextStyle(color: Colors.black),
                      ),
                      activeColor: Colors.blueGrey,
                      value: isAllEmiratesSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          isAllEmiratesSelected = value ?? false;
                          // Update all Emirates based on Select All
                          for (var emirate in emirates) {
                            emirate['isSelected'] = isAllEmiratesSelected;
                          }

                          // If no emirates are selected, clear all areas
                          if (emirates.every((emirate) => !emirate['isSelected'])) {
                            selectedAreas.clear();
                            selectedAreasString = "Select Area";

                            // Reset all area states
                            areas.forEach((key, areaList) {
                              for (var area in areaList) {
                                area['isSelected'] = false;
                              }
                            });
                          }

                          // Update the displayed areas
                          updateSelectedAreasString();


                          /*updateEmiratesSelection();  // Update Emirates selection text*/
                          updateAreasSelection();     // Update Areas based on Emirates selection
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(height: 15),
                Expanded(
                  child: ListView(
                    children: filteredEmirates.map((emirate) {
                      return CheckboxListTile(
                        activeColor: Colors.blueGrey,
                        title: Text(emirate['label']),
                        value: emirate['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            emirate['isSelected'] = value!;

                            // Handle 'Select All' logic for emirates
                            isAllEmiratesSelected =
                                emirates.every((emirate) => emirate['isSelected']);

                            // If an emirate is deselected, clear its areas
                            if (!emirate['isSelected']) {
                              List<Map<String, dynamic>> emirateAreas = areas[emirate['label']] ?? [];
                              for (var area in emirateAreas) {
                                area['isSelected'] = false;
                                selectedAreas.remove(area['label']); // Remove from selectedAreas list
                              }
                            }


                            // If no emirates are selected, clear all areas
                            if (emirates.every((emirate) => !emirate['isSelected'])) {
                              selectedAreas.clear();
                              selectedAreasString = "Select Area";

                              // Reset all area states
                              areas.forEach((key, areaList) {
                                for (var area in areaList) {
                                  area['isSelected'] = false;
                                }
                              });
                            }

                            // Update the displayed areas
                            updateSelectedAreasString();
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
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    onPressed: () {
                      List<String> selected = emirates
                          .where((emirate) => emirate['isSelected'])
                          .map((emirate) => emirate['label'] as String)
                          .toList();



                      if (selected.isEmpty) {
                        Navigator.of(context).pop(null);
                      } else {
                        Navigator.of(context).pop(selected);
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

    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        selectedEmiratesList = selectedItems;
        selectedEmirates = selectedItems.join(', ');
      });
    }
    else {
      setState(() {
        selectedEmirates = "Select Emirate";  // Reset if no selection
        isEmirateSelected = false;  // Mark as not selected
        selectedEmiratesList.clear();
      });
    }


  }
  // Area Dropdown based on selected emirates
  void _openAreaDropdown(BuildContext context) async {
    // List to store areas to display based on selected Emirates
    List<Map<String, dynamic>> areasToDisplay = [];

    // Populate areasToDisplay based on selected emirates
    selectedEmiratesList.forEach((emirate) {
      if (areas.containsKey(emirate)) {
        areasToDisplay.addAll(areas[emirate]!);  // Add areas related to the selected emirate
      }
    });

    // Show modal bottom sheet with filtered areas list
    final selectedAreasList = await showModalBottomSheet<List<String>>(
      context: context,
      isDismissible: false, // Prevent closing by tapping outside
      enableDrag: false,    // Prevent closing by dragging
      builder: (BuildContext context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, dynamic>> filteredAreas = List.from(areasToDisplay); // Start with all areas

        return StatefulBuilder(
          builder: (context, setState) {
            // Check if all areas are selected
            bool isAllAreasSelected = filteredAreas.every((area) => area['isSelected']);

            return Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "Select Area(s)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                // Search bar to filter areas
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setState(() {
                        filteredAreas = areasToDisplay
                            .where((area) => area['label']
                            .toLowerCase()
                            .contains(query.toLowerCase()))  // Case insensitive search
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Areas',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 15),

                // "Select All" checkbox
                CheckboxListTile(
                  title: Text('Select All'),
                  activeColor: Colors.blueGrey,
                  value: isAllAreasSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      // Update all areas to the selected value
                      isAllAreasSelected = value!;
                      filteredAreas.forEach((area) {
                        area['isSelected'] = isAllAreasSelected;
                      });
                      updateSelectedAreasString();
                    });
                  },
                ),

                SizedBox(height: 15),

                // Display filtered areas with their corresponding emirates
                Expanded(
                  child: ListView(
                    children: filteredAreas.map((area) {
                      // Loop through emirates to find the matching one
                      String emirate = '';
                      areas.forEach((emirateName, areaList) {
                        if (areaList.contains(area)) {
                          emirate = emirateName;
                        }
                      });

                      return CheckboxListTile(
                        activeColor: Colors.blueGrey,
                        title: Text('${area['label']} - $emirate'), // Display area and emirate
                        value: area['isSelected'],
                        onChanged: (bool? value) {
                          setState(() {
                            area['isSelected'] = value!;
                            if (area['isSelected']) {
                              selectedAreas.add('${area['label']} - $emirate');  // Add area with emirate
                            } else {
                              selectedAreas.remove('${area['label']} - $emirate');  // Remove area with emirate
                            }
                            // Update the "Select All" checkbox based on individual selections
                            isAllAreasSelected = filteredAreas.every((area) => area['isSelected']);
                            updateSelectedAreasString();
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
                      // Collect the selected areas with their emirate names
                      List<String> formattedAreas = [];
                      areas.forEach((emirateName, areaList) {
                        for (var area in areaList) {
                          if (area['isSelected']) {
                            formattedAreas.add('${area['label']} - $emirateName');
                          }
                        }
                      });

                      // Update the `selectedAreasString` to show the selected areas with emirate names
                      setState(() {
                        if (formattedAreas.isEmpty) {
                          selectedAreasString = "Select Area";
                        } else {
                          selectedAreasString = formattedAreas.join(', ');
                        }
                      });

                      // Pop the modal
                      Navigator.of(context).pop(formattedAreas.isEmpty ? null : formattedAreas);
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

    if (selectedAreasList != null && selectedAreasList.isNotEmpty) {
      setState(() {
        selectedAreas = selectedAreasList;
        selectedAreasString = selectedAreas.join(', ');
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
    fetchUnitTypes();
    fetchLeadStatus();
    fetchAmenities();
  }

  int? selectedInterestType;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          backgroundColor: appbar_color,
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
          title: Text('Inquiry',
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
                    Container(
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
                    ),

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
                                            const SizedBox(height: 5),
                                            ToggleButtons(
                                              borderRadius: BorderRadius.circular(10),

                                              isSelected: [selectedInterestType == 0, selectedInterestType == 1],
                                              onPressed: (int index) {
                                                setState(() {
                                                  selectedInterestType = index;
                                                });
                                              },
                                              selectedColor: Colors.white, // Text color for selected button
                                              fillColor:
                                              Colors.blueGrey.shade400, // Background color for selected button
                                              color: Colors.black, // Text color for unselected button
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                                  child: Text("Rent"),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                                  child: Text("Buy"),
                                                )])])),

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
                                                      selectedColor: Colors.blueGrey.shade400,
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
                                                    icon: Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
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
                                                hintText: 'Enter Name',
                                                label: Text('Name',
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

                                            )),


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
                                                label: Text('Email Address',
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

                                                DropdownButtonFormField<FollowUpStatus>(
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
                                                  icon: Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
                                                  items: inquirystatus_list.map((FollowUpStatus status) {
                                                    return DropdownMenuItem<FollowUpStatus>(
                                                      value: status,
                                                      child: Text(
                                                        status.name,  // Display the 'name'
                                                        style: TextStyle(color: Colors.black87),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (FollowUpStatus? value) {
                                                    setState(() {
                                                      selectedinquiry_status = value;


                                                    });
                                                  },
                                                )

                                                // Switch for isQualified

                                                ]))]),
                                  ), // folowup status

                                  /*if (selectedinquiry_status == 'In Follow-Up' || selectedinquiry_status == 'Contact Later') // Conditionally render based on status
                                    */
                                  Container(

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
                                              /*SizedBox(width: 2),
                                              Text(
                                                '*', // Red asterisk for required field
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.red, // Red color for the asterisk
                                                ),
                                              ),*/
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

                                                initialDate: nextFollowUpDate ?? DateTime.now(),
                                                firstDate: DateTime.now(), // Restrict past dates
                                                lastDate: DateTime(2100),
                                                builder: (BuildContext context, Widget? child) {
                                                  return Theme(
                                                    data: ThemeData.light().copyWith(
                                                      colorScheme: ColorScheme.light(
                                                        primary: Colors.blueGrey, // Header background and selected date color
                                                        onPrimary: Colors.white, // Header text color
                                                        onSurface: Colors.blueGrey, // Calendar text color
                                                      ),
                                                      textButtonTheme: TextButtonThemeData(
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Colors.blueGrey, // Button text color
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
                                  ),


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
                                          ),
                                        ),
                                      ],
                                    ),
                                  ), // unit type

                                  Padding(
                                    padding: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
                                    child: GestureDetector(
                                      onTap: () => _openUnitTypeDropdown(context), // Open the custom dropdown
                                      child: TextFormField(
                                        controller: TextEditingController(text: selectedUnitType),
                                        decoration: InputDecoration(
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
                                            borderSide: BorderSide(color: Colors.black54), // Black focused border
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
                                        Padding(padding: EdgeInsets.only(top: 5,left:20),
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
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

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
                                                    child: selectedEmirates.isNotEmpty
                                                        ? Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: selectedEmirates.split(', ').map((emirate) {
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
                                    margin: EdgeInsets.only( top:15,
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
                                    padding: const EdgeInsets.only(left: 20.0, right: 20, top: 15),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Amenities:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        SingleChildScrollView(
                                          child: Wrap(
                                            spacing: 8.0,
                                            runSpacing: 8.0,
                                            children: amenities.map((amenity) {
                                              final isSelected = selectedAmenities.contains(amenity['id']);
                                              return ChoiceChip(
                                                label: Text(
                                                  amenity['name'],
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                                selected: isSelected,
                                                checkmarkColor: Colors.white,
                                                selectedColor: Colors.blueGrey,
                                                onSelected: (bool selected) {
                                                  setState(() {
                                                    if (selected) {
                                                      selectedAmenities.add(amenity['id']);
                                                    } else {
                                                      selectedAmenities.remove(amenity['id']);
                                                    }
                                                  });
                                                },
                                                backgroundColor: Colors.white,
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.only(left: 20.0, right: 20, top: 15),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Special Features:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        SingleChildScrollView(
                                          child: Wrap(
                                            spacing: 8.0,
                                            runSpacing: 8.0,
                                            children: specialfeatures.map((amenity) {
                                              final isSelected = selectedSpecialFeatures.contains(amenity['id']);
                                              return ChoiceChip(
                                                label: Text(
                                                  amenity['name'],
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                                selected: isSelected,
                                                checkmarkColor: Colors.white,
                                                selectedColor: Colors.blueGrey,
                                                onSelected: (bool selected) {
                                                  setState(() {
                                                    if (selected) {
                                                      selectedSpecialFeatures.add(amenity['id']);
                                                    } else {
                                                      selectedSpecialFeatures.remove(amenity['id']);
                                                    }
                                                  });
                                                },
                                                backgroundColor: Colors.white,
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                  Container(
                                    padding: const EdgeInsets.only(left: 20.0, right: 20, top: 15),
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
                                                  border: OutlineInputBorder(),
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
                                                  border: OutlineInputBorder(),
                                                ),
                                                onChanged: (value) => _updateRangeFromTextFields(),
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height:10),

                                        RangeSlider(
                                          activeColor: Colors.blueGrey,
                                          inactiveColor: Colors.blueGrey.withOpacity(0.4),
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
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

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

                                  // assigned to field and heading

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

                                  Container(
                                    margin: EdgeInsets.only( top:15,
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
                                  ),

                                  Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

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
                                                  selectedInterestType = null;
                                                  selectedPropertyType = null;
                                                  selectedactivity_source = null;
                                                  nextFollowUpDate = null;
                                                  selectedUnitIds.clear();

                                                  selectedUnitType = "Select Unit Types";
                                                  selectedEmirates = "Select Emirate";
                                                  selectedEmiratesList.clear();

                                                   selectedAreasString = "Select Area";
                                                  selectedAreas.clear();
                                                  selectedAmenities.clear();
                                                  selectedSpecialFeatures.clear();

                                                  range_min = prefs!.getDouble('range_min') ?? 10000;
                                                  range_max = prefs!.getDouble('range_max') ?? 100000;

                                                  double range_start = range_min! + (range_min! / 0.8);
                                                  double range_end = range_max! - (range_max! * 0.2);

                                                  _currentRangeValues = RangeValues(range_start, range_end);

                                                  startController.text = _currentRangeValues!.start.toStringAsFixed(0);
                                                  endController.text = _currentRangeValues!.end.toStringAsFixed(0);



                                                  /*print(_selectedrole['role_name']);*/

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