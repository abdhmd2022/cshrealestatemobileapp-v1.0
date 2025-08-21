import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String app_name = "Fincore RMS";

const MaterialAccentColor appbar_color = Colors.blueAccent;

 late String company_name = 'Company';

const String authTokenBase = r'!1--3*%*%*%*9$api$8*%*%*%*5--0!X19fIUBBUyQlYXMxOTI4MzdfX18=KSgqL2FzZGFzZGlvQ0VEQUZf';

// const String BASE_URL_config = "http://192.168.2.185:6551/api";

//const String OAuth_URL = "http://192.168.2.185:4555";

const String OAuth_URL = "http://realestate.chaturvedigroup.com/oauth";

const String client_id_constant = "3beca39997dc69a761afe408987e46589cb75a5e";

const String client_password_constant = "internal@001";

// Path constant
const String dirhamIconPath = 'assets/dirham.png';

// Widget constant (for reuse everywhere)
final Widget dirhamPrefix = Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0),
  child: Image.asset(
    dirhamIconPath,
    width: 12,
    height: 12,
    fit: BoxFit.contain,
  ),
);

// Serial & Company Tokens (Loaded Dynamically)
/*late String Company_Token;*/
late String Company_Token;
late String user_email;
late String user_name;
late int company_id;
late int serial_id;
late int user_id;
late String scope;
late bool is_admin,is_landlord;
late int flat_id;
late String flat_name;
late String flatsJson ;
late List<dynamic> flatsList;
late String baseurl,adminurl,license_expiry,building;
late bool is_admin_from_api;
late List<Map<String, dynamic>> user_permissions;
String access_token_expiry = "";
String role_name = "";
bool is_active = false;

late String mailing_name,address,pincode,state,country,trn,phone,mobile,email,website,logo_path,whatsapp_no;

/// Load tokens from SharedPreferences
/// new function

Future<void> loadTokens() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  mailing_name =  prefs.getString('mailing_name') ?? "";
  address= prefs.getString('address') ?? "";
  pincode =  prefs.getString('pincode')?? "";
  state =  prefs.getString('state') ?? "";
  country =  prefs.getString('country') ?? "";
  trn =  prefs.getString('trn') ?? "";
  phone = prefs.getString('phone') ?? "";
  mobile =  prefs.getString('mobile') ?? "";
  email =  prefs.getString('email') ?? "";
  website =  prefs.getString('website') ?? "";
  logo_path =  prefs.getString('logo_path') ?? "";
  whatsapp_no =  prefs.getString('whatsapp_no')?? "";

  company_name =  prefs.getString('company_name')?? "";

  Company_Token = prefs.getString("access_token") ?? "";
  access_token_expiry = prefs.getString("access_token_expiry") ?? "";

  user_email = prefs.getString("user_email") ?? "";
  user_name = prefs.getString("user_name") ?? "";
  company_id = prefs.getInt("company_id") ?? 0;
  scope = prefs.getString("scope") ?? "";

  serial_id = prefs.getInt("serial_id") ?? 0;
  user_id = prefs.getInt("user_id") ?? 0;

  role_name = prefs.getString("role_name") ?? "";


  is_admin = prefs.getBool("is_admin") ?? false;
  is_admin_from_api = prefs.getBool("is_admin_from_api") ?? false;
  is_landlord = prefs.getBool('is_landlord') ?? false;

  is_active = prefs.getBool("is_active") ?? true;

  flat_id = prefs.getInt("flat_id") ?? 0;
  flat_name = prefs.getString("flat_name") ?? '';
  flatsJson = prefs.getString("flats_list") ?? '';
  baseurl = prefs.getString("baseurl") ?? '';
  adminurl = prefs.getString("adminurl") ?? '';
  license_expiry = prefs.getString("license_expiry") ?? '';
  building = prefs.getString("building") ?? '';

  print("🛡️ is_admin (legacy): $is_admin");
  print("🛡️ is_admin_from_api: $is_admin_from_api");

  // ✅ Load permissions
  String permissionsJson = prefs.getString("user_permissions") ?? "[]";

