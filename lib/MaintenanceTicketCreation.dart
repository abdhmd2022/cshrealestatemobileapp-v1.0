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
import 'package:intl/intl.dart';
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
  Map<int, TextEditingController> _descriptionControllers = {};
  // TextEditingController _totalamountController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      isVisibleNoRoleFound = false;

  final DateFormat dateFormatter = DateFormat('dd-MMM-yyyy');


  DateTimeRange? selectedDateRange;
  TimeOfDay? startTime;
  TimeOfDay? endTime;


  String name = "",email = "";

  bool selectAll = false;

   List<dynamic> flats = [];

  Map<String, dynamic>? selectedFlat; // Stores the selected flat object

  List<dynamic> _attachment = []; // List to store selected images

  final ImagePicker _picker = ImagePicker();

  Future<void> _showFlatPicker(BuildContext context) async {
    TextEditingController searchController = TextEditingController();
    List<dynamic> filteredFlats = List.from(flats);

    final selected = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setModalState(() {
                            filteredFlats = flats
                                .where((flat) =>
                            flat['flat_name'].toLowerCase().contains(value.toLowerCase()) ||
                                flat['tenant_name'].toLowerCase().contains(value.toLowerCase()) ||
                                flat['building_name'].toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: GoogleFonts.poppins(color: Colors.black45),
                          prefixIcon: Icon(Icons.search, color: appbar_color),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              setModalState(() {
                                filteredFlats = List.from(flats);
                              });
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: appbar_color, width: 1.5),
                          ),
                        ),
                      ),


                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredFlats.length,
                    itemBuilder: (context, index) {
                      final flat = filteredFlats[index];
                       return Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0), // spacing between tiles
                        decoration: BoxDecoration(
                          color: selectedFlat != null && flat['flat_id'] == selectedFlat!['flat_id']
                              ? appbar_color.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Optional: ripple effect also matches
                          ),
                          title: Text(
                            '${flat['tenant_name']} | ${flat['flat_name']} | ${flat['building_name']}',
                            style: GoogleFonts.poppins(
                              fontWeight: selectedFlat != null && flat['flat_id'] == selectedFlat!['flat_id']
                                  ? FontWeight.normal
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: selectedFlat != null && flat['flat_id'] == selectedFlat!['flat_id']
                              ? Icon(Icons.check_circle, color: appbar_color)
                              : null,
                          onTap: () {
                            Navigator.pop(context, flat); // Pass selected flat back
                          },
                        ),
                      );


                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedFlat = selected;
      });
    }
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

  // new fetch units function
  Future<void> fetchUnits() async {
    flats.clear();
    print('user id $user_id');

    String token = 'Bearer $Company_Token';

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    try {
      if (is_admin) {
        // ✅ 1. Fetch Tenants
        final tenantResponse = await http.get(Uri.parse('$baseurl/tenant'), headers: headers);
        if (tenantResponse.statusCode == 200) {
          final tenantData = json.decode(tenantResponse.body);
          List<dynamic> tenants = tenantData['data']['tenants'] ?? [];

          for (var tenant in tenants) {
            String tenantName = tenant['name'] ?? '';
            List<dynamic> contracts = tenant['contracts'] ?? [];

            for (var contract in contracts) {
              int contractId = contract['id'];
              List<dynamic> contractFlats = contract['flats'] ?? [];

              for (var flatData in contractFlats) {
                var flat = flatData['flat'];
                if (flat != null) {
                  flats.add({
                    'user_type': 'Tenant',
                    'tenant_name': tenantName,
                    'flat_id': flat['id'],
                    'flat_name': flat['name'],
                    'building_name': flat['building']['name'],
                    'area_name': flat['building']['area']['name'],
                    'emirate': flat['building']['area']['state']['name'],
                    'flat_type': flat['flat_type']['name'],
                    'contract_id': contractId,
                  });
                }
              }
            }
          }
        }

        // ✅ 2. Fetch Landlords
        final landlordResponse = await http.get(Uri.parse('$baseurl/landlord'), headers: headers);
        if (landlordResponse.statusCode == 200) {
          final landlordData = json.decode(landlordResponse.body);
          List<dynamic> landlords = landlordData['data']['landlords'] ?? [];

          for (var landlord in landlords) {
            String landlordName = landlord['name'] ?? '';
            List<dynamic> boughtContracts = landlord['bought_contracts'] ?? [];

            for (var contract in boughtContracts) {
              int contractId = contract['id'];
              List<dynamic> contractFlats = contract['flats'] ?? [];

              for (var flatData in contractFlats) {
                var flat = flatData['flat'];
                if (flat != null) {
                  flats.add({
                    'user_type': 'Landlord',
                    'tenant_name': landlordName,
                    'flat_id': flat['id'],
                    'flat_name': flat['name'],
                    'building_name': flat['building']['name'],
                    'area_name': flat['building']['area']['name'],
                    'emirate': flat['building']['area']['state']['name'],
                    'flat_type': flat['flat_type']['name'],
                    'contract_id': contractId,
                  });
                }
              }
            }
          }
        }

      } else {
        // ✅ Tenant or Landlord (Single)
        String url = is_landlord
            ? '$baseurl/landlord/$user_id'
            : '$baseurl/tenant/$user_id';

        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (is_landlord) {
            var landlord = data['data']['landlord'];
            if (landlord != null) {
              String landlordName = landlord['name'] ?? '';
              List<dynamic> boughtContracts = landlord['bought_contracts'] ?? [];

              for (var contract in boughtContracts) {
                int contractId = contract['id'];
                List<dynamic> contractFlats = contract['flats'] ?? [];

                for (var flatData in contractFlats) {
                  var flat = flatData['flat'];
                  if (flat != null) {
                    flats.add({
                      'user_type': 'Landlord',
                      'tenant_name': landlordName,
                      'flat_id': flat['id'],
                      'flat_name': flat['name'],
                      'building_name': flat['building']['name'],
                      'area_name': flat['building']['area']['name'],
                      'emirate': flat['building']['area']['state']['name'],
                      'flat_type': flat['flat_type']['name'],
                      'contract_id': contractId,
                    });
                  }
                }
              }
            }
          } else {
            var tenant = data['data']['tenant'];
            if (tenant != null) {
              String tenantName = tenant['name'] ?? '';
              List<dynamic> contracts = tenant['contracts'] ?? [];

              for (var contract in contracts) {
                int contractId = contract['id'];
                List<dynamic> contractFlats = contract['flats'] ?? [];

                for (var flatData in contractFlats) {
                  var flat = flatData['flat'];
                  if (flat != null) {
                    flats.add({
                      'user_type': 'Tenant',
                      'tenant_name': tenantName,
                      'flat_id': flat['id'],
                      'flat_name': flat['name'],
                      'building_name': flat['building']['name'],
                      'area_name': flat['building']['area']['name'],
                      'emirate': flat['building']['area']['state']['name'],
                      'flat_type': flat['flat_type']['name'],
                      'contract_id': contractId,
                    });
                  }
                }
              }
            }
          }
        }
      }

      // ✅ After all, update UI
      setState(() {
        selectedFlat = flats.firstWhere(
              (flat) => flat['flat_id'] == loaded_flat_id,
          orElse: () => flats.isNotEmpty ? flats[0] : {},
        );

        flats.sort((a, b) => (a['flat_name'] ?? '').compareTo(b['flat_name'] ?? ''));
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }


  // no 2 old fetch units function
  /*Future<void> fetchUnits() async {
    flats.clear();
    print('user id $user_id');

    String url = is_admin
        ? '$baseurl/tenant'
        : is_landlord
        ? '$baseurl/landlord/$user_id'
        : '$baseurl/tenant/$user_id';

    String token = 'Bearer $Company_Token';

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      print('code ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('data: $data');

        setState(() {
          flats.clear();

          if (is_admin) {
            List<dynamic> tenants = data['data']['tenants'] ?? [];
            for (var tenant in tenants) {
              String tenantName = tenant['name'] ?? '';
              List<dynamic> contracts = tenant['contracts'] ?? [];

              for (var contract in contracts) {
                int contractId = contract['id'];
                List<dynamic> contractFlats = contract['flats'] ?? [];

                for (var flatData in contractFlats) {
                  var flat = flatData['flat'];
                  if (flat != null) {
                    flats.add({
                      'tenant_name': tenantName,
                      'flat_id': flat['id'],
                      'flat_name': flat['name'],
                      'building_name': flat['building']['name'],
                      'area_name': flat['building']['area']['name'],
                      'emirate': flat['building']['area']['state']['name'],
                      'flat_type': flat['flat_type']['name'],
                      'contract_id': contractId,
                    });
                  }
                }
              }
            }

          } else if (is_landlord) {
            var landlord = data['data']['landlord'];
            if (landlord != null) {
              String landlordName = landlord['name'] ?? '';
              List<dynamic> boughtContracts = landlord['bought_contracts'] ?? [];

              for (var contract in boughtContracts) {
                int contractId = contract['id'];
                List<dynamic> contractFlats = contract['flats'] ?? [];

                for (var flatData in contractFlats) {
                  var flat = flatData['flat'];
                  if (flat != null) {
                    flats.add({
                      'tenant_name': landlordName, // You may rename this key if needed
                      'flat_id': flat['id'],
                      'flat_name': flat['name'],
                      'building_name': flat['building']['name'],
                      'area_name': flat['building']['area']['name'],
                      'emirate': flat['building']['area']['state']['name'],
                      'flat_type': flat['flat_type']['name'],
                      'contract_id': contractId,
                    });
                  }
                }
              }
            }

          } else {
            var tenant = data['data']['tenant'];
            if (tenant != null) {
              String tenantName = tenant['name'] ?? '';
              List<dynamic> contracts = tenant['contracts'] ?? [];

              for (var contract in contracts) {
                int contractId = contract['id'];
                List<dynamic> contractFlats = contract['flats'] ?? [];

                for (var flatData in contractFlats) {
                  var flat = flatData['flat'];
                  if (flat != null) {
                    flats.add({
                      'tenant_name': tenantName,
                      'flat_id': flat['id'],
                      'flat_name': flat['name'],
                      'building_name': flat['building']['name'],
                      'area_name': flat['building']['area']['name'],
                      'emirate': flat['building']['area']['state']['name'],
                      'flat_type': flat['flat_type']['name'],
                      'contract_id': contractId,
                    });
                  }
                }
              }
            }
          }

          // ✅ Default selected flat
          selectedFlat = flats.firstWhere(
                (flat) => flat['flat_id'] == loaded_flat_id,
            orElse: () => flats.isNotEmpty ? flats[0] : {},
          );

          // ✅ Sort by flat name
          flats.sort((a, b) => (a['flat_name'] ?? '').compareTo(b['flat_name'] ?? ''));
        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }*/


  // no 1 old fetch units function
  /*Future<void> fetchUnits() async {
    flats.clear();
    print('user id $user_id');

    String url = is_admin
        ? '$baseurl/tenant'
        : '$baseurl/tenant/$user_id';

    String token = 'Bearer $Company_Token';

    Map<String, String> headers = {
      'Authorization': token,
      "Content-Type": "application/json"
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      print('code ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('data: $data');

        setState(() {
          flats.clear();

          if (is_admin) {
            // ✅ Admin: iterate all tenants
            List<dynamic> tenants = data['data']['tenants'] ?? [];

            for (var tenant in tenants) {
              String tenantName = tenant['name'] ?? '';

              List<dynamic> contracts = tenant['contracts'] ?? [];
              for (var contract in contracts) {
                int contractId = contract['id'];

                List<dynamic> contractFlats = contract['flats'] ?? [];
                for (var flatData in contractFlats) {
                  var flat = flatData['flat'];

                  if (flat != null) {
                    flats.add({
                      'tenant_name': tenantName,
                      'flat_id': flat['id'],
                      'flat_name': flat['name'],
                      'building_name': flat['building']['name'],
                      'area_name': flat['building']['area']['name'],
                      'emirate': flat['building']['area']['state']['name'],
                      'flat_type': flat['flat_type']['name'],
                      'contract_id': contractId,
                    });
                  }
                }
              }
            }

          } else {
            // ✅ Tenant: single tenant object
            var tenant = data['data']['tenant'];
            if (tenant != null) {
              String tenantName = tenant['name'] ?? '';

              List<dynamic> contracts = tenant['contracts'] ?? [];
              for (var contract in contracts) {
                int contractId = contract['id'];

                List<dynamic> contractFlats = contract['flats'] ?? [];
                for (var flatData in contractFlats) {
                  var flat = flatData['flat'];

                  if (flat != null) {
                    flats.add({
                      'tenant_name': tenantName,
                      'flat_id': flat['id'],
                      'flat_name': flat['name'],
                      'building_name': flat['building']['name'],
                      'area_name': flat['building']['area']['name'],
                      'emirate': flat['building']['area']['state']['name'],
                      'flat_type': flat['flat_type']['name'],
                      'contract_id': contractId,
                    });
                  }
                }
              }
            }
          }

          // ✅ Set default selected flat
          selectedFlat = flats.firstWhere(
                (flat) => flat['flat_id'] == loaded_flat_id,
            orElse: () => flats.isNotEmpty ? flats[0] : {},
          );

          // ✅ Sort by flat name
          flats.sort((a, b) => (a['flat_name'] ?? '').compareTo(b['flat_name'] ?? ''));
        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }*/

  /*Future<void> fetchUnits() async {
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

          flats.sort((a, b) => (a['flat_name'] ?? '').compareTo(b['flat_name'] ?? ''));

        });
      } else {
        print("Error: ${response.statusCode}");
        print("Message: ${response.body}");
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }*/

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
    if (_attachment.length >= 5) {
      Fluttertoast.showToast(
        msg: 'You can attach a maximum of 5 images',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return; // Skip if already at limit
    }

    List<XFile>? pickedFiles;

    if (fromCamera) {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera);

      if (file != null) {
        if (_attachment.length >= 5) {
          Fluttertoast.showToast(
            msg: 'Maximum 5 attachments allowed',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }

        setState(() {
          if (kIsWeb) {
            _handleWebFile(file);
          } else {
            _handleMobileFile(file);
          }
        });
      }
    } else {
      pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          if (_attachment.length >= 5) {
            Fluttertoast.showToast(
              msg: 'Maximum 5 attachments allowed',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.black,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            break;
          }

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
                  if (_attachment.length < 5)
                    _attachmentOption(
                    icon: Icons.upload,
                    label: 'Upload',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages(); // Pick images from gallery (works for Web & Mobile)
                    },
                  ),
                  if (!kIsWeb && _attachment.length < 5) // Camera option is not supported on Web
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
                                      : "No Flat Assigned",
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

                    Padding(
                      padding: const EdgeInsets.only(left: 16.0,right:16, top: 0,bottom:12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📅 DATE RANGE CARD
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 18, color: appbar_color),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Available Date",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                      initialDateRange: selectedDateRange,
                                      builder: (context, child) {
                                        return Theme(
                                          data: ThemeData.light().copyWith(
                                            primaryColor: appbar_color, // ✅ Header & buttons color
                                            scaffoldBackgroundColor: Colors.white,
                                            colorScheme: ColorScheme.light(
                                              primary: appbar_color, // ✅ Start & End date circle color
                                              onPrimary: Colors.white, // ✅ Text inside Start & End date
                                              secondary: appbar_color.withOpacity(0.6), // ✅ In-Between date highlight color
                                              onSecondary: Colors.white, // ✅ Text color inside In-Between dates
                                              surface: Colors.white, // ✅ Background color
                                              onSurface: Colors.black, // ✅ Default text color
                                            ),
                                            dialogBackgroundColor: Colors.white,
                                          ),
                                          child: child!,
                                        );
                                      },


                                    );
                                    if (picked != null) {
                                      setState(() {
                                        selectedDateRange = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      selectedDateRange != null
                                          ? "${dateFormatter.format(selectedDateRange!.start)} → ${dateFormatter.format(selectedDateRange!.end)}"
                                          : "Select date range",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),

                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ⏰ TIME RANGE CARD
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time_outlined, size: 18, color: appbar_color),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Available Time",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () async {
                                    final TimeOfDay? start = await showTimePicker(
                                      context: context,
                                      initialTime: const TimeOfDay(hour: 9, minute: 0), // ✅ hardcoded default
                                      builder: (context, child) {
                                        return Theme(
                                          data: ThemeData.light().copyWith(
                                            dialogBackgroundColor: Colors.white,
                                            timePickerTheme: TimePickerThemeData(
                                              backgroundColor: Colors.white,
                                              hourMinuteTextColor: appbar_color,
                                              hourMinuteShape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: appbar_color, width: 1),
                                              ),
                                              dialHandColor: appbar_color,
                                              dialTextColor: Colors.black,
                                              entryModeIconColor: appbar_color,
                                              dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
                                              states.contains(MaterialState.selected) ? Colors.white : appbar_color),
                                              dayPeriodShape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                side: BorderSide(color: appbar_color),
                                              ),
                                              dayPeriodColor: MaterialStateColor.resolveWith((states) =>
                                              states.contains(MaterialState.selected) ? appbar_color : Colors.white),
                                              helpTextStyle: GoogleFonts.poppins(
                                                color: appbar_color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              cancelButtonStyle: TextButton.styleFrom(foregroundColor: appbar_color),
                                              confirmButtonStyle: TextButton.styleFrom(foregroundColor: appbar_color),
                                            ),
                                            colorScheme: ColorScheme.light(
                                              primary: Colors.white,
                                              onSurface: Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },

                                    );
                                    if (start != null) {
                                      final TimeOfDay? end = await showTimePicker(
                                        context: context,
                                        initialTime: const TimeOfDay(hour: 19, minute: 0), // ✅ 7 PM
                                        builder: (context, child) {
                                          return Theme(
                                            data: ThemeData.light().copyWith(
                                              dialogBackgroundColor: Colors.white,
                                              timePickerTheme: TimePickerThemeData(
                                                backgroundColor: Colors.white,
                                                hourMinuteTextColor: appbar_color,
                                                hourMinuteShape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(color: appbar_color, width: 1),
                                                ),
                                                dialHandColor: appbar_color,
                                                dialTextColor: Colors.black,
                                                entryModeIconColor: appbar_color,
                                                dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
                                                states.contains(MaterialState.selected) ? Colors.white : appbar_color),
                                                dayPeriodShape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  side: BorderSide(color: appbar_color),
                                                ),
                                                dayPeriodColor: MaterialStateColor.resolveWith((states) =>
                                                states.contains(MaterialState.selected) ? appbar_color : Colors.white),
                                                helpTextStyle: GoogleFonts.poppins(
                                                  color: appbar_color,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                cancelButtonStyle: TextButton.styleFrom(foregroundColor: appbar_color),
                                                confirmButtonStyle: TextButton.styleFrom(foregroundColor: appbar_color),
                                              ),
                                              colorScheme: ColorScheme.light(
                                                primary: Colors.white,
                                                onSurface: Colors.white,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },

                                      );
                                      if (end != null) {
                                        setState(() {
                                          startTime = start;
                                          endTime = end;
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      (startTime != null && endTime != null)
                                          ? "${startTime!.format(context)} → ${endTime!.format(context)}"
                                          : "Select time range",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ],
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

                        GestureDetector(
                          onTap: () => _showMaintenanceTypeSelector(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            margin: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black54, width: 0.75),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedMaintenanceType!.isEmpty
                                        ? "Select Maintenance Type"
                                        : selectedMaintenanceType!.map((e) => e.name).join(', '),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: selectedMaintenanceType!.map((type) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 0, right: 0, bottom: 5),
                                    child: TextFormField(
                                      controller: _descriptionControllers[type.id],
                                      maxLines: 2,
                                      maxLength: 100,
                                      decoration: InputDecoration(
                                        labelText: '${type.name} Description',
                                        hintText: 'Enter description for ${type.name}',
                                        floatingLabelStyle: GoogleFonts.poppins(color: appbar_color),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(11),
                                          borderSide: BorderSide(color: appbar_color),
                                        ),

                                      ),
                                      style: GoogleFonts.poppins(fontSize: 15),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ),

                          Container(
                            margin: EdgeInsets.only(left: 20, right: 20),
                            child: Row(
                              children: [
                                Text(
                                  'Attachments',
                                  style: GoogleFonts.poppins(fontSize: 16,
                                    fontWeight: FontWeight.bold,),
                                ),
                                /*SizedBox(width: 2),
                                Text(
                                  '*', // Red asterisk for required field
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    color: Colors.red, // Red color for the asterisk
                                  ),
                                ),*/
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
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

                                          if (_attachment.length < 5)
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
                                            ))]),

                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 0.0,top:10),
                                        child: Text(
                                          '${_attachment.length} of 5 attachments selected',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),])
                                else
                                  Column(
                                    children: [
                                      if (_attachment.length < 5)
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
                          if (selectedMaintenanceType!.any((type) =>
                          _descriptionControllers[type.id]?.text.trim().isEmpty ?? true)) {
                            Fluttertoast.showToast(
                              msg: 'Please enter description for all selected types.',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          }


                          else if (_attachment.length > 5)
                          {
                            Fluttertoast.showToast(
                              msg: 'You can attach a maximum of 5 images only',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
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
                    );
  }


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
    String? availableFromStr;
    String? availableToStr;
    final DateFormat dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    if (selectedDateRange == null || startTime == null || endTime == null) {
      Fluttertoast.showToast(
        msg: 'Please select both date and time range.',
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    } else {
      final from = DateTime(
        selectedDateRange!.start.year,
        selectedDateRange!.start.month,
        selectedDateRange!.start.day,
        startTime!.hour,
        startTime!.minute,
      );
      final to = DateTime(
        selectedDateRange!.end.year,
        selectedDateRange!.end.month,
        selectedDateRange!.end.day,
        endTime!.hour,
        endTime!.minute,
      );

      if (!from.isBefore(to)) {
        Fluttertoast.showToast(
          msg: 'Start time must be before end time.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      if (from.isBefore(DateTime.now())) {
        Fluttertoast.showToast(
          msg: 'Start time must be in the future.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      availableFromStr = dateTimeFormatter.format(from);
      availableToStr = dateTimeFormatter.format(to);
    }

    try {
      String url = "$baseurl/maintenance/ticket";
      var uuid = Uuid();
      String uuidValue = uuid.v4();

      print('type list ${selectedMaintenanceTypeIds}');

      final Map<String, dynamic> requestBody = {
        "uuid": uuidValue,
        "flat_id": selectedFlat?['flat_id'],
        "types": selectedMaintenanceType!.map((type) => {
          "id": type.id,
          "description": _descriptionControllers[type.id]?.text ?? ""
        }).toList(),
        "available_from": availableFromStr,
        "available_to": availableToStr,
      };

// ✅ Add contract ID dynamically
      if (is_admin) {
        // Admin: check the selected unit type
        if (selectedFlat?['user_type'] == 'Landlord') {
          requestBody['sales_contract_id'] = selectedFlat?['contract_id'];
        } else {
          requestBody['rental_contract_id'] = selectedFlat?['contract_id'];
        }
      } else if (is_landlord) {
        requestBody['sales_contract_id'] = selectedFlat?['contract_id'];
      } else {
        // Default = Tenant
        requestBody['rental_contract_id'] = selectedFlat?['contract_id'];
      }

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
          _descriptionControllers.clear();
          selectedFlat = flats[0];
          _attachment.clear();
          selectedDateRange = null;
          startTime = null;
          endTime = null;
        });

        showResponseSnackbar(context, decodedResponse);

        int ticketId = decodedResponse['data']['ticket']['id'];
        if(_attachment.length>0)
          {
            await sendImageData(ticketId, context); // ✅ separate request for attachments
          }

      } else {
        showResponseSnackbar(context, decodedResponse);
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

      if (response.statusCode == 201) {

        setState(() {
          selectedMaintenanceType = [];
          selectedMaintenanceTypeIds = [];
          _descriptionControllers.clear();
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
  void _showMaintenanceTypeSelector(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    List<MaintanceType> filteredList = List.from(maintenance_types_list);
    List<MaintanceType> tempSelected = List.from(selectedMaintenanceType!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20), // Rounded corners
              ),              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setModalState(() {
                            filteredList = maintenance_types_list
                                .where((type) =>
                            type.name.toLowerCase().contains(value.toLowerCase()) ||
                                type.category.toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                        style: GoogleFonts.poppins(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: GoogleFonts.poppins(color: Colors.black45),
                          prefixIcon: Icon(Icons.search, color: appbar_color),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              setModalState(() {
                                filteredList = List.from(maintenance_types_list);
                              });
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: appbar_color, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],),

                  SizedBox(height: 16),

                  // List of checkboxes
                  Expanded(
                    child: ListView(
                      children: [
                        // 🔹 Select All option
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 0),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            title: Text("Select All", style: GoogleFonts.poppins(fontWeight: FontWeight.normal)),
                            value: tempSelected.length == maintenance_types_list.length,
                            activeColor: appbar_color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onChanged: (bool? checked) {
                              setModalState(() {
                                if (checked == true) {
                                  tempSelected = List.from(maintenance_types_list); // Select all
                                } else {
                                  tempSelected.clear(); // Deselect all
                                }
                              });
                            },
                          ),
                        ),

                        Divider(),

                        // 🔹 Regular items
                        ...filteredList.map((type) {
                          final isSelected = tempSelected.contains(type);

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CheckboxListTile(
                              title: Text(type.name, style: GoogleFonts.poppins()),
                              value: isSelected,
                              activeColor: appbar_color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onChanged: (bool? checked) {
                                setModalState(() {
                                  if (checked == true) {
                                    tempSelected.add(type);
                                  } else {
                                    tempSelected.remove(type);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  // Done button
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedMaintenanceType = List.from(tempSelected);
                            selectedMaintenanceTypeIds = selectedMaintenanceType!.map((e) => e.id).toList();
                            // Initialize controllers for each selected type
                            for (var type in selectedMaintenanceType!) {
                              _descriptionControllers.putIfAbsent(type.id, () => TextEditingController());
                            }

                            // Clean up controllers for unselected types
                            _descriptionControllers.removeWhere((key, value) =>
                            !selectedMaintenanceTypeIds.contains(key));
                          });
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.check, size: 20, color: Colors.white),
                        label: Text(
                          "Select",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appbar_color,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  )]))));});}}

