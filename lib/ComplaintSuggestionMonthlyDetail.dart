import 'dart:ui';
import 'package:cshrealestatemobile/ComplaintReport.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class MonthlyDetailScreen extends StatelessWidget {
  final String monthKey; // e.g. "2025-04"
  final List<Map<String, dynamic>> entries;

  MonthlyDetailScreen({required this.monthKey, required this.entries});

  Map<String, List<Map<String, dynamic>>> groupByDay(List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      final createdAt = DateTime.tryParse(item['created_at'] ?? "") ?? DateTime.now();
      final key = DateFormat('dd-MMM').format(createdAt);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(item);
    }

    // Sort each group (latest feedback first)
    for (var list in grouped.values) {
      list.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    }

    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          final aDate = DateFormat('dd-MMM').parse(a.key);
          final bDate = DateFormat('dd-MMM').parse(b.key);
          return bDate.compareTo(aDate); // Latest date first
        }),
    );
  }

  String getInitials(String name) {
    final parts = name.trim().split(" ");
    return parts.length > 1
        ? "${parts[0][0]}${parts[1][0]}"
        : name.isNotEmpty ? name[0] : "?";
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupByDay(entries);
    final monthLabel = DateFormat('MMMM, yyyy').format(DateFormat('yyyy-MM').parse(monthKey));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ComplaintSuggestionReportScreen()),
            );
          },
        ),
        title: Text(monthLabel, style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((group) {
          final day = group.key;
          final feedbacks = group.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 6),
                    Text(
                      day,
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              ...feedbacks.map((entry) {
                final type = entry['type'] ?? 'Unknown';
                final desc = entry['description'] ?? 'No description';
                final tenant = entry['tenant']?['name'] ?? 'Unknown';
                final createdAt = DateTime.tryParse(entry['created_at'] ?? '') ?? DateTime.now();
                final dateLabel = DateFormat('dd-MMM-yyyy • hh:mm a').format(createdAt);

                final isComplaint = type == 'Complaint';
                final bgColor = isComplaint ? Colors.red : Colors.teal.withOpacity(0.8);
                final icon = isComplaint ? Icons.report_problem : Icons.lightbulb;

                return Container(
                  margin: EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: bgColor.withOpacity(0.25),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: bgColor,
                        radius: 22,
                        child: Text(
                          getInitials(tenant).toUpperCase(),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(desc, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                    subtitle: Text(
                      "$tenant \n$dateLabel",
                      style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[700]),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            type,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              SizedBox(height: 24),
            ],
          );
        }).toList(),
      )

    );
  }
}