// Defensive fallback for empty or malformed strings
  if (permissionsJson.trim().isEmpty) {
    permissionsJson = "[]";
  }

  user_permissions = List<Map<String, dynamic>>.from(jsonDecode(permissionsJson));

  if (!is_admin) {
    flatsList = jsonDecode(flatsJson);
  }

  print("🔑 Loaded Access Token: $Company_Token");
  print("🕒 Access Token Expiry: $access_token_expiry");

  print("🏢 Company ID: $company_id");
  print("👤 User ID: $user_id");
  print("👤 User Email: $user_email");
  print("👤 User Name: $user_name");

  print("🛡️ is_admin (legacy): $is_admin");
  print("🛡️ is_admin_from_api: $is_admin_from_api");
  print("🛡️ is_active: $is_active");

  print("📍 Flat ID: $flat_id");
  print("🏠 Flat Name: $flat_name");
  print("🌐 BaseURL: $baseurl");
  print("🔧 AdminURL: $adminurl");
  print("📅 License Expiry: $license_expiry");
  print("🏗️ Building: $building");

  print("🧾 Loaded Permissions: ${user_permissions.length}");
  print("🧾 Role Name: $role_name");

}

bool hasPermission(String permissionName) {
  return user_permissions.any((perm) => perm['name'] == permissionName);
}

bool hasPermissionInCategory(String categoryName) {
  return user_permissions.any(
        (perm) => (perm['category']?.toString().toLowerCase() == categoryName.toLowerCase()),
  );
}

//old function
/*Future<void> loadTokens() async {


  SharedPreferences prefs = await SharedPreferences.getInstance();
  Company_Token = prefs.getString("company_token") ?? "";


  user_email = prefs.getString("user_email") ?? "";
  user_name = prefs.getString("user_name") ?? "";
  company_id = prefs.getInt("company_id") ?? 0;
  scope = prefs.getString("scope") ?? "";

  serial_id = prefs.getInt("serial_id") ?? 0;
  user_id = prefs.getInt("user_id") ?? 0;
  is_admin = prefs.getBool("is_admin") ?? false;
  is_landlord= prefs.getBool('is_landlord')?? false;

  is_admin_from_api = prefs.getBool("is_admin_from_api") ?? false;

  flat_id = prefs.getInt("flat_id") ?? 0;
  flat_name = prefs.getString("flat_name") ?? '';
  flatsJson = prefs.getString("flats_list") ?? '';
  baseurl = prefs.getString("baseurl") ?? '';
  adminurl = prefs.getString("adminurl") ?? '';
  license_expiry = prefs.getString("license_expiry") ?? '';
  building = prefs.getString("building") ?? '';

  if(!is_admin)
  {
      flatsList = jsonDecode(flatsJson);
  }

  print("Loaded Token: $Company_Token");
  print("Selected Flat ID: $flat_id");

  print("Loaded Company ID: $company_id");
  print("Loaded User ID: $user_id");
  print("Loading Admin Status: $is_admin");
  print("Loading Admin from API Status: $is_admin_from_api");
  print("Loaded User Email: $user_email");
  print("Loaded User Name: $user_name");
  print("Loaded BaseURL: $baseurl");
  print("Loaded AdminURL: $adminurl");
  print("Loaded license expiry: $license_expiry");
  print("Loaded Building: $building");
}*/

// Global Font Family
final TextTheme globalTextTheme = TextTheme(
  displayLarge: GoogleFonts.poppins(),
  displayMedium: GoogleFonts.poppins(),
  displaySmall: GoogleFonts.poppins(),
  headlineMedium: GoogleFonts.poppins(),
  headlineSmall: GoogleFonts.poppins(),
  titleLarge: GoogleFonts.poppins(),
  titleMedium: GoogleFonts.poppins(),
  titleSmall: GoogleFonts.poppins(),
  bodyLarge: GoogleFonts.poppins(),
  bodyMedium: GoogleFonts.poppins(),
  labelLarge: GoogleFonts.poppins(),
  bodySmall: GoogleFonts.poppins(),
  labelSmall: GoogleFonts.poppins(),
);

String formatDate(String dateString) {
  DateTime date = DateTime.parse(dateString);
  return DateFormat('dd-MMM-yyyy').format(date);
}

void showResponseSnackbar(BuildContext context, Map<String, dynamic> responseJson) {
  final bool isSuccess = responseJson['success'] == true;
  final String message = responseJson['message'] ?? 'Unexpected response';

  final Color backgroundColor = isSuccess ? Colors.green : Colors.red;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}


