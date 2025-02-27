import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String app_name = "Real Estate";

const MaterialAccentColor appbar_color = Colors.blueAccent;

const String company_name = 'Company';

const String authTokenBase = r'!1--3*%*%*%*9$api$8*%*%*%*5--0!X19fIUBBUyQlYXMxOTI4MzdfX18=KSgqL2FzZGFzZGlvQ0VEQUZf';

const String BASE_URL_config = "http://192.168.2.185:7750/api";

// Serial & Company Tokens (Loaded Dynamically)
late String Company_Token;
late String user_email;
late String user_name;
late int company_id;
late int serial_id;
late int user_id;
late bool is_admin;

/// Load tokens from SharedPreferences
Future<void> loadTokens() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  /*Company_Token = prefs.getString("Company_Token") ?? "";*/
  Company_Token = prefs.getString("company_token") ?? "";
  user_email = prefs.getString("user_email") ?? "";
  user_name = prefs.getString("user_name") ?? "";
  company_id = prefs.getInt("company_id") ?? 0;
  serial_id = prefs.getInt("serial_id") ?? 0;
  user_id = prefs.getInt("user_id") ?? 0;
  is_admin = prefs.getBool("is_admin") ?? false;

  print("Loaded Company Token: $Company_Token");
  print("Loaded Company ID: $company_id");
  print("Loaded User ID: $user_id");
  print("Loading Admin Status: $is_admin");
  print("Loaded User Email: $user_email");
  print("Loaded User Name: $user_name");
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
