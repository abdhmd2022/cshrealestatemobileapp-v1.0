import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';

class AnnouncementScreen extends StatefulWidget {
  @override
  _AnnouncementScreenState createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<Map<String, dynamic>> announcements = [];
  bool isLoading = true;
  final CarouselController _carouselController = CarouselController();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }


  Future<void> fetchAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userBuildingName = prefs.getString('building'); // replace with actual key

    if (userBuildingName == null || userBuildingName.isEmpty) {
      print('No building name found in SharedPreferences');
      setState(() => isLoading = false);
      return;
    }

    const int pageSize = 10;
    int currentPage = 1;
    bool hasMore = true;

    final DateTime now = DateTime.now();
    final DateTime oneMonthAgo = now.subtract(Duration(days: 30));

    List<Map<String, dynamic>> allValidAnnouncements = [];

    try {
      while (hasMore) {
        final response = await http.get(
          Uri.parse('$baseurl/master/Announcement?page=$currentPage&size=$pageSize'),
          headers: {
            'Authorization': 'Bearer $Company_Token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonBody = json.decode(response.body);
          final List<dynamic> pageData = jsonBody['data']['announcements'] ?? [];

          if (pageData.isEmpty) break;

          final filtered = pageData.where((a) {
            final expiryStr = a['expiry'];
            final buildingName = a['building']?['name'] ?? '';

            // Filter by building
            if (buildingName != userBuildingName) return false;

            // Include if no expiry
            if (expiryStr == null) return true;

            final expiryDate = DateTime.tryParse(expiryStr);
            if (expiryDate == null) return false;

            final endOfExpiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day, 23, 59, 59);
            return endOfExpiry.isAfter(oneMonthAgo);
          }).map((a) => a as Map<String, dynamic>).toList();

          allValidAnnouncements.addAll(filtered);

          final meta = jsonBody['meta'];
          final totalCount = meta?['totalCount'] ?? 0;
          final totalPages = (totalCount / pageSize).ceil();

          currentPage++;
          hasMore = currentPage <= totalPages;
        } else {
          throw Exception('Failed to load announcements');
        }
      }

      // Sort by latest
      allValidAnnouncements.sort((a, b) =>
          DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

      setState(() {
        announcements = allValidAnnouncements;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching announcements: $e");
      setState(() => isLoading = false);
    }
  }
  final PageController _pageController = PageController();
  int _currentPage = 0;


  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Announcements", style: GoogleFonts.poppins(fontWeight: FontWeight.normal,
            color:Colors.white)),
        backgroundColor: appbar_color.withOpacity(0.9),
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator.adaptive())
          : announcements.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.announcement_rounded,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              'No Announcements',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for the latest updates',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      )

          : Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          children: [


            // Horizontally swipeable cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                itemCount: announcements.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final a = announcements[index];
                  return _buildAnnouncementCard(context, a, index, isTablet);
                },
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(announcements.length, (index) {
                  bool isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 14 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? appbar_color : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),


      ),

    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Map<String, dynamic> a, int index, bool isTablet) {
    final subject = a['subject'] ?? 'No Subject';
    final desc = a['description'] ?? 'No description';

    final buildingName = a['building']?['name'] ?? 'Unknown Building';
    final emirate = a['building']?['area']?['state']?['name'] ?? '';
    final fullBuilding = emirate.isNotEmpty ? '$buildingName, $emirate' : buildingName;

    final expiryDate = a['expiry'] != null ? DateTime.parse(a['expiry']) : null;
    final attachments = a['attachments'] as List<dynamic>? ?? [];

    final postedOn = a['created_at'] != null
        ? DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.parse(a['created_at']))
        : 'N/A';

    final isExpired = expiryDate == null || expiryDate.isBefore(DateTime.now());

    final statusPill =Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isExpired ? Colors.red.shade100 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExpired ? Icons.cancel_outlined : Icons.verified_rounded,
              size: 16,
              color: isExpired ? Colors.red.shade700 : Colors.green.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              isExpired
                  ? 'Expired since ${DateFormat('dd-MMM-yyyy').format(expiryDate!)}'
                  : 'Valid until ${DateFormat('dd-MMM-yyyy').format(expiryDate!)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isExpired ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('📢 $subject',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [

                    Text(
                      '📅 Published on $postedOn',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.6, // Line height for better readability
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.justify, // Optional: gives a clean paragraph look
                ),

                const SizedBox(height: 20),

                if (attachments.isNotEmpty)
                  Container(
                    height: isTablet
                        ? MediaQuery.of(context).size.height * 0.45
                        : MediaQuery.of(context).size.height * 0.35,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.9),
                      itemCount: attachments.length,
                      itemBuilder: (context, imgIndex) {
                        final imagePath = attachments[imgIndex]['path'];
                        final fullImageUrl = '$baseurl/uploads/$imagePath';

                        print('fullImageUrl -> $fullImageUrl');



                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.black,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  children: [
                                    InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 1,
                                      maxScale: 5,
                                      child: Center(
                                        child: Image.network(
                                          fullImageUrl,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (_, child, loading) =>
                                          loading == null
                                              ? child
                                              : const Center(
                                              child:
                                              CircularProgressIndicator()),
                                          errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image,
                                              color: Colors.white, size: 60),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white, size: 30),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(fullImageUrl),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Building + Validity
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fullBuilding,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                statusPill,
              ],
            ),
          ),

          // Swipe hint
          if (!isTablet && index < announcements.length - 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.keyboard_arrow_right_rounded, size: 28, color: Colors.grey),
                    Text(
                      "Swipe → to view next announcement",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

        ],
      ),
    );
  }



}
