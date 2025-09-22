import 'dart:convert';

import 'package:cshrealestatemobile/TenantDashboard.dart';
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

  String _getChequeCategory(Map cheque) {
    final payment = cheque['payment'] ?? {};
    final chequeInfo = payment['cheque'] ?? {};

    // Returned
    if (payment['returned_on'] != null) {
      return "Returned";
    }

    // Cleared
    if (chequeInfo['cleared_on'] != null) {
      return "Cleared";
    }

    // Deposited
    if (chequeInfo['is_deposited']?.toString() == "true" &&
        chequeInfo['cleared_on'] == null) {
      return "Deposited";
    }

    // Received
    if (chequeInfo['is_received']?.toString() == "true") {
      return "Received";
    }

    return "Other";
  }


  Map<String, int> _buildChequeCounts() {
    final Map<String, int> counts = {
      "Received": 0,
      "Deposited": 0,
      "Cleared": 0,
      "Returned": 0,
    };

    for (var contract in widget.contracts) {
      final cheques = contract['cheques'] ?? [];
      for (var chq in cheques) {
        final cat = _getChequeCategory(chq);
        if (counts.containsKey(cat)) {
          counts[cat] = counts[cat]! + 1;
        }
      }
    }
    return counts;
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

  Map<String, List<Map>> _groupPaymentsByType(List contracts) {
    final payments = contracts.expand((c) => (c['payments'] as List?) ?? []);
    final Map<String, List<Map>> grouped = {};
    for (var p in payments) {
      final type = p['type'] ?? 'Unknown';
      grouped.putIfAbsent(type, () => []).add(p);
    }

    return grouped;
  }
  String _getShortTypeLabel(String type) {
    switch (type) {
      case "Online_Transfer":
        return "OT";
      case "Cheque":
        return "Cheque";
      case "Cash":
        return "Cash";
      case "Card":
        return "Card";
      default:
        return type;
    }
  }

  Widget _buildPaymentSummaryPie(List contracts) {
    final grouped = _groupPaymentsByType(contracts);
    final totalPayments =
    grouped.values.fold<int>(0, (a, b) => a + b.length);

    final sections = grouped.entries.map((entry) {
      final type = entry.key;
      final count = entry.value.length;

      final color = _getTypeColor(type);

      return PieChartSectionData(

        value: count.toDouble(),
        title: '$count\n${_getShortTypeLabel(type)}',
        radius: 70,
        titleStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        color: color,
      );
    }).toList();


    return Container(
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
          Text("Payment Summary",
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 30,
                    startDegreeOffset: -45,
                    sectionsSpace: 3,
                    sections: sections,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent && response?.touchedSection != null) {
                          final index = response!.touchedSection!.touchedSectionIndex;
                          final type = grouped.keys.elementAt(index);
                          _showPaymentsPopup(context, type, grouped[type]!);
                        }
                      },
                    ),
                  ),
                ),

                // 🔹 Center Total
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Total",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        // 👇 Show all payments
                        final allPayments = grouped.values.expand((list) => list).toList();
                        _showPaymentsPopup(context, "All", allPayments);
                      },
                      child: Text(
                        "$totalPayments",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
  void _showPaymentsPopup(BuildContext context, String type, List<Map> payments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.7,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                    child: Column(
                      children: [
                        // 🔹 Header (same as cheque popup)
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: type == "All" ? Colors.teal : _getTypeColor(type),
                                child: Icon(Icons.payments, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 10),

                              // 🔹 Title
                              Text(
                                type == "All" ? "All Payments" : "$type Payments",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // 🔹 Count
                              Text(
                                "${payments.length} payment(s)",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Divider(),

                        // 🔹 Payments list
                        Expanded(
                          child: payments.isEmpty
                              ? Center(
                            child: Text(
                              "No payments found",
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          )
                              : ListView.builder(
                            controller: scrollController,
                            itemCount: payments.length,
                            itemBuilder: (context, i) {
                              final payment = payments[i];
                              final contract = _findContractForPayment(
                                  payment, widget.contracts);
                              final unit =
                              (contract['flats'] as List?)?.isNotEmpty ==
                                  true
                                  ? contract['flats'][0]
                                  : {};

                              return _buildPaymentCard(
                                  payment, contract, unit, type);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔹 Close button
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
      },
    );
  }

  Map _findContractForPayment(Map payment, List contracts) {
    for (final contract in contracts) {
      final payments = (contract['payments'] as List?) ?? [];
      if (payments.any((p) => p['payment_id'] == payment['payment_id'])) {
        return contract;
      }
    }
    return {}; // not found
  }

  String _getPaymentStatus(Map payment) {
    // Only cheque payments have detailed statuses
    if (payment['type'] == "Cheque") {
      if (payment['returned_on'] != null) return "Returned";
      if (payment['cleared_on'] != null) return "Cleared";
      if (payment['is_deposited']?.toString() == "true" &&
          payment['cleared_on'] == null) return "Deposited";
      if (payment['is_received']?.toString() == "true") return "Received";
      return "Other";
    }

    // Non-cheque payments → use generic "Done" or "Recorded"
    return "Cleared";
  }


  Widget _buildPaymentCard(Map payment, Map contract, Map unit, String type) {
    final status = _getPaymentStatus(payment);
    final receivedOn = payment['date'];
    final depositedOn = payment['deposited_on'];
    final clearedOn = payment['cleared_on'];
    final returnedOn = payment['returned_on'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        // 🔹 Leading avatar
        leading: CircleAvatar(
          radius: 36,
          backgroundColor: _getCategoryColor(status),
          child: Icon(Icons.payments, color: Colors.white, size: 28),
        ),


        // 🔹 Title + Chip in one Row
        title: Row(
          children: [
            Expanded(
              child: Text(
                "${payment['instrument_no'] ?? '-'}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(width: 8,),
            _buildStatusChip(status), // ✅ chip stays right side, no overlap
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset("assets/dirham.png",
                    height: 13, width: 13, ),
                const SizedBox(width: 4),
                Text(
                  "${payment['amount'] ?? '-'}",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
            if (payment['bank_name'] != null)
              Text("Bank: ${payment['bank_name']}",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600)),
            if (type == "Cheque") ...[
              if (receivedOn != null)
                Text("Received on: ${formatDate(receivedOn)}",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
              if (depositedOn != null)
                Text("Deposited on: ${formatDate(depositedOn)}",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
              if (clearedOn != null)
                Text("Cleared on: ${formatDate(clearedOn)}",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
              if (returnedOn != null)
                Text("Returned on: ${formatDate(returnedOn)}",
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500)),
            ] else if (payment['date'] != null) ...[
              Text("Date: ${formatDate(payment['date'])}",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ],
        ),

        // 🔹 Expanded details
        children: [
          if (unit.isNotEmpty) _buildUnitDetails(unit),
          if (contract.isNotEmpty) _buildContractDetails(contract),
        ],
      ),
    );
  }


  Color _getTypeColor(String type) {
    switch (type) {
      case "Cheque":
        return Colors.orange;
      case "Cash":
        return Colors.green;
      case "Card":
        return Colors.blue;
      case "Online_Transfer":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUnitDetails(Map unit) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon + title
          Row(
            children: [
              Icon(Icons.apartment_outlined,
                  size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                "Unit Details",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details
          Text(
            "Unit: ${unit['name']} - ${unit['flat_type']?['name'] ?? '-'}",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            "Building: ${unit['building']?['name'] ?? '-'}, ${unit['building']?['area']?['name'] ?? '-'}, ${unit['building']?['area']?['state']?['name'] ?? '-'}",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
          ),

        ],
      ),
    );
  }
  Widget _buildContractDetails(Map contract) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon + title
          Row(
            children: [
              Icon(Icons.assignment_outlined,
                  size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                "Contract Details",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details
          Text(
            "Contract #: ${contract['contract_no'] ?? '-'}",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            "Type: ${contract['contract_type'] ?? '-'}",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            "Expiry: ${formatDate(contract['expiry_date'])}",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final chequeCounts = _buildChequeCounts();
    final totalCheques = chequeCounts.values.fold(0, (a, b) => a + b);



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
            if (!widget.isLandlord && widget.contracts.isNotEmpty)
              _buildPaymentSummaryPie(widget.contracts),


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

                                if (index != null &&
                                    index >= 0 &&
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
  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getCategoryColor(status), width: 1),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getCategoryColor(status),
        ),
      ),
    );
  }




  Color _getCategoryColor(String category) {
    switch (category) {
      case "Received":
        return Colors.blue;
      case "Deposited":
        return Colors.orange;
      case "Cleared":
        return Colors.green;
      case "Returned":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildExpandableChequeCard(
      Map chq, Map payment, Map chequeInfo, String status, String category)
  {
    final contract = _findContractForCheque(chq);
    final unit = (contract['flats'] as List?)?.isNotEmpty == true
        ? contract['flats'][0]
        : {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        // 🔹 Summary Row (always visible)
        leading: CircleAvatar(
          backgroundColor: (category == "All"
              ? _getCategoryColor(status)
              : _getCategoryColor(category))
              .withOpacity(0.15),
          child: Icon(
            Icons.description_outlined,
            color: category == "All"
                ? _getCategoryColor(status)
                : _getCategoryColor(category),
          ),
        ),
        title: Text(
          "Cheque #${payment['instrument_no'] ?? '-'}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount row with AED icon
            Row(
              children: [
                Image.asset("assets/dirham.png", height: 13, width: 13),
                const SizedBox(width: 4),
                Text(
                  "${payment['amount'] ?? '-'}",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Bank name
            if (payment['bank_name'] != null)
              Text("Bank: ${payment['bank_name']}",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600)),

            // 🔹 Dates (using your formatDate function)
            if (payment['date'] != null)
              Text(
                "Received on: ${formatDate(payment['date'])}",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (payment['deposited_on'] != null)
              Text(
                "Deposited on: ${formatDate(payment['deposited_on'])}",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (payment['cleared_on'] != null)
              Text(
                "Cleared on: ${formatDate(payment['cleared_on'])}",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (payment['returned_on'] != null)
              Text(
                "Returned on: ${formatDate(payment['returned_on'])}",
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),


        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category == "All") _buildStatusChip(status), // ✅ chip only in All
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey), // dropdown arrow
          ],
        ),

        // 🔹 Expanded Details → as mini sub-cards
        children: [
          if (unit.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.apartment_outlined,
                          size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text("Unit Details",
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Unit: ${unit['name']} - ${unit['flat_type']?['name'] ?? '-'}",
                      style: GoogleFonts.poppins(fontSize: 13)),
                  Text("Building: ${unit['building']?['name'] ?? '-'}, ${unit['building']?['area']['name'] ?? '-'}, ${unit['building']?['area']['state']['name'] ?? '-'}",
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
            ),

          if (contract.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text("Contract Details",
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Contract #: ${contract['contract_no'] ?? '-'}",
                      style: GoogleFonts.poppins(fontSize: 13)),
                  Text("Type: ${contract['contract_type'] ?? '-'}",
                      style: GoogleFonts.poppins(fontSize: 13)),
                  Text("Expiry: ${formatDate(contract['expiry_date']) ?? '-'}",
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
            ),
        ],
      ),
    );
  }



  Map<String, dynamic> _findContractForCheque(Map cheque) {
    for (var contract in widget.contracts) {
      final cheques = contract['cheques'] ?? [];
      if (cheques.contains(cheque)) {
        return contract;
      }
    }
    return {};
  }

}
PieChartSectionData _buildSection(String label, int count, List<Color> colors) {
  return PieChartSectionData(
    value: count.toDouble(),
    title: "$count\n$label",
    radius: 70,
    titleStyle: GoogleFonts.poppins(
      fontSize: 11,

      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    gradient: LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,

      end: Alignment.bottomRight,
    ),
  );
}
