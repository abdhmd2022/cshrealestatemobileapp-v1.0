import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AnalyticsReport.dart';
import 'constants.dart';
import 'MonthlyDetailScreen.dart';

class ComplaintSuggestionReportScreen extends StatefulWidget {
  @override
  State<ComplaintSuggestionReportScreen> createState() =>
      _ComplaintSuggestionReportScreenState();
}

class _ComplaintSuggestionReportScreenState extends State<ComplaintSuggestionReportScreen> {
  List<int> years = [];
  late int selectedYear;
  List<Map<String, dynamic>> allData = [];
  Map<String, List<Map<String, dynamic>>> groupedByMonth = {};
  Map<String, String> complaintTrendMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMonthlyStats();
  }

  Future<void> fetchMonthlyStats() async {
    final url = Uri.parse("$baseurl/tenant/complaint");
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $Company_Token",
      "Content-Type": "application/json",
    });

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final List<Map<String, dynamic>> complaints =
      List<Map<String, dynamic>>.from(responseData['data']['complaints'] ?? []);

      allData = complaints;
      groupedByMonth.clear();
      Set<int> uniqueYears = {};

      for (var entry in allData) {
        final createdAt = DateTime.parse(entry['created_at']);
        final key = DateFormat('yyyy-MM').format(createdAt);
        final year = createdAt.year;
        uniqueYears.add(year);
        groupedByMonth.putIfAbsent(key, () => []).add(entry);
      }

      // Sort months and calculate "vs prev"
      final sortedKeys = groupedByMonth.keys.toList()
        ..sort((a, b) => DateFormat('yyyy-MM').parse(a).compareTo(DateFormat('yyyy-MM').parse(b)));

      complaintTrendMap.clear();
      for (int i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        final current = groupedByMonth[key]!;
        final currentComplaints = current.where((e) => e['type'] == 'Complaint').length;

        int prevComplaints = 0;
        if (i > 0) {
          final prevKey = sortedKeys[i - 1];
          final prev = groupedByMonth[prevKey] ?? [];
          prevComplaints = prev.where((e) => e['type'] == 'Complaint').length;
        }

        final diff = currentComplaints - prevComplaints;
        if (diff > 0) {
          complaintTrendMap[key] = "↑ $diff";
        } else if (diff < 0) {
          complaintTrendMap[key] = "↓ ${diff.abs()}";
        } else {
          complaintTrendMap[key] = "No Change";
        }
      }

      years = uniqueYears.toList()..sort((a, b) => b.compareTo(a));
      selectedYear = years.isNotEmpty ? years.first : DateTime.now().year;

      setState(() => isLoading = false);
    } else {
      throw Exception("Failed to fetch complaints");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMonths = groupedByMonth.entries.where((e) {
      final year = int.parse(e.key.split("-")[0]);
      return year == selectedYear;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,

              MaterialPageRoute(builder: (_) => LandlordDashboardScreen()),
            );
          },
        ),
        title: Text("Complaints/Suggestions", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: appbar_color))
          : Column(
        children: [
          SizedBox(height: 10),
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12),
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected = year == selectedYear;
                return GestureDetector(
                  onTap: () => setState(() => selectedYear = year),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? appbar_color : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        year.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: filteredMonths.isEmpty
                ? Center(child: Text("No data for $selectedYear"))
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: filteredMonths.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final key = filteredMonths[index].key;
                  final entries = filteredMonths[index].value;
                  final DateTime date = DateFormat('yyyy-MM').parse(key);
                  final monthName = DateFormat('MMMM').format(date);
                  final year = date.year;

                  final complaintCount = entries.where((e) => e['type'] == 'Complaint').length;
                  final suggestionCount = entries.where((e) => e['type'] == 'Suggestion').length;
                  final trendText = complaintTrendMap[key] ?? "";

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MonthlyDetailScreen(monthKey: key, entries: entries),
                        ),
                      );

                    },
                    child: TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 150),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),

                        ),
                        child: Material(
                          elevation: 5, // 💥 maximum natural elevation
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                                ),
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("$monthName, $year",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.report_problem_outlined, size: 18, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text("Complaints: $complaintCount",
                                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline, size: 18, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text("Suggestions: $suggestionCount",
                                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                    /*Spacer(),
                                    Text(
                                      trendText,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: trendText.contains("↑")
                                            ? Colors.red
                                            : trendText.contains("↓")
                                            ? Colors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),*/
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );


                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
