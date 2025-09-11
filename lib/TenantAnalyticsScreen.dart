import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class TenantAnalyticsScreen extends StatelessWidget {
  final int cleared;
  final int pending;
  final Map<String, double> invoices;
  final Map<String, int> buildingFlatCount;
  final bool isLandlord;
  final List<Map<String, dynamic>> contracts;
  final int? loadingTileIndex;
  final Future<void> Function(int flatId, String category) onTapFetchFlat;

  const TenantAnalyticsScreen({
    Key? key,
    required this.cleared,
    required this.pending,
    required this.invoices,
    required this.buildingFlatCount,
    required this.isLandlord,
    required this.contracts,
    required this.loadingTileIndex,
    required this.onTapFetchFlat,
  }) : super(key: key);
  void _showUnitsPopup(BuildContext context, String buildingName) {
    final units = contracts
        .expand((contract) => contract['flats'] as List)
        .where((flat) => flat['building']?['name'] == buildingName)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.orange,
                              child: Text(
                                buildingName.isNotEmpty
                                    ? buildingName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              buildingName,
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${units.length.toString()} Unit(s)',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: units.length,
                        itemBuilder: (context, i) => _buildUnitTile(
                          context: context,
                          flat: units[i],
                          badgeColor: Colors.blue,
                          loadingFlatId: loadingTileIndex,
                          onTapFetch: onTapFetchFlat,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);

          },
        ),
        title: Text(
          "Analytics",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Cheque Summary (Tenant + Landlord)
            if (cleared > 0 || pending > 0)
              Container(
                height: 280,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Cheque Summary",
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 200, // ✅ fixed height
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              centerSpaceRadius: 30,
                              startDegreeOffset: -45,
                              sectionsSpace: 3,
                              sections: [
                                PieChartSectionData(
                                  value: cleared.toDouble(),
                                  title: '$cleared\nCleared',
                                  radius: 70,
                                  titleStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [Colors.teal.shade700, Colors.teal.shade400],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: pending.toDouble(),
                                  title: '$pending\nPending',
                                  radius: 70,
                                  titleStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [Colors.orange.shade700, Colors.orange.shade300],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Total",
                                  style: GoogleFonts.poppins(
                                      fontSize: 10, color: Colors.grey.shade600)),
                              const SizedBox(height: 2),
                              Text(
                                "${cleared + pending}",
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),


            /*// 🔹 Invoice Summary (Tenant only)
            if (!isLandlord && invoices.isNotEmpty)
              Container(
                height: 275,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Monthly Invoice Summary",
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          barGroups: invoices.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            int x = entry.key;
                            String month = entry.value.key;
                            double amount = entry.value.value;
                            return BarChartGroupData(
                              x: x,
                              barRods: [
                                BarChartRodData(
                                  toY: amount,
                                  color: appbar_color,
                                  width: 30,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  int idx = value.toInt();
                                  if (idx >= invoices.length) {
                                    return const SizedBox.shrink();
                                  }
                                  String monthKey =
                                  invoices.keys.elementAt(idx);
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      monthKey,
                                      style: GoogleFonts.poppins(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),*/

            // 🔹 Unit Distribution (Landlord only)
            if (isLandlord && buildingFlatCount.isNotEmpty)
              Container(
                height: 260,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Units Overview",
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (buildingFlatCount.values.reduce((a, b) => a > b ? a : b)).toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchCallback: (event, response) {
                              if (event is FlTapUpEvent && response != null && response.spot != null) {
                                final index = response.spot!.touchedBarGroupIndex;
                                if (index != null && index >= 0 && index < buildingFlatCount.length) {
                                  final buildingName = buildingFlatCount.keys.elementAt(index);
                                  _showUnitsPopup(context, buildingName); // ✅ same popup
                                }
                              }
                            },
                          ),

                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  int idx = value.toInt();
                                  if (idx >= buildingFlatCount.length) return const SizedBox.shrink();
                                  String label = buildingFlatCount.keys.elementAt(idx);
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      label,
                                      style: GoogleFonts.poppins(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: true),
                          barGroups: buildingFlatCount.entries.toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final label = entry.value.key;
                            final count = entry.value.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: count.toDouble(),
                                  color: appbar_color,
                                  width: 20,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
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
  Widget _buildUnitTile({
    required BuildContext context,
    required Map flat,
    required Color badgeColor,
    required int? loadingFlatId,
    required Future<void> Function(int flatId, String category) onTapFetch,
  }) {
    final int flatId = flat['id'] ?? -1;
    final isLoading = loadingFlatId == flatId;

    final flatName = flat['name']?.toString() ?? 'N/A';
    final flatType = flat['flat_type']?['name']?.toString() ?? 'N/A';

    final String category = flat['status'] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: GestureDetector(
        onTap: () => onTapFetch(flatId, category),   // 👈 send both
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: badgeColor.withOpacity(0.15)),
            child: Icon(Icons.home_outlined, color: badgeColor, size: 24),
          ),
          title: Text('Unit $flatName', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: Text('Type: $flatType',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),

        ),

      ),
    );
  }

}
