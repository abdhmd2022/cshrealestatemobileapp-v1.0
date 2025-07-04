import 'package:cshrealestatemobile/FlatSelection.dart';
import 'package:cshrealestatemobile/Help.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'Login.dart';
import 'AdminDashboard.dart';
import 'TenantDashboard.dart';
import 'SerialSelect.dart';
import 'Settings.dart';
import 'package:google_fonts/google_fonts.dart';

class Sidebar extends StatefulWidget {
  final bool isDashEnable, isRolesVisible, isUserEnable, isRolesEnable, isUserVisible;

  Sidebar({
    Key? key,
    required this.isDashEnable,
    required this.isRolesVisible,
    required this.isRolesEnable,
    required this.isUserEnable,
    required this.isUserVisible,
  }) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String userName = "Loading...";
  String userEmail = "Loading...";

  String companyName = "Loading...";
 /* String serialNo = "Loading...";*/

  /*int serialID = 0;*/

  int companyID = 0;

  int userID = 0;

  bool is_admin = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Fetch User Data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print('loaded id ${prefs.getInt("company_id") ?? prefs.getInt("flat_id") ?? 0}');
    setState(() {
      userName = prefs.getString("user_name") ?? "Guest User";
      userEmail = prefs.getString("user_email") ?? "guest@example.com";

      companyName = prefs.getString("company_name") ??
          (prefs.getString("flat_name") != null && prefs.getString("building") != null
              ? "${prefs.getString("flat_name")} - ${prefs.getString("building")}"
              : prefs.getString("flat_name") ?? "Unknown");


      /*serialNo = prefs.getString("serial_no") ?? "Unknown";*/
      /*serialID = prefs.getInt("serial_id") ?? 0;*/
      companyID = prefs.getInt("flat_id") ?? prefs.getInt("company_id") ?? 0;
      userID = prefs.getInt("user_id") ?? 0;
      is_admin = prefs.getBool("is_admin") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Card(
              color: appbar_color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: EdgeInsets.only(top: 70, left: 10, right: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar/Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.9)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: appbar_color,
                      ),
                    ),

                    SizedBox(width: 15),

                    // Info block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user_name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            user_email,
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            role_name,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                          ),
                          SizedBox(height: 2),
                          Text(
                            companyName,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),


            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),


            // ✅ Sidebar Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if(is_admin)
                    _buildDrawerItem(Icons.dashboard, "Dashboard", widget.isDashEnable, () {
                      Navigator.of(context).pop();
                    _navigateTo(context, AdminDashboard());
                  }),
                  if(!is_admin)
                    _buildDrawerItem(Icons.dashboard, "Dashboard", true, () {
                      Navigator.of(context).pop();
                    _navigateTo(context, TenantDashboard());
                  }),
                  /*if(is_admin)
                    _buildDrawerItem(Icons.dashboard, "Landlord Dashboard", true, () {
                    _navigateTo(context, LandlordDashboardScreen());
                  }),*/
                  if(is_admin)
                    _buildDrawerItem(Icons.business, "Companies", true, () {
                      Navigator.of(context).pop();
                    _navigateTo(context, CompanySelection());
                  }),
                  if(!is_admin)
                    _buildDrawerItem(Icons.business, "Unit(s)", true, () {
                      Navigator.of(context).pop();
                      _navigateTo(context, FlatSelection());
                    }),
                  if(is_admin)
                    _buildDrawerItem(Icons.settings, "Settings", true, () {
                      Navigator.of(context).pop();
                      _navigateTopush(context, SettingsScreen());
                  }),
                  Divider(),
                  _buildDrawerItem(Icons.contact_support, "Help", true, () {
                    Navigator.of(context).pop();
                    _navigateTopush(context, HelpSupportScreen());
                   // _showHelpDialog(context);
                  }),
                  _buildDrawerItem(Icons.logout, "Logout", true, () {
                    _showLogoutDialog(context);
                  }),
                ],
              ),
            ),

            // ✅ Sidebar Footer - Version Number
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  "v1.0",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Reusable Drawer Menu Item
  Widget _buildDrawerItem(IconData icon, String title, bool enabled, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: enabled ? Colors.black : Colors.grey),
      title: Text(title, style: GoogleFonts.poppins(color: enabled ? Colors.black : Colors.grey)),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }

  /// ✅ Function to Navigate to Different Screens
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _navigateTopush(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  /// ✅ Logout Confirmation Dialog
  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Logout Confirmation"),
          content: Text("Do you really want to logout?"),
          actions: [
            TextButton(
              child: Text("No", style: GoogleFonts.poppins(color: appbar_color)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Yes", style: GoogleFonts.poppins(color: appbar_color)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login(title: app_name)));
              },
            ),
          ],
        );
      },
    );
  }

  /// ✅ Placeholder for Help Dialog
  void _showHelpDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Help section coming soon!")),
    );
  }
}
