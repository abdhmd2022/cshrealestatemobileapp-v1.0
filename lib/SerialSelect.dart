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

    // ✅ Load user token (debugging)
    String? userToken = prefs.getString("user_token");
    int? userId = prefs.getInt("user_id");

    print("🔑 Loaded User Token from SharedPreferences: $userToken");
    print("🔑 Loaded User ID from SharedPreferences: $userId");


    String? serialsJson = prefs.getString("serials_list");
    String? companiesJson = prefs.getString("companies_list");

    if (serialsJson != null) {
      List<dynamic> serialsList = jsonDecode(serialsJson);
      setState(() {
        serials = serialsList.map((data) => Serial.fromJson(data, userToken: userToken ?? '',userId: userId ?? 0)).toList();
      });
    }

    if (companiesJson != null) {
      List<dynamic> companiesList = jsonDecode(companiesJson);
      setState(() {
        companies = companiesList.map((data) => RegisteredCompany.fromJson(data)).toList();
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

    // saving prefs values
    await prefs.setString("serial_token", selectedSerial!.userToken);

    await prefs.setInt("company_id", selectedCompany!.id);

    await prefs.setInt("serial_id", selectedSerial!.id);

    await prefs.setInt("user_id", selectedSerial!.userId);

    await prefs.setString("company_token", selectedCompany!.token);

    await prefs.setString("company_name", selectedCompany!.name);

    await prefs.setString("serial_no", selectedSerial!.serialNo);

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
        automaticallyImplyLeading:false,
        title: Text("Select Serial & Company", style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,color: Colors.white
        )),
        backgroundColor: appbar_color, // Using appbar_color from constants.dart
        elevation: 4,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.only(left:20,right: 20),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white70, Colors.white70],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16), // Ensure gradient follows card shape
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min, // To avoid unnecessary expansion
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Choose Serial Number",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildDropdown<Serial>(
                    selectedSerial,
                    "Select Serial No.",
                    serials.map((serial) => DropdownMenuItem(value: serial, child: Text(serial.serialNo))).toList(),
                        (Serial? newSerial) {
                      if (newSerial != null) {
                        setState(() {
                          selectedSerial = newSerial;
                          filteredCompanies = newSerial.registeredCompanies;
                          selectedCompany = null;
                        });

                        print("✅ Selected Serial No: ${newSerial.serialNo}");
                        print("🔑 User Token: ${newSerial.userToken}");
                        print("🔑 User ID: ${newSerial.userId}");
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Choose Company",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildDropdown<RegisteredCompany>(
                    selectedCompany,
                    "Select Company",
                    filteredCompanies
                        .map((company) => DropdownMenuItem(value: company, child: Text(company.name)))
                        .toList(),
                        (RegisteredCompany? newCompany) {
                      if (newCompany != null) {
                        setState(() {
                          selectedCompany = newCompany;
                        });

                        print("✅ Selected Company: ${newCompany.name}");
                        print("🔑 Company Token: ${newCompany.token}");
                        print("🔑 Company ID: ${newCompany.id}");
                      }}),
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
                        ))))]),
            ),
          ),
        ),
      ),
    );
  }
}

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
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
      ],
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

