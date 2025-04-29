import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AdminDashboard.dart';
import 'Login.dart';
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

class SalesProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        leading: GestureDetector(
            onTap: ()
            {

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminDashboard()),
              );
            },
            child:
            const Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),

        title:  Text('Profile',
        style: GoogleFonts.poppins(

          color: Colors.white
        ),),
        centerTitle: true,
        backgroundColor: appbar_color.withOpacity(0.9),
        
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.only(top: 20.0, bottom: 20, left: 40, right: 40),
              margin: const EdgeInsets.only(top: 40.0),
              decoration:  BoxDecoration(
                color: appbar_color.withOpacity(0.7),
                
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      'https://mobile.chaturvedigroup.com/profile_logo/sreeja-7kotegzLt7w-unsplash.jpg',
                    ),
                  ),
                  const SizedBox(height: 10),
                   Text(
                    user_name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,

                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   SizedBox(height: 5),
                   Text(
                    user_email,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                   Text(
                    '+971 500000000',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Section
            /*Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Clients', '45', Colors.teal),
                  _buildStatCard('Sales Achieved', '\AED 20K', Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 20),*/

            // User Details
            /*Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Role', 'Sales Executive'),
                      *//*const SizedBox(height: 10),
                      _buildDetailRow('Team', 'Sales'),*//*
                      *//*const SizedBox(height: 10),
                      _buildDetailRow('Target', '\AED 50K/month'),*//*
                    ],
                  ),
                ),
              ),
            ),*/
            const SizedBox(height: 20),

            // Profile Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.lock, color: Colors.teal),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Handle Change Password
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Logout'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style:  GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.normal
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:  GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style:  GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black54,


          ),
        ),
      ],
    );
  }
}
