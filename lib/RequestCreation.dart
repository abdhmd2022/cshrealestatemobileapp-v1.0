import 'dart:convert';
import 'dart:io';

import 'package:cshrealestatemobile/RequestList.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'TenantDashboard.dart';

class SpecialRequestScreen extends StatefulWidget {
  const SpecialRequestScreen({Key? key}) : super(key: key);

  @override
  State<SpecialRequestScreen> createState() => _SpecialRequestScreenState();
}

class _SpecialRequestScreenState extends State<SpecialRequestScreen> {
  Map<String, dynamic>? tenantData;
  List<Map<String, dynamic>> requestTypes = [];
  int? selectedRequestTypeId;
  Map<String, dynamic>? tenantFlatDetails;

  final _formKey = GlobalKey<FormState>();

  TextEditingController descriptionController = TextEditingController();
  bool isLoading = true;
  int? selectedFlatId;
  int? selectedContractId;

  List<Map<String, dynamic>> tenantFlats = [];

  bool isSubmitting = false;

  Future<void> fetchTenantAndRequestTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFlatId = prefs.getInt('flat_id'); // 👈 fetch saved flat_id

      // Fetch tenant + types
      final tenantResponse = await http.get(
        Uri.parse('$baseurl/tenant/$user_id'),
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        },
      );

      final typesResponse = await http.get(
        Uri.parse('$baseurl/tenant/requestType'),
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        },
      );

      final tenantJson = json.decode(tenantResponse.body);
      final typesJson = json.decode(typesResponse.body);

      final contracts = tenantJson['data']['tenant']['contracts'];
      for (var contract in contracts) {
        final contractId = contract['id'];
        final flats = contract['flats'] ?? [];

        for (var flatWrapper in flats) {
          final flat = flatWrapper['flat'];
          tenantFlats.add({
            'flatId': flat['id'],
            'flatName': flat['name'],
            'buildingName': 'Building ${flat['building_id']}',
            'areaName': 'Area Name',
            'contractId': contractId,
          });
        }
      }


      requestTypes = (typesJson['data']['types'] as List).map((e) => {
        'id': e['id'],
        'name': e['name'],
      }).toList();

      // 🔘 Set selected based on shared prefs OR fallback to first
      if (tenantFlats.isNotEmpty) {
        final matchedFlat = tenantFlats.firstWhere(
              (f) => f['flatId'] == savedFlatId,
          orElse: () => tenantFlats.first,
        );
        selectedFlatId = matchedFlat['flatId'];
        selectedContractId = matchedFlat['contractId'];
      }
    } catch (e) {
      print("Error fetching tenant/request types: $e");
    }

    setState(() => isLoading = false);
  }
  @override
  void initState() {
    super.initState();

    fetchTenantAndRequestTypes();

  }



  Future<void> submitRequest() async {

    var uuidValue = Uuid();

    String uuid = uuidValue.v4();

    if (!_formKey.currentState!.validate()) return;


    setState(() => isSubmitting = true);


    try {
      final response = await http.post(
        Uri.parse('$baseurl/tenant/request'),
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "contract_id": selectedContractId,
          "flat_id": selectedFlatId,
          "type_id": selectedRequestTypeId,
          "uuid": uuid,
          "description": descriptionController.text.trim(),
        }),
      );

      final data = json.decode(response.body);
      final message = data['message'] ?? 'Request submitted.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: data['success'] == true ? Colors.green[600] : Colors.red[600],
        ),
      );

      if (data['success'] == true) {
        setState(() {

          if (tenantFlats.isNotEmpty) {
            final matchedFlat = tenantFlats.firstWhere(
                  (f) => f['flatId'] == flat_id,
              orElse: () => tenantFlats.first,
            );
            selectedFlatId = matchedFlat['flatId'];
            selectedContractId = matchedFlat['contractId'];
          }

          selectedRequestTypeId = null;
          descriptionController.clear();
        });
      }

    } catch (e) {
      print("Submit error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red[600],
        ),
      );
    }

    setState(() => isSubmitting = false);
  }

  @override
  // ✅ 2025 Modern UI Enhancements
  Widget build(BuildContext context) {
    final Color appbarColor = appbar_color;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Request", style: GoogleFonts.poppins(fontWeight: FontWeight.normal,
          color: Colors.white, // ← Color set here

        ),),
        backgroundColor: appbarColor,
        automaticallyImplyLeading: true, // ✅ Ensures back button shows when needed
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => RequestListScreen()),
            );
          },
        ),

        elevation: 6,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
        child: Center(
          child: Platform.isIOS
              ? const CupertinoActivityIndicator(radius: 18)
              : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(appbarColor),
            strokeWidth: 3.0,
          ),
        )
      )
          : Padding(
    padding: const EdgeInsets.all(16),
    child: SingleChildScrollView(
    child: Form(
      key: _formKey,
      child:
      Column(
        children: [
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: "Unit(s)",
              hintText: "Select Unit(s)",
              labelStyle: GoogleFonts.poppins(color: Colors.black),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: appbarColor, width: 1), // 🔵 On focus
              ),
            ),
            value: selectedFlatId,
            validator: (value) => value == null ? 'Please select a unit' : null,

            items: tenantFlats.map((item) {
              return DropdownMenuItem<int>(
                value: item['flatId'],
                child: Text(
                  "${item['flatName']} - ${item['buildingName']}, ${item['areaName']}",
                  style: GoogleFonts.poppins(),
                ),
              );
            }).toList(),
            onChanged: (flatId) {
              setState(() {
                selectedFlatId = flatId;
                selectedContractId = tenantFlats.firstWhere(
                      (item) => item['flatId'] == flatId,
                )['contractId'];
              });
            },
          ),

          const SizedBox(height: 15),

          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: "Request Type(s)",

              labelStyle: GoogleFonts.poppins(color: Colors.black),
              hintText: "Select Request Type(s)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: appbarColor, width: 1), // 🔵 On focus
              ),
            ),
            value: selectedRequestTypeId,
            validator: (value) => value == null ? 'Please select request type' : null,

            items: requestTypes.map((type) {
              return DropdownMenuItem<int>(
                value: type['id'],
                child: Text(type['name'], style: GoogleFonts.poppins()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedRequestTypeId = value;
              });
            },
          ),
          const SizedBox(height: 18),

          // 🔹 Description Field
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Description", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          TextFormField(
              controller: descriptionController,
              maxLines: 5,
              maxLength: 100,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter description';
                } else if (val.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },

              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: "Write your request description...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: appbarColor),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (val)
              {
                descriptionController.text = val;
              }
          ),

          const SizedBox(height: 32),

          // 🔹 Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: isSubmitting
                  ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Icon(Icons.send_rounded,color:Colors.white),
              label: Text(
                isSubmitting ? "Submitting..." : "Submit Request",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              onPressed: isSubmitting ? null : submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: appbarColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 6,
                shadowColor: appbarColor.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    ),

    )))
    ;
  }

}
Widget _buildTenantIconRow(IconData icon, String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: appbar_color, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black)),
              Text(
                value ?? '—',
                style: GoogleFonts.poppins(fontSize: 14.5, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
Widget platformLoader() {
  return Platform.isIOS
      ? CupertinoActivityIndicator(radius: 12) // iOS-style loader
      : CircularProgressIndicator(
    color: appbar_color, // Matches button text color
    strokeWidth: 3, // Thin and modern look
  );
}