import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SalesDashboard.dart';
import 'models/serial_model.dart'; // Import your existing Serial and RegisteredCompany models
import 'constants.dart'; // Import constants for appbar_color

class SerialNoSelection extends StatefulWidget {
  @override
  _SerialNoSelectionState createState() => _SerialNoSelectionState();
}

class _SerialNoSelectionState extends State<SerialNoSelection> {
  List<Serial> serials = [];
  List<RegisteredCompany> companies = [];
  Serial? selectedSerial;
  RegisteredCompany? selectedCompany;
  List<RegisteredCompany> filteredCompanies = [];

  @override
  void initState() {
    super.initState();
    _loadSerialsAndCompanies();
  }

  /// ✅ Load Serial and Companies from SharedPreferences
  Future<void> _loadSerialsAndCompanies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? serialsJson = prefs.getString("serials_list");
    String? companiesJson = prefs.getString("companies_list");

    if (serialsJson != null) {
      setState(() {
        serials = (jsonDecode(serialsJson) as List)
            .map((data) => Serial.fromJson(data))
            .toList();
      });
    }

    if (companiesJson != null) {
      setState(() {
        companies = (jsonDecode(companiesJson) as List)
            .map((data) => RegisteredCompany.fromJson(data))
            .toList();
      });
    }
  }

  /// ✅ Update Companies List when a Serial is selected
  void updateCompaniesList(Serial serial) {
    setState(() {
      selectedSerial = serial;
      filteredCompanies = serial.registeredCompanies;
      selectedCompany = null;
    });
  }

  /// ✅ Save Selection in SharedPreferences
  Future<void> saveSelection() async {
    if (selectedSerial == null || selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select both Serial and Company"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("serial_token", selectedSerial!.token);
    await prefs.setString("company_token", selectedCompany!.token);

    await loadTokens();

    Navigator.pushReplacement

      (
      context,
      MaterialPageRoute(builder: (context) => SalesDashboard()), // navigate to company and serial select screen
    );



  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA), // Light modern background
      appBar: AppBar(
        title: Text("Select Serial & Company", style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,color: Colors.white
        )),
        backgroundColor: appbar_color, // Using appbar_color from constants.dart
        elevation: 4,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Center(
          child:  Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Choose Serial Number", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: appbar_color[900])),
              SizedBox(height: 10),

              // Serial Number Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                  ],
                ),
                child: DropdownButtonFormField<Serial>(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  value: selectedSerial,
                  hint: Text(
                      'Select Serial No.'
                  ),
                  isExpanded: true,
                  onChanged: (Serial? newSerial) {
                    if (newSerial != null) {
                      updateCompaniesList(newSerial);
                    }
                  },
                  items: serials.map((Serial serial) {
                    return DropdownMenuItem<Serial>(
                      value: serial,
                      child: Text(serial.serialNo),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 20),
              Text("Choose Company", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: appbar_color[900])),
              SizedBox(height: 10),

              // Company Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                  ],
                ),
                child: DropdownButtonFormField<RegisteredCompany>(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  value: selectedCompany,
                  isExpanded: true,
                  onChanged: (RegisteredCompany? newCompany) {
                    setState(() {
                      selectedCompany = newCompany;
                    });
                  },
                  hint: Text(
                      'Select Company'
                  ),
                  items: filteredCompanies.map((RegisteredCompany company) {
                    return DropdownMenuItem<RegisteredCompany>(
                      value: company,
                      child: Text(company.name),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 30),

              // Save Selection Button
              Center(
                child: ElevatedButton(
                  onPressed: saveSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  child: Text(
                    "Proceed",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

      ),
    );
  }
}
