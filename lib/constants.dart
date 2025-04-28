import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String app_name = "Real Estate";

const MaterialAccentColor appbar_color = Colors.blueAccent;

const String company_name = 'Company';

const String authTokenBase = r'!1--3*%*%*%*9$api$8*%*%*%*5--0!X19fIUBBUyQlYXMxOTI4MzdfX18=KSgqL2FzZGFzZGlvQ0VEQUZf';

const String BASE_URL_config = "http://192.168.2.185:7750/api";

const String OAuth_URL = "http://192.168.2.185:4555";

const String client_id_constant = "262d59daa7ec95e07090cad7fcda24f8be197921";

const String client_password_constant = "internal@001";

// Serial & Company Tokens (Loaded Dynamically)
/*late String Company_Token;*/
late String Company_Token;
late String user_email;
late String user_name;
late int company_id;
late int serial_id;
late int user_id;
late String scope;
late bool is_admin;
late int flat_id;
late String flat_name;
late String flatsJson ;
late List<dynamic> flatsList;
late String baseurl,adminurl,license_expiry,building;

/// Load tokens from SharedPreferences
Future<void> loadTokens() async {


  SharedPreferences prefs = await SharedPreferences.getInstance();
  Company_Token = prefs.getString("company_token") ?? "";
/*
  Company_Token = 'eyJhbGciOiJIUzI1N iIsInR5cCI6IkpXVCJ9.eyJzY29wZSI6InVzZXIiLCJ0b2tlbiI6ImJjYzYxNjQ2MzhiZmZhNjVmMzVjNjAxYTMwZThmMWYyNTJlMzhjM2QiLCJpYXQiOjE3NDU1NzgwNzIsImV4cCI6MTc0NTY2NDQ3Mn0.ThnCK8kvEusX880BrFc2QPOP1231_XH-E8rArcQe_sU';
*/

  user_email = prefs.getString("user_email") ?? "";
  user_name = prefs.getString("user_name") ?? "";
  company_id = prefs.getInt("company_id") ?? 0;
  scope = prefs.getString("scope") ?? "";

  serial_id = prefs.getInt("serial_id") ?? 0;
  user_id = prefs.getInt("user_id") ?? 0;
  is_admin = prefs.getBool("is_admin") ?? false;
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
  print("Loaded User Email: $user_email");
  print("Loaded User Name: $user_name");
  print("Loaded BaseURL: $baseurl");
  print("Loaded AdminURL: $adminurl");
  print("Loaded license expiry: $license_expiry");
  print("Loaded Building: $building");
}

// Global Font Family
final TextTheme globalTextTheme = TextTheme(
  headline1: GoogleFonts.poppins(),
  headline2: GoogleFonts.poppins(),
  headline3: GoogleFonts.poppins(),
  headline4: GoogleFonts.poppins(),
  headline5: GoogleFonts.poppins(),
  headline6: GoogleFonts.poppins(),
  subtitle1: GoogleFonts.poppins(),
  subtitle2: GoogleFonts.poppins(),
  bodyText1: GoogleFonts.poppins(),
  bodyText2: GoogleFonts.poppins(),
  button: GoogleFonts.poppins(),
  caption: GoogleFonts.poppins(),
  overline: GoogleFonts.poppins(),
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


