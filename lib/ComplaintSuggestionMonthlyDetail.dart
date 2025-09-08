import 'dart:convert';
import 'dart:ui';
import 'package:cshrealestatemobile/ComplaintReport.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

class MonthlyDetailScreen extends StatelessWidget {
  final String monthKey; // e.g. "2025-04"
  final List<Map<String, dynamic>> entries;

  MonthlyDetailScreen({required this.monthKey, required this.entries});

  Future<Map<String, dynamic>?> _fetchTenantById(int id) async {
    final headers = {
      'Authorization': 'Bearer $Company_Token',
      'Content-Type': 'application/json',
    };
    try {
      final res = await http.get(Uri.parse("$baseurl/tenant/$id"), headers: headers);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        return body['data']?['tenant'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _fetchLandlordById(int id) async {
    final headers = {
      'Authorization': 'Bearer $Company_Token',
      'Content-Type': 'application/json',
    };
    try {
      final res = await http.get(Uri.parse("$baseurl/landlord/$id"), headers: headers);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        return body['data']?['landlord'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  // ---------- GROUPING / UTILS ----------
  Map<String, List<Map<String, dynamic>>> groupByDay(List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      final createdAt = DateTime.tryParse(item['created_at'] ?? "") ?? DateTime.now();
      final key = DateFormat('dd-MMM').format(createdAt);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(item);
    }

    for (var list in grouped.values) {
      list.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    }

    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          final nowYear = DateFormat('yyyy-MM').parse(monthKey).year;
          // Parse dd-MMM without year, then attach current month/year for stable sorting
          final aDate = DateFormat('dd-MMM-yyyy').parse("${a.key}-$nowYear");
          final bDate = DateFormat('dd-MMM-yyyy').parse("${b.key}-$nowYear");
          return bDate.compareTo(aDate);
        }),
    );
  }

  String getInitials(String name) {
    final parts = name.trim().split(" ");
    return parts.length > 1
        ? "${parts[0][0]}${parts[1][0]}"
        : name.isNotEmpty ? name[0] : "?";
  }

  // ---------- NETWORK: FETCH TENANT / LANDLORD DETAILS ----------
  Future<Map<String, dynamic>> _fetchPartyDetails({int? tenantId, int? landlordId}) async {
    final Map<String, dynamic> result = {"tenant": null, "landlord": null};

    final headers = {
      'Authorization': 'Bearer $Company_Token',
      'Content-Type': 'application/json',
    };

    try {
      if (tenantId != null) {
        // 👉 Adjust if your real endpoint differs
        final uriTenant = Uri.parse("$baseurl/tenant/$tenantId");
        final resT = await http.get(uriTenant, headers: headers);
        if (resT.statusCode == 200) {
          final body = json.decode(resT.body);
          result["tenant"] = body["data"]?["tenant"]; // matches your sample
        }
      }

      if (landlordId != null) {
        // 👉 Adjust if your real endpoint differs
        final uriLandlord = Uri.parse("$baseurl/landlord/$landlordId");
        final resL = await http.get(uriLandlord, headers: headers);
        if (resL.statusCode == 200) {
          final body = json.decode(resL.body);
          result["landlord"] = body["data"]?["landlord"]; // matches your sample
        }
      }
    } catch (_) {}

    return result;
  }

  String fmtDate(String? iso, {String pattern = 'dd-MMM-yyyy'}) {
    if (iso == null || iso.isEmpty) return "—";
    try { return DateFormat(pattern).format(DateTime.parse(iso).toLocal()); }
    catch (_) { return iso; }
  }

  Widget _kv(String label, String? value) => Padding(
    padding: const EdgeInsets.only(top: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(child: Text((value == null || value.isEmpty) ? "—" : value, style: GoogleFonts.poppins())),
      ],
    ),
  );

  Widget _boxedSection({required String title, required Widget child}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      ),
    ],
  );


  Widget _docChip(String name, String? no, String? expiry) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        "$name${no != null ? " • $no" : ""}${expiry != null ? " • Expires ${fmtDate(expiry)}" : ""}",
        style: GoogleFonts.poppins(fontSize: 12.5),
      ),
    );
  }

  Widget _tenantCard(Map<String, dynamic> t) {
    // Primary contact fields
    final name        = t["name"]?.toString();
    final email       = t["email"]?.toString();
    final phone       = (t["mobile_no"] ?? t["phone_no"])?.toString();
    final nationality = t["nationality"]?.toString();
    final address     = t["address"]?.toString() ?? t["residential"]?.toString();

    // IDs
    final emiratesId  = t["emirates_id"]?.toString();
    final emiratesExp = t["emirates_id_expiry"]?.toString();
    final passport    = t["passport_no"]?.toString();
    final passportExp = t["passport_expiry"]?.toString();

    // Current unit/building (first contract → first flat)
    String? unitName, buildingName, flatType;
    try {
      final contracts = (t["contracts"] as List?) ?? const [];
      if (contracts.isNotEmpty) {
        final flats = (contracts.first["flats"] as List?) ?? const [];
        if (flats.isNotEmpty) {
          final flat     = flats.first["flat"] as Map<String, dynamic>?;
          unitName       = flat?["name"]?.toString();
          buildingName   = flat?["building"]?["name"]?.toString();
          flatType       = flat?["flat_type"]?["name"]?.toString();
        }
      }
    } catch (_) {}

    final kyc = (t["kyc_details"] as List?) ?? const [];

    return _boxedSection(
      title: "Tenant",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv("Name", name),
          _kv("Email", email),
          _kv("Phone", phone),
          const SizedBox(height: 6),
          _kv("Nationality", nationality),
          _kv("Address", address),
          const SizedBox(height: 6),
          _kv("Emirates ID", emiratesId),
          _kv("Emirates Expiry", fmtDate(emiratesExp)),
          _kv("Passport No", passport),
          _kv("Passport Expiry", fmtDate(passportExp)),
          const SizedBox(height: 10),
          if (unitName != null || buildingName != null || flatType != null) ...[
            Text("Current Unit", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _kv("Unit", unitName),
            _kv("Building", buildingName),
            _kv("Type", flatType),
            const SizedBox(height: 10),
          ],
          if (kyc.isNotEmpty) ...[
            Text("KYC", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              children: kyc.map((d) {
                final docType = d["doc_type"]?["name"]?.toString() ?? "Document";
                final docNo   = d["doc_no"]?.toString();
                final exp     = d["expiry_date"]?.toString();
                return _docChip(docType, docNo, exp);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _landlordCard(Map<String, dynamic> l) {
    final name        = l["name"]?.toString();
    final email       = l["email"]?.toString();
    final phone       = (l["mobile_no"] ?? l["phone_no"])?.toString();
    final nationality = l["nationality"]?.toString();
    final address     = l["address"]?.toString() ?? l["residential"]?.toString();

    // IDs
    final emiratesId  = l["emirates_id"]?.toString();
    final emiratesExp = l["emirates_id_expiry"]?.toString();
    final passport    = l["passport_no"]?.toString();
    final passportExp = l["passport_expiry"]?.toString();

    final kyc = (l["kyc_details"] as List?) ?? const [];

    return _boxedSection(
      title: "Landlord",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv("Name", name),
          _kv("Email", email),
          _kv("Phone", phone),
          const SizedBox(height: 6),
          _kv("Nationality", nationality),
          _kv("Address", address),
          const SizedBox(height: 6),
          _kv("Emirates ID", emiratesId),
          _kv("Emirates Expiry", fmtDate(emiratesExp)),
          _kv("Passport No", passport),
          _kv("Passport Expiry", fmtDate(passportExp)),
          const SizedBox(height: 10),
          if (kyc.isNotEmpty) ...[
            Text("KYC", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              children: kyc.map((d) {
                final docType = d["doc_type"]?["name"]?.toString() ?? "Document";
                final docNo   = d["doc_no"]?.toString();
                final exp     = d["expiry_date"]?.toString();
                return _docChip(docType, docNo, exp);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tenantDetails(Map<String, dynamic> t) {
    final emiratesId  = t["emirates_id"]?.toString();
    final emiratesExp = t["emirates_id_expiry"]?.toString();
    final passport    = t["passport_no"]?.toString();
    final passportExp = t["passport_expiry"]?.toString();
    final nationality = t["nationality"]?.toString();
    final address     = t["address"]?.toString() ?? t["residential"]?.toString();
    final kyc         = (t["kyc_details"] as List?) ?? const [];

    String? unitName, buildingName, flatType;
    try {
      final contracts = (t["contracts"] as List?) ?? const [];
      if (contracts.isNotEmpty) {
        final flats = (contracts.first["flats"] as List?) ?? const [];
        if (flats.isNotEmpty) {
          final flat   = flats.first["flat"] as Map<String, dynamic>?;
          unitName     = flat?["name"]?.toString();
          buildingName = flat?["building"]?["name"]?.toString();
          flatType     = flat?["flat_type"]?["name"]?.toString();
        }
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv("Nationality", nationality),
        _kv("Address", address),
        const SizedBox(height: 6),
        _kv("Emirates ID", emiratesId),
        _kv("Emirates Expiry", fmtDate(emiratesExp)),
        _kv("Passport No", passport),
        _kv("Passport Expiry", fmtDate(passportExp)),
        if (unitName != null || buildingName != null || flatType != null) ...[
          const SizedBox(height: 10),
          Text("Current Unit", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _kv("Unit", unitName),
          _kv("Building", buildingName),
          _kv("Type", flatType),
        ],
        if (kyc.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text("KYC", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            children: kyc.map((d) {
              final docType = d["doc_type"]?["name"]?.toString() ?? "Document";
              final docNo   = d["doc_no"]?.toString();
              final exp     = d["expiry_date"]?.toString();
              return _docChip(docType, docNo, exp);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _landlordDetails(Map<String, dynamic> l) {
    final emiratesId  = l["emirates_id"]?.toString();
    final emiratesExp = l["emirates_id_expiry"]?.toString();
    final passport    = l["passport_no"]?.toString();
    final passportExp = l["passport_expiry"]?.toString();
    final nationality = l["nationality"]?.toString();
    final address     = l["address"]?.toString() ?? l["residential"]?.toString();
    final kyc         = (l["kyc_details"] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv("Nationality", nationality),
        _kv("Address", address),
        const SizedBox(height: 6),
        _kv("Emirates ID", emiratesId),
        _kv("Emirates Expiry", fmtDate(emiratesExp)),
        _kv("Passport No", passport),
        _kv("Passport Expiry", fmtDate(passportExp)),
        if (kyc.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text("KYC", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            children: kyc.map((d) {
              final docType = d["doc_type"]?["name"]?.toString() ?? "Document";
              final docNo   = d["doc_no"]?.toString();
              final exp     = d["expiry_date"]?.toString();
              return _docChip(docType, docNo, exp);
            }).toList(),
          ),
        ],
      ],
    );
  }


  // ---------- UI HELPERS ----------
  Widget _pillFromStatus(Map<String, dynamic>? status, String type) {
    String text;
    Color color;

    if (status != null) {
      text = (status["name"] ?? "Status").toString();
      final cat = (status["category"] ?? "").toString().toLowerCase();
      if (cat.contains("close")) {
        color = Colors.green;
      } else if (cat.contains("normal") || cat.contains("process")) {
        color = Colors.orange;
      } else {
        color = Colors.blueGrey;
      }
    } else {
      text = type;
      color = type == "Suggestion" ? Colors.teal : Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text((value?.isNotEmpty ?? false) ? value! : "—", style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  void _openDetailsSheet(BuildContext context, Map<String, dynamic> entry) {
    final String type = (entry['type'] ?? 'Unknown').toString();
    final String desc = (entry['description'] ?? 'No description').toString();

    // Date/time (keep your exact formatting)
    final DateTime createdAt =
        DateTime.tryParse(entry['created_at'] ?? '') ?? DateTime.now();
    final String dateLabel =
    DateFormat('dd-MMM-yyyy • hh:mm a').format(createdAt);

    // IDs to fetch details
    final int? tenantId = entry['tenant_id'];
    final int? landlordId = entry['landlord_id'];

    // Status object from list API
    final Map<String, dynamic>? status =
    entry['status'] is Map<String, dynamic> ? entry['status'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  )
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                children: [
                  // grab handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // header row (icon + title + status pill)
                  Row(
                    children: [
                      Icon(
                        type == 'Suggestion'
                            ? Icons.lightbulb_outline
                            : Icons.report_problem_outlined,
                        color:
                        type == 'Suggestion' ? Colors.teal : Colors.redAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${type == 'Complaint' ? 'Complaint' : 'Suggestion'} Details",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _pillFromStatus(status, type),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 8),

                  // BODY
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        // date/time row (unchanged)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: Colors.blueAccent),
                              const SizedBox(width: 6),
                              Text(
                                dateLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueAccent.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),


                        const SizedBox(height: 14),

                        // description title (unchanged)
                        Text(
                          "Description",
                          style: GoogleFonts.poppins(
                              fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),

                        // description box (unchanged styling)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            desc,
                            style: GoogleFonts.poppins(fontSize: 13.5, height: 1.4),
                          ),
                        ),

                        // ⬇️ NEW: minimal Tenant/Landlord info appended after description
                        const SizedBox(height: 16),

                        FutureBuilder<Map<String, dynamic>>(
                          future: _fetchPartyDetails(
                            tenantId: tenantId,
                            landlordId: landlordId,
                          ),
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: const [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator.adaptive(

                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text("Loading contact info...")
                                  ],
                                ),
                              );
                            }

                            final tenant = snap.data?["tenant"]
                            as Map<String, dynamic>?;
                            final landlord = snap.data?["landlord"]
                            as Map<String, dynamic>?;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tenant != null) ...[
                                  _partyCard("Tenant", tenant),
                                  const SizedBox(height: 12),
                                ],
                                if (landlord != null) _partyCard("Landlord", landlord),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 8),

                  // footer button (unchanged)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appbar_color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: Text(
                        "Close",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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

  Widget _partyCard(String title, Map<String, dynamic> data) {
    return _boxedSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv("Name", data["name"]?.toString()),
          _kv("Email", data["email"]?.toString()),
          _kv("Phone", (data["mobile_no"] ?? data["phone_no"])?.toString()),
        ],
      ),
    );
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                    const SizedBox(width: 6),
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
                final tenant = entry['tenant']?['name'] ?? entry['landlord_id']?? "Unknown";
                final createdAt = DateTime.tryParse(entry['created_at'] ?? '') ?? DateTime.now();
                final dateLabel = DateFormat('dd-MMM-yyyy • hh:mm a').format(createdAt);

                final isComplaint = type == 'Complaint';
                final bgColor = isComplaint ? Colors.red : Colors.teal.withOpacity(0.8);
                final icon = isComplaint ? Icons.report_problem : Icons.lightbulb;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    onTap: () => _openDetailsSheet(context, entry), // <-- OPEN POPUP HERE
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: bgColor.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: bgColor,
                        radius: 22,
                        child: Text(
                          getInitials(tenant.toString()).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(type.toString(), style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}
