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

    print('company data -> $companiesJson');

    if (companiesJson != null) {
      List<dynamic> companiesList = jsonDecode(companiesJson);
      setState(() {
        companies =
            companiesList.map((data) => RegisteredCompany.fromJson(data))
                .toList();
      });
    }

    print("✅ Loaded ${companies.length} Companies");
  }

  Future<void> fetchAndSaveCompanyData(String baseurll, int company_id, String token) async {
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
      MaterialPageRoute(
          builder: (context) => AdminDashboard()), // Navigate to dashboard
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Select Company", style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        )),
        backgroundColor: appbar_color,
        elevation: 6,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: companies.length,
          itemBuilder: (context, index) => _buildCompanyCard(companies[index]),
        )

      ),
    );
  }

  Widget _buildExpiryBadge(DateTime? expiryDate) {
    if (expiryDate == null) {
      return _buildPill("No expiry", Colors.grey[300]!, Colors.black54);
    }

    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;

    if (daysLeft < 0) {
      return _buildPill("Expired on ${_formatDateToDDMMMYYYY(expiryDate)}", Colors.red[100]!, Colors.red[800]!);
    } else if (daysLeft <= 30) {
      return _buildPill("Expiring in $daysLeft days", Colors.orangeAccent.withOpacity(0.2), Colors.orangeAccent);
    } else {
      return _buildPill(
        "Expires on ${_formatDateToDDMMMYYYY(expiryDate)}",
        appbar_color.withOpacity(0.2),
        appbar_color,
      );
    }
  }

  Widget _buildPill(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCompanyCard(RegisteredCompany company) {
     final expiryDate = DateTime.tryParse(company.licenseExpiry);
    // final expiryDate = DateTime.tryParse("2025-07-07");
    final isSelected = selectedCompany?.id == company.id;

    return GestureDetector(
      onTap: () => _handleCompanySelection(company, expiryDate),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected ? appbar_color.withOpacity(0.3) : Colors.black12,
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: isSelected ? Border.all(color: appbar_color, width: 1.4) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: Company Name + Status + Arrow
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.apartment_rounded, color: Colors.indigo),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          company.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildStatusBadge(company.isActive),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row: User Info
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${company.userName} (${company.roleName})",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Row: Email
            Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.teal, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    company.userEmail,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

           /* Row(
              children: [
                const Icon(Icons.group_outlined, color: Colors.purple, size: 20),
                const SizedBox(width: 10),
                Text(
                  "Allowed users: ${company.allowedUsersPerCompany}", // <-- ✅ your new field
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),

            const SizedBox(height: 6),*/

            // Row: Expiry
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Colors.deepOrange, size: 20),
                const SizedBox(width: 10),
                _buildExpiryBadge(expiryDate)
              ],
            ),

            const SizedBox(height: 12),

            // Tap to continue (bottom-right)
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Tap to continue",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.touch_app_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? "Active" : "Inactive",
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.green[800] : Colors.red[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleCompanySelection(RegisteredCompany company, DateTime? expiryDate) async {
    final now = DateTime.now();
    final daysLeft = expiryDate?.difference(now).inDays ?? -999;

    if (daysLeft < 0) {
      showErrorSnackbar(
        context,
        'The license for "${company.name}" has expired.\nPlease contact your service provider.',
      );
      return; // ❌ Do not proceed
    }

    if (!company.isActive) {
      showErrorSnackbar(
        context,
        'This company is inactive for your account.',
      );
      return; // ❌ Do not proceed
    }

    setState(() => selectedCompany = company);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("company_id", company.id);
    await prefs.setString("company_name", company.name);
    await prefs.setString("access_token", company.token);
    await prefs.setString("access_token_expiry", company.tokenExpiry);
    await prefs.setString("baseurl", company.baseurl);
    await prefs.setString("adminurl", company.adminurl);
    await prefs.setString("license_expiry", company.licenseExpiry);
    await prefs.setBool("is_admin", is_admin);
    await prefs.setBool("is_admin_from_api", is_admin_from_api);
    await prefs.setString("user_name", company.userName);
    await prefs.setString("user_email", company.userEmail);
    await prefs.setInt("user_id", company.userId);

    await prefs.setString("user_permissions", jsonEncode(company.permissions));
    await prefs.setString("role_name", company.roleName);

    loadTokens();

    // ✅ Proceed to dashboard or fetch company data
    fetchAndSaveCompanyData(company.baseurl, company.id, company.token);
  }

  String _formatDateToDDMMMYYYY(DateTime? date) {
    if (date == null) return "N/A";
    return "${date.day.toString().padLeft(2, '0')}-${_monthName(
        date.month)}-${date.year}";
  }

  String _monthName(int month) {
    const monthNames = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return monthNames[month - 1];
  }

}


