import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AnalyticsReport.dart';
import 'constants.dart';
import 'ComplaintSuggestionMonthlyDetail.dart';

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
    setState(() => isLoading = true);

    int currentPage = 1;
    List<Map<String, dynamic>> allFetchedData = [];

    while (true) {
      final url = Uri.parse("$baseurl/tenant/complaint?page=$currentPage");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $Company_Token",
        "Content-Type": "application/json",
      });

      if (response.statusCode != 200) {
        print("Failed at page $currentPage");
        break;
      }

      final responseData = json.decode(response.body);
      final List<Map<String, dynamic>> pageData =
      List<Map<String, dynamic>>.from(responseData['data']['complaints'] ?? []);

      if (pageData.isEmpty) break; // 🔁 Stop if no more data

      allFetchedData.addAll(pageData);
      currentPage++;
    }

    // 👉 Process fetched data
    allData = allFetchedData;
    groupedByMonth.clear();
    Set<int> uniqueYears = {};

    for (var entry in allData) {
      final createdAt = DateTime.parse(entry['created_at']);
      final key = DateFormat('yyyy-MM').format(createdAt);
      final year = createdAt.year;
      uniqueYears.add(year);
      groupedByMonth.putIfAbsent(key, () => []).add(entry);
    }

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
      complaintTrendMap[key] = diff > 0
          ? "↑ $diff"
          : diff < 0
          ? "↓ ${diff.abs()}"
          : "No Change";
    }

    years = uniqueYears.toList()..sort((a, b) => b.compareTo(a));
    selectedYear = years.isNotEmpty ? years.first : DateTime.now().year;

    setState(() => isLoading = false);
  }

  Widget buildLineChart() {
    final filtered = groupedByMonth.entries.where((e) => e.key.startsWith("$selectedYear-")).toList();
    final sortedKeys = filtered.map((e) => e.key).toList()
      ..sort((a, b) => a.compareTo(b));

    List<FlSpot> complaintSpots = [];
    List<FlSpot> suggestionSpots = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      final entries = groupedByMonth[sortedKeys[i]] ?? [];
      final complaints = entries.where((e) => e['type'] == 'Complaint').length.toDouble();
      final suggestions = entries.where((e) => e['type'] == 'Suggestion').length.toDouble();
      complaintSpots.add(FlSpot(i.toDouble(), complaints));
      suggestionSpots.add(FlSpot(i.toDouble(), suggestions));
    }

    return Card(
        elevation: 10, // 🔥 Clean elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        color: Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
child: Container(

  color: Colors.white,
  height: 270,
  padding: const EdgeInsets.only(top:30, right: 16,left: 16,bottom:26),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 180, // ✅ give it a specific height

        child: LineChart(
          LineChartData(
            minY: 0,
            lineTouchData: LineTouchData(enabled: true),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                spots: complaintSpots,
                barWidth: 2,
                gradient: LinearGradient(colors: [Colors.redAccent, Colors.redAccent]),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.withOpacity(0.3),
                      Colors.redAccent.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.redAccent,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
              LineChartBarData(
                isCurved: true,
                spots: suggestionSpots,
                barWidth: 2,
                gradient: LinearGradient(colors: [Colors.teal.withOpacity(0.8), Colors.teal.withOpacity(0.7)]),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal.withOpacity(0.3),
                      Colors.teal.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.teal.withOpacity(0.8),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 32,
                  getTitlesWidget: (value, _) {
                    if (value % 1 != 0) return SizedBox.shrink();
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index < 0 || index >= sortedKeys.length) return SizedBox.shrink();
                    final month = DateFormat('MMM').format(DateTime.parse("${sortedKeys[index]}-01"));
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 6,
                      child: Text(
                        month,
                        style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey.shade100,
                strokeWidth: 1,
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendDot(color: Colors.redAccent, label: 'Complaints'),
          SizedBox(width: 16),
          _buildLegendDot(color: Colors.teal.withOpacity(0.8), label: 'Suggestions'),
        ],
      ),
    ],
  ),
),
        ),
      );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMonths = groupedByMonth.entries.where((e) {
      final year = int.parse(e.key.split("-")[0]);
      return year == selectedYear;
    }).toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // 👈 Sort by latest month first

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
          ? Center(
        child: Platform.isIOS
            ? CupertinoActivityIndicator(
          radius: 15.0, // Adjust size if needed
        )
            : CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(appbar_color), // Change color here
          strokeWidth: 4.0, // Adjust thickness if needed
        ),
      )
          : SingleChildScrollView(

        child: Column(
          children: [
            SizedBox(height: 5),

            Container(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final year = years[index];
                  final isSelected = year == selectedYear;
                  return GestureDetector(
                    onTap: () => setState(() => selectedYear = year),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                        ],
                        border: Border.all(
                          color: isSelected ? appbar_color.withOpacity(0.6) : Colors.grey.shade300,
                          width: isSelected ? 1.0 : 1.0,
                        ),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? appbar_color : Colors.black87,
                        ),
                        child: Text(year.toString()),
                      ),
                    ),
                  );
                },
              ),
            ),

            buildLineChart(),

            SizedBox(height: 12),

            filteredMonths.isEmpty
                ? Center(child: Text("No data for $selectedYear"))
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(), // prevent nested scroll
                shrinkWrap: true, // ✅ prevent overflow in landscape
                itemCount: filteredMonths.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250, // max width per card
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6,
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
                      duration: Duration(milliseconds: 250),
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
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text("$monthName, $year",
                                          style: GoogleFonts.poppins(
                                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),

                                    ),
                                    SizedBox(height: 10),

                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Icon(Icons.report_problem_outlined, size: 18, color: Colors.red),
                                          SizedBox(width: 4),
                                          Text("Complaints: $complaintCount",
                                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                                        ],
                                      ),
                                    ),

                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb_outline, size: 18, color: Colors.teal.withOpacity(0.8)),
                                          SizedBox(width: 4),
                                          Text("Suggestions: $suggestionCount",
                                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                                        ],
                                      ),
                                    )

                                    /*Spacer(),
                                    Text(
                                      trendText,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: trendText.contains("↑")
                                            ? Colors.red
                                            : trendText.contains("↓")
                                            ? Colors.teal.withOpacity(0.8)
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
          ],
        ),
      ),
    );
  }
}
