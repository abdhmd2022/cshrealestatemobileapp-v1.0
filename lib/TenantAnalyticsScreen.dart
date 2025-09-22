import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class TenantAnalyticsScreen extends StatefulWidget {
  final int cleared;
  final int pending;
  final Map<String, double> invoices;
  final Map<String, int> buildingFlatCount;
  final bool isLandlord;
  final List<Map<String, dynamic>> contracts;
  final int? loadingTileIndex;
  final Future<void> Function(int flatId, String category) onTapFetchFlat;

  const TenantAnalyticsScreen({
    super.key,
    required this.cleared,
    required this.pending,
    required this.invoices,
    required this.buildingFlatCount,
    required this.isLandlord,
    required this.contracts,
    required this.loadingTileIndex,
    required this.onTapFetchFlat,
  });

  @override
  State<TenantAnalyticsScreen> createState() => _TenantAnalyticsScreenState();
}

class _TenantAnalyticsScreenState extends State<TenantAnalyticsScreen> {


  @override
  void initState() {
    super.initState();

    // Debug all building names from contracts
    for (var contract in widget.contracts) {
      final flats = (contract['flats'] as List?) ?? [];
      for (var flat in flats) {
        debugPrint("Contract ${contract['contract_no']} → Unit ${flat['name']} in building: ${flat['building']?['name']}");
      }
    }

    // Debug the map you are using for chart
    widget.buildingFlatCount.forEach((building, count) {
      debugPrint("buildingFlatCount: $building → $count");
    });
  }

  void _showUnitsPopup(BuildContext context, String buildingName) {
    final units = widget.contracts
        .expand((contract) => (contract['flats'] as List?) ?? [])
        .where((flat) =>
    (flat['building']?['name'] ?? '').toString().trim() ==
        buildingName.toString().trim())
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
                          loadingFlatId: widget.loadingTileIndex,
                          onTapFetch: widget.onTapFetchFlat,
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
           /* // 🔹 Cheque Summary (Tenant + Landlord)
            if (!widget.isLandlord && widget.contracts.isNotEmpty)
              _buildPaymentSummaryPie(widget.contracts),
*/

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
            if (widget.isLandlord && widget.buildingFlatCount.isNotEmpty)
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
                          maxY: (widget.buildingFlatCount.values.reduce((a, b) => a > b ? a : b)).toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchCallback: (event, response) {
                              if (event is FlTapUpEvent &&
                                  response != null &&
                                  response.spot != null) {
                                final index = response.spot!.touchedBarGroupIndex;

                                if (index >= 0 &&
                                    index < widget.buildingFlatCount.length) {
                                  final buildingName = widget.buildingFlatCount.keys.elementAt(index);
                                  debugPrint("Tapped bar → $buildingName");

                                  // ✅ Delay bottom sheet opening until after gesture completes
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _showUnitsPopup(context, buildingName);
                                  });
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
                                  if (idx >= widget.buildingFlatCount.length) return const SizedBox.shrink();
                                  String label = widget.buildingFlatCount.keys.elementAt(idx);
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
                          barGroups: widget.buildingFlatCount.entries.toList().asMap().entries.map((entry) {
                            final index = entry.key;
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
