import 'dart:convert';
import 'package:cshrealestatemobile/BuildingDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AdminDashboard.dart';
import 'constants.dart';
import 'models/serial_model.dart';
import 'package:http/http.dart' as http;


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

  Future<void> fetchAndSaveCompanyData(String baseurll,int company_id,String token) async {

    print('calling -> $baseurll');
    try {
      final url = Uri.parse('$baseurll/company/details/$company_id');
      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },);

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final company = responseJson['data']['company'];

        await saveCompanyData(company);

      } else {
        print('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> saveCompanyData(Map<String, dynamic> company) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('mailing_name', company['mailing_name'] ?? '');
    await prefs.setString('address', company['address'] ?? '');
    await prefs.setString('pincode', company['pincode'] ?? '');
    await prefs.setString('state', company['state'] ?? '');
    await prefs.setString('country', company['country'] ?? '');
    await prefs.setString('trn', company['trn'] ?? '');
    await prefs.setString('phone', company['phone'] ?? '');
    await prefs.setString('mobile', company['mobile'] ?? '');
    await prefs.setString('email', company['email'] ?? '');
    await prefs.setString('website', company['website'] ?? '');
    await prefs.setString('logo_path', company['logo_path'] ?? '');
    await prefs.setString('whatsapp_no', company['whatsapp_no'] ?? '');

    print('Company data saved');

    loadTokens();
    print('Company data loaded');


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminDashboard()),
    );
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
    await prefs.setString("baseurl", selectedCompany!.baseurl);
    await prefs.setString("adminurl", selectedCompany!.adminurl);
    await prefs.setString("license_expiry", selectedCompany!.licenseExpiry);


    print("✅ Selected Company: ${selectedCompany!.name}");
    print("🔑 Company Token: ${selectedCompany!.token}");
    print("🔑 Base URL: ${selectedCompany!.baseurl}");
    print("🔑 Admin URL: ${selectedCompany!.adminurl}");
    print("🔑 Expiry: ${selectedCompany!.licenseExpiry}");
    print("🔑 Company Name: ${selectedCompany!.name}");

    await loadTokens();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminDashboard()), // Navigate to dashboard
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA), // Light modern background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Select Company", style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                        child: Text(
                          company.name,
                          style: TextStyle(
                            color: company.isActive ? Colors.black : Colors.grey,
                            fontStyle: company.isActive ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      )).toList(),

                      (RegisteredCompany? newCompany) async {
                        if (newCompany == null) return;

                        // Check license expiry
                        final expiry = DateTime.tryParse(newCompany.licenseExpiry);
                        if (expiry != null && expiry.isBefore(DateTime.now())) {
                          showErrorSnackbar(
                            context,
                            'Your license against "${newCompany.name}" is expired. Please contact your service provider for renewal.',
                          );
                          return;
                        }

                        if (!newCompany.isActive) {
                          showErrorSnackbar(context, 'This company is inactive for your account.');
                          return;
                        }

                        setState(() {
                          selectedCompany = newCompany;
                        });

                        SharedPreferences prefs = await SharedPreferences.getInstance();

                        await prefs.setInt("company_id", newCompany.id);
                        await prefs.setString("company_name", newCompany.name);
                        await prefs.setString("access_token", newCompany.token); // updated key
                        await prefs.setString("access_token_expiry", newCompany.tokenExpiry);
                        await prefs.setString("baseurl", newCompany.baseurl);
                        await prefs.setString("adminurl", newCompany.adminurl);
                        await prefs.setString("license_expiry", newCompany.licenseExpiry);
                        await prefs.setBool("is_admin", newCompany.isAdmin);
                        await prefs.setBool("is_admin_from_api", newCompany.isAdmin);
                        await prefs.setString("user_name", newCompany.userName);
                        await prefs.setString("user_email", newCompany.userEmail);
                        await prefs.setInt("user_id", newCompany.userId);
                        await prefs.setString("user_permissions", jsonEncode(newCompany.permissions));
                        await prefs.setString("role_name", newCompany.roleName);

                        loadTokens(); // ✅ To refresh globally used values



                        fetchAndSaveCompanyData(newCompany.baseurl, newCompany.id, newCompany.token);

                      }

                  ),
                  /*SizedBox(height: 30),
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
                  )*/
                ],
              ),
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
