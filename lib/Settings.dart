import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AmenitiesReport.dart';
import 'LeadStatusReport.dart';
import 'LeadTypeReport.dart';
import 'MaintenanceStatusReport.dart';
import 'MaintenanceTypeMastersReport.dart';
import 'ActivitySourceReport.dart';
import 'Sidebar.dart';
import 'constants.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController minController = TextEditingController();
  TextEditingController maxController = TextEditingController();
  double range_min = 10000;
  double range_max = 100000;

  @override
  void initState() {
    super.initState();
    _loadRangeValues();
  }

  void _loadRangeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      range_min = prefs.getDouble('range_min') ?? 10000;
      range_max = prefs.getDouble('range_max') ?? 100000;
      minController.text = range_min.toString();
      maxController.text = range_max.toString();
    });
  }

  void _saveRangeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('range_min', double.parse(minController.text));
    prefs.setDouble('range_max', double.parse(maxController.text));
  }

  void _showPriceRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set Price Range', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceField(minController, 'Minimum Price'),
            SizedBox(height: 12),
            _buildPriceField(maxController, 'Maximum Price'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: appbar_color)),
          ),
          ElevatedButton(
            onPressed: () {
              _saveRangeValues();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appbar_color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildPriceField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: appbar_color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: appbar_color, size: 22),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade500),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Settings",
          style: GoogleFonts.poppins(
              color: Colors.white
          ),),
        backgroundColor: appbar_color.withOpacity(0.9),
        leading: GestureDetector(
          onTap: ()
          {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),
      ),
      drawer: Sidebar(
        isDashEnable: true,
        isRolesVisible: true,
        isRolesEnable: true,
        isUserEnable: true,
        isUserVisible: true,
      ),
      body: ListView(
        padding: EdgeInsets.only(top: 12),
        children: [
          if (hasPermissionInCategory('Lead Status'))
            _buildGlassCard(
              icon: Icons.leaderboard,
              title: 'Lead Status',
              subtitle: 'Manage lead/follow-up status masters for the app',
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LeadStatusReport())),
            ),
          if (hasPermission('canCreateAmenities') || hasPermission('canViewAmenities') || hasPermission('canUpdateAmenities') || hasPermission('canDeleteAmenities'))
            _buildGlassCard(
              icon: Icons.room_preferences,
              title: 'Amenities',
              subtitle: 'Manage amenities masters for the app',
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AmentiesReport())),
            ),
          if (hasPermission('canSetPriceRangeForSalesInquiry'))
            _buildGlassCard(
              icon: Icons.price_change,
              title: 'Price Range',
              subtitle: 'Set price range for sales enquiry',
              onTap: _showPriceRangeDialog,
            ),
          if (hasPermissionInCategory('Lead Follow-up Type'))
            _buildGlassCard(
              icon: Icons.follow_the_signs,
              title: 'Lead Follow-up Type',
              subtitle: 'Manage lead follow-up type masters for the app',
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LeadFollowupTypeReport())),
            ),
          if (hasPermissionInCategory('Activity Source'))
            _buildGlassCard(
              icon: Icons.source,
              title: 'Activity Source',
              subtitle: 'Manage activity source masters for the app',
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ActivitySourceReport())),
            ),
          if (hasPermissionInCategory('Maintenance Types'))
            _buildGlassCard(
              icon: Icons.settings_suggest,
              title: 'Maintenance Types',
              subtitle: 'Manage maintenance types masters for the app',
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MaintenanceTypeMastersReport())),
            ),
          if (hasPermissionInCategory('Maintenance Status'))
            _buildGlassCard(
              icon: Icons.assignment_turned_in,
              title: 'Maintenance Status',
              subtitle: 'Manage maintenance status masters for the app',
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MaintenanceStatusReport())),
            ),
        ],
      ),
    );
  }
}
