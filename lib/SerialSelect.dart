import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SalesDashboard.dart';
import 'constants.dart';
import 'models/serial_model.dart'; // Import constants for appbar_color

class CompanySelection extends StatefulWidget {
  @override
  _CompanySelectionState createState() => _CompanySelectionState();
}

class _CompanySelectionState extends State<CompanySelection> {
  List<RegisteredCompany> companies = [];
  RegisteredCompany? selectedCompany;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  /// ✅ Load Companies from SharedPreferences
  Future<void> _loadCompanies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? companiesJson = prefs.getString("companies_list");

    if (companiesJson != null) {
      List<dynamic> companiesList = jsonDecode(companiesJson);
      setState(() {
        companies = companiesList.map((data) => RegisteredCompany.fromJson(data)).toList();
      });
    }

    print("✅ Loaded ${companies.length} Companies");
  }

  /// ✅ Save Selection in SharedPreferences
  Future<void> saveSelection() async {
    if (selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a company"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt("company_id", selectedCompany!.id);
    await prefs.setString("company_token", selectedCompany!.token);
    await prefs.setString("company_name", selectedCompany!.name);

    print("✅ Selected Company: ${selectedCompany!.name}");
    print("🔑 Company Token: ${selectedCompany!.token}");

    await loadTokens();


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SalesDashboard()), // Navigate to dashboard
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA), // Light modern background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Select Company", style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white
        )),
        backgroundColor: appbar_color, // Using appbar_color from constants.dart
        elevation: 4,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Card(
            elevation: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16), // Ensure gradient follows card shape
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Avoid unnecessary expansion
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    companies.map((company) => DropdownMenuItem(
                        value: company,
                        child: Text(company.name))
                    ).toList(),
                        (RegisteredCompany? newCompany) async {
                      if (newCompany != null) {
                        setState(() {
                          selectedCompany = newCompany;
                        });
                        SharedPreferences prefs = await SharedPreferences.getInstance();

                         await prefs.setInt("company_id", newCompany!.id);
                        await prefs.setString("company_token", newCompany!.token);
                        await prefs.setString("company_name", newCompany!.name);

                        print("✅ Selected Company: ${newCompany.name}");
                        print("🔑 Company Token: ${newCompany.token}");
                        print("🔑 Company ID: ${newCompany.id}");
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

/// ✅ Generic Dropdown Builder
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
