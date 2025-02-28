import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'TenantDashboard.dart';
import 'constants.dart';

class FlatSelection extends StatefulWidget {
  @override
  _FlatSelectionState createState() => _FlatSelectionState();
}

class _FlatSelectionState extends State<FlatSelection> {
  List<Map<String, dynamic>> flats = [];
  Map<String, dynamic>? selectedFlat;

  @override
  void initState() {
    super.initState();
    _loadFlats();
  }

  /// ✅ Load Flats from SharedPreferences
  Future<void> _loadFlats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? flatsJson = prefs.getString("flats_list");

    if (flatsJson != null) {
      List<dynamic> flatsList = jsonDecode(flatsJson);
      setState(() {
        flats = List<Map<String, dynamic>>.from(flatsList);
      });
    }

    print("✅ Loaded ${flats.length} Flats");
  }

  /// ✅ Save Selected Flat in SharedPreferences
  Future<void> saveSelection() async {
    if (selectedFlat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a flat"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt("flat_id", selectedFlat!['id']);
    await prefs.setString("flat_name", selectedFlat!['name']);
    await prefs.setString("floor", selectedFlat!['floor']);
    await prefs.setString("flat_type", selectedFlat!['flat_type']);
    await prefs.setString("building", selectedFlat!['building']);
    await prefs.setString("area", selectedFlat!['area']);
    await prefs.setString("state", selectedFlat!['state']);
    await prefs.setString("country", selectedFlat!['country']);

    print("✅ Selected Flat: ${selectedFlat!['name']} - ${selectedFlat!['building']}");

    await loadTokens();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TenantDashboard()), // Navigate to Tenant Dashboard
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Select Flat", style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white
        )),
        backgroundColor: appbar_color,
        elevation: 4,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            elevation: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Choose Flat",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildDropdown<Map<String, dynamic>>(
                    selectedFlat,
                    "Select Flat",
                    flats.map((flat) {
                      return DropdownMenuItem(
                        value: flat,
                        child: Text("${flat['name']} - ${flat['building']}"),
                      );
                    }).toList(),
                        (Map<String, dynamic>? newFlat) async {
                      if (newFlat != null) {
                        setState(() {
                          selectedFlat = newFlat;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: saveSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appbar_color.withOpacity(1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      ),
                      child: Text(
                        "Proceed",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔥 Custom Dropdown Widget
Widget _buildDropdown<T>(
    T? selectedValue,
    String hint,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
    ) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
    ),
    child: DropdownButtonFormField<T>(
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      value: selectedValue,
      hint: Text(hint),
      isExpanded: true,
      onChanged: onChanged,
      items: items,
    ),
  );
}
