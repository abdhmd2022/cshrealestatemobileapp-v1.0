import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'Login.dart';
import 'SalesDashboard.dart';
import 'TenantDashboard.dart';
import 'LandlordDashboard.dart';
import 'SerialSelect.dart';
import 'Settings.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Fetch User Data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "Guest User";
      userEmail = prefs.getString("user_email") ?? "guest@example.com";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ✅ Drawer Header - User Profile Section
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.only(top: 90,left: 0,right: 20,bottom: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [appbar_color.shade200, appbar_color.shade700],
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
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appbar_color),
                    ),
                    SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(fontSize: 14, color: appbar_color),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ✅ Sidebar Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.dashboard, "Sales", widget.isDashEnable, () {
                  _navigateTo(context, SalesDashboard());
                }),
                _buildDrawerItem(Icons.dashboard, "Tenant", true, () {
                  _navigateTo(context, TenantDashboardScreen());
                }),
                _buildDrawerItem(Icons.dashboard, "Landlord", true, () {
                  _navigateTo(context, LandlordDashboardScreen());
                }),
                _buildDrawerItem(Icons.business, "Companies", true, () {
                  _navigateTo(context, SerialNoSelection());
                }),
                _buildDrawerItem(Icons.settings, "Settings", true, () {
                  _navigateTo(context, SettingsScreen());
                }),
                Divider(),
                _buildDrawerItem(Icons.contact_support, "Help", true, () {
                  _showHelpDialog(context);
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
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Reusable Drawer Menu Item
  Widget _buildDrawerItem(IconData icon, String title, bool enabled, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: enabled ? Colors.black : Colors.grey),
      title: Text(title, style: TextStyle(color: enabled ? Colors.black : Colors.grey)),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }

  /// ✅ Function to Navigate to Different Screens
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
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
              child: Text("No", style: TextStyle(color: appbar_color)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Yes", style: TextStyle(color: appbar_color)),
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
