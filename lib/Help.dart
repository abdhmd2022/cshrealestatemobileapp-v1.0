import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _launchPhone(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchWhatsApp(String phone) async {
    final Uri url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchEmail(String email) async {
    final Uri url = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=Support Request&body=Please describe your issue...'
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Help & Support',
            style: GoogleFonts.poppins(
                color: Colors.white
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
          _buildSupportCard(
          icon: Icons.phone_in_talk_rounded,
          title: 'Call Us',
          subtitle: '+971-123-456789',
          color: Colors.green,
          onTap: () => _launchPhone('+971123456789'),
        ),
        _buildSupportCard(
          icon: FontAwesomeIcons.whatsapp,
          title: 'Chat on WhatsApp',
          subtitle: '+971-123-456789',
          color: Colors.teal,
          onTap: () => _launchWhatsApp('971123456789'),
        ),
        _buildSupportCard(
          icon: Icons.email_outlined,
          title: 'Email Us',
          subtitle: 'support@realestateapp.com',
          color: Colors.deepPurple,
          onTap: () => _launchEmail('support@realestateapp.com'),
        ),
        const SizedBox(height: 40),
        Icon(Icons.support_agent_rounded, size: 80, color: appbar_color),
        const SizedBox(height: 20),
        Text(
          "'We're here to help you!'",
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: appbar_color,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10),
      Text(
        'Feel free to reach out to us through any of the options above. Our support team will get back to you as soon as possible.',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
        textAlign: TextAlign.center,
      )
      ],
    ),
    ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}