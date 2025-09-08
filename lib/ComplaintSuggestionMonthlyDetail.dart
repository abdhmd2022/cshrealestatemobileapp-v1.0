import 'dart:convert';
import 'dart:ui';
import 'package:cshrealestatemobile/ComplaintReport.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

class MonthlyDetailScreen extends StatefulWidget {
  final String monthKey; // e.g. "2025-04"
  final List<Map<String, dynamic>> entries;

  MonthlyDetailScreen({required this.monthKey, required this.entries});

  @override
  State<MonthlyDetailScreen> createState() => _MonthlyDetailScreenState();

}

  class _MonthlyDetailScreenState extends State<MonthlyDetailScreen> {
  late List<Map<String, dynamic>> _entries;
  late String monthKey;

  @override
  void initState() {
  super.initState();
  _entries = widget.entries.map((e) => Map<String, dynamic>.from(e)).toList();
  monthKey = widget.monthKey;
  _rebuildStatusChipOptions();  // ← derive chips from _entries
  _applyFilters();              // ← produce _filteredEntries from active filters
  }

  late List<Map<String, dynamic>> _filteredEntries;
  final Set<String> _activeStatusKeys = {'all'};
  List<Map<String, String>> _statusChipOptions = [];


  void _applyEntryUpdate(Map<String, dynamic> updated) {
    final id = updated['id'];
    final idx = _entries.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      setState(() {
        _entries[idx] = Map<String, dynamic>.from(updated);
        // keep filters/chips in sync with current data
        _rebuildStatusChipOptions();
        _applyFilters();
      });
    }
  }
  void _rebuildStatusChipOptions() {
    // Always have "Pending" if any record has null status
    final hasPending = _entries.any((e) => e['status'] == null);

    // Collect unique status names from data
    final Set<String> names = {};
    for (final e in _entries) {
      final st = e['status'];
      if (st is Map) {
        final n = (st['name'] ?? '').toString().trim();
        if (n.isNotEmpty) names.add(n);
      }
    }

    final List<Map<String, String>> chips = [];

    if (hasPending) {
      chips.add({'key': 'pending', 'name': 'Pending'});
    }

    for (final n in names) {
      chips.add({'key': _toKey(n), 'name': n});
    }

    // Keep currently selected keys if still present; otherwise fall back to 'all'
    final existingKeys = chips.map((c) => c['key']!).toSet()..add('all');
    if (!_activeStatusKeys.every(existingKeys.contains)) {
      _activeStatusKeys
        ..clear()
        ..add('all');
    }

    _statusChipOptions = chips;
  }

  String _toKey(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  void _applyFilters() {
    // 'all' → no filtering
    if (_activeStatusKeys.contains('all')) {
      _filteredEntries = List<Map<String, dynamic>>.from(_entries);
      return;
    }

    _filteredEntries = _entries.where((e) {
      final st = e['status'];
      if (st == null) {
        // pending
        return _activeStatusKeys.contains('pending');
      }
      final name = (st['name'] ?? '').toString();
      final key  = _toKey(name);
      return _activeStatusKeys.contains(key);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> groupByDay(
      List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      final createdAt = DateTime.tryParse(item['created_at'] ?? "") ??
          DateTime.now();
      final key = DateFormat('dd-MMM-yy').format(createdAt);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(item);
    }

    for (var list in grouped.values) {
      list.sort((a, b) =>
          DateTime.parse(b['created_at']).compareTo(
              DateTime.parse(a['created_at'])));
    }

    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          final nowYear = DateFormat('yyyy-MM')
              .parse(monthKey)
              .year;
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

  Future<Map<String, dynamic>> _fetchPartyDetails(
      {int? tenantId, int? landlordId}) async {
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
    try {
      return DateFormat(pattern).format(DateTime.parse(iso).toLocal());
    }
    catch (_) {
      return iso;
    }
  }

  Widget _kv(String label, String? value) =>
      Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130,
                child: Text(label,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            Expanded(child: Text((value == null || value.isEmpty) ? "—" : value,
                style: GoogleFonts.poppins())),
          ],
        ),
      );

  Widget _boxedSection({required String title, required Widget child}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(
              fontSize: 14.5, fontWeight: FontWeight.w600)),
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
        "$name${no != null ? " • $no" : ""}${expiry != null
            ? " • Expires ${fmtDate(expiry)}"
            : ""}",
        style: GoogleFonts.poppins(fontSize: 12.5),
      ),
    );
  }

  Future<void> _openDetailsSheet(
      BuildContext context,
      Map<String, dynamic> entry, {
        required void Function(Map<String, dynamic> updated) onUpdated,
      }) async {
    // Local mutable copy so the sheet can reflect edits immediately
    final localEntry = Map<String, dynamic>.from(entry);

    final String type = (localEntry['type'] ?? 'Unknown').toString();
    final String desc = (localEntry['description'] ?? 'No description').toString();

    final DateTime createdAt =
        DateTime.tryParse(localEntry['created_at'] ?? '') ?? DateTime.now();
    final String dateLabel = DateFormat('dd-MMM-yyyy • hh:mm a').format(createdAt);

    final int? tenantId = localEntry['tenant_id'] as int?;
    final int? landlordId = localEntry['landlord_id'] as int?;
    Map<String, dynamic>? status =
    localEntry['status'] is Map<String, dynamic> ? localEntry['status'] : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Editable Status Pill (inline widget)
            Widget _editableStatusPill() {
              final canEdit = hasPermission('canUpdateComplaintStatus');
              final isClosed = status?['category']?.toString().toLowerCase() == "close";

              final Color color = status != null ? _statusColor(status!) : Colors.orange;
              final IconData icon = status != null ? _statusIcon(status!) : Icons.access_time;
              final String text = status != null
                  ? (status!['name'] ?? 'Unknown').toString()
                  : 'Pending';

              final pillCore = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      style: GoogleFonts.poppins(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      !canEdit || isClosed ? Icons.lock_outline : Icons.edit_outlined,
                      size: 14,
                      color: canEdit ? color : Colors.grey,
                    ),
                  ],
                ),
              );

              if (!canEdit || isClosed) return pillCore;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final picked = await _pickStatus(
                    context: context,
                    selectedStatusId: status?['id'] as int?,
                  );
                  if (picked == null) return;

                  final ok = await _updateComplaintStatus(
                    complaintId: localEntry['id'] as int,
                    newStatusId: picked['id'] as int,
                  );

                  if (ok) {
                    // 1) Update local (sheet)
                    status = picked;
                    localEntry['status'] = picked;
                    setSheetState(() {});

                    // 2) Update parent list immediately
                    onUpdated(localEntry);

                    /*ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated'),
                        duration: Duration(seconds: 1),
                      ),
                    );*/
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update status'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: pillCore,
              );
            }

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

                      // Header row (icon + title + editable status pill)
                      Row(
                        children: [
                          Icon(
                            type == 'Suggestion'
                                ? Icons.lightbulb_outline
                                : Icons.report_problem_outlined,
                            color: type == 'Suggestion' ? Colors.teal : Colors.redAccent,
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
                          _editableStatusPill(), // ← editable pill
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
                            // date/time row (unchanged look)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
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

                            Text(
                              "Description",
                              style: GoogleFonts.poppins(
                                  fontSize: 14.5, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),

                            // Description box (unchanged styling)
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

                            const SizedBox(height: 16),

                            // Tenant/Landlord (Name, Email, Phone) only
                            FutureBuilder<Map<String, dynamic>>(
                              future: _fetchPartyDetails(
                                tenantId: tenantId,
                                landlordId: landlordId,
                              ),
                              builder: (context, snap) {
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: const [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 10),
                                        Text("Loading contact info...")
                                      ],
                                    ),
                                  );
                                }

                                final tenant =
                                snap.data?["tenant"] as Map<String, dynamic>?;
                                final landlord =
                                snap.data?["landlord"] as Map<String, dynamic>?;

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

                      // Footer button (unchanged)
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

  Color _statusColor(Map<String, dynamic> status) {
    final cat = (status['category'] ?? '').toString().toLowerCase();
    if (cat.contains('close')) return Colors.green;
    if (cat.contains('normal')) return Colors.orange;
    return Colors.orange; // fallback
  }

  IconData _statusIcon(Map<String, dynamic> status) {
    final cat = (status['category'] ?? '').toString().toLowerCase();
    if (cat.contains('close')) return Icons.check_circle;
    if (cat.contains('process')) return Icons.sync;
    return Icons.info_outline; // fallback
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupByDay(_filteredEntries); // <-- use filtered list
    final monthLabel = DateFormat('MMMM, yyyy').format(
        DateFormat('yyyy-MM').parse(monthKey));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => ComplaintSuggestionReportScreen()),
            );
          },
        ),
        title: Text(
            monthLabel, style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _statusFilterBar(),
          const SizedBox(height: 12),
          ...grouped.entries.map((group) {
            final day = group.key;
            final feedbacks = group.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16,
                          color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(

                        day,
                        style: GoogleFonts.poppins(fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                ...feedbacks.map((entry) {
                  final type = entry['type'] ?? 'Unknown';
                  final desc = entry['description'] ?? 'No description';
                  final tenant = entry['tenant']?['name'] ??
                      entry['landlord_id'] ?? "Unknown";
                  final createdAt = DateTime.tryParse(
                      entry['created_at'] ?? '') ?? DateTime.now();
                  final dateLabel = DateFormat('dd-MMM-yyyy • hh:mm a').format(
                      createdAt);

                  final isComplaint = type == 'Complaint';
                  final bgColor = isComplaint ? Colors.red : Colors.teal
                      .withOpacity(0.8);

                  return _buildEntryCard(
                    context: context,
                    entry: entry,
                    appColor: bgColor, // you already compute this based on type
                    onTap: () => _openDetailsSheet(context, entry,
                      onUpdated: _applyEntryUpdate, // <— will refresh list instantly
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ]

      ),
    );
  }

  Widget _buildEntryCard({
    required BuildContext context,
    required Map<String, dynamic> entry,
    required Color appColor,
    required VoidCallback onTap,
  }) {
    final type = (entry['type'] ?? 'Unknown').toString();
    final tenantName = entry['tenant']?['name']?.toString() ?? entry['landlord_id'].toString() ?? 'Unknown';
    final desc = (entry['description'] ?? 'No description').toString();
    final createdAt = DateTime.tryParse(entry['created_at'] ?? '') ?? DateTime.now();
    final dateLabel = DateFormat('dd-MMM-yyyy • hh:mm a').format(createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row: Avatar • Name/Date • Status ────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: appColor.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: appColor,
                    child: Text(
                      getInitials(tenantName).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantName,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                _statusChip(entry['status']), // 👈 status at top-right
              ],
            ),

            const SizedBox(height: 10),

            // ── Description ────────────────────────────────
            Text(
              desc,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                height: 1.35,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // ── Footer Row: Type (Complaint/Suggestion) + Chevron ──────
            Row(
              children: [
                _typeChip(type),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type) {
    final bool isSuggestion = type == 'Suggestion';
    final color = isSuggestion ? Colors.teal : Colors.redAccent;
    final icon  = isSuggestion ? Icons.lightbulb_outline : Icons.report_problem_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            type,
            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(dynamic status) {
    // status may be null → show Pending
    final bool has = status != null;
    final String label = has ? (status['name']?.toString() ?? 'Unknown') : 'Pending';
    final _StatusStyle s = _statusStyle(has ? status['category']?.toString() : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: s.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: s.color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 14, color: s.color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: s.color),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _pickStatus({
    required BuildContext context,
    int? selectedStatusId,
  }) async {
    final options = await _fetchStatusOptions(); // [{id, name, category}, ...]
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No statuses available')),
      );
      return null;
      
    }

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('Update Status', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade300),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final s = options[i];
                    final bool selected = selectedStatusId == s['id'];
                    final color = _statusColor({'category': s['category']});
                    final icon  = _statusIcon({'category': s['category']});
                    return ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(
                        s['name'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? color : Colors.black87,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: color)
                          : const Icon(Icons.circle_outlined, color: Colors.grey),
                      onTap: () => Navigator.pop(context, s),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStatusOptions() async {
    try {
      final res = await http.get(
        Uri.parse("$baseurl/tenant/complaintStatus"), // ← your endpoint
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        // ✅ matches: { data: { complaintStatus: [ {id,name,category,...}, ... ] } }
        final list = (body['data']?['complaintStatus'] as List?) ?? const [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
  Widget _statusFilterBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6), // glass effect
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Filter text + reset button
          Row(
            children: [
              Text(
                "Filter(s)",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
              const Spacer(),
              if (!_activeStatusKeys.contains('all'))
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeStatusKeys
                        ..clear()
                        ..add('all');
                      _applyFilters();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: appbar_color, // match appbar color
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Reset"),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Pills row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ALL pill
                _statusPill(
                  keyId: 'all',
                  label: 'All',
                  count: _entries.length,
                  icon: Icons.all_inclusive,
                  color: appbar_color,
                  selected: _activeStatusKeys.contains('all'),
                  onTap: () {
                    setState(() {
                      _activeStatusKeys
                        ..clear()
                        ..add('all');
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // Dynamic pills
                ..._statusChipOptions.map((c) {
                  final keyId = c['key']!;
                  final label = c['name']!;
                  final style = _chipStyleFor(keyId, label);
                  final selected = _activeStatusKeys.contains(keyId);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _statusPill(
                      keyId: keyId,
                      count: _countForKey(keyId),
                      label: label,
                      icon: style.icon,
                      color: style.color,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _activeStatusKeys.remove(keyId);
                            if (_activeStatusKeys.isEmpty) {
                              _activeStatusKeys.add('all');
                            }
                          } else {
                            _activeStatusKeys.remove('all');
                            _activeStatusKeys.add(keyId);
                          }
                          _applyFilters();
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _updateComplaintStatus({
    required int complaintId,
    required int newStatusId,
  }) async {
    try {
      final res = await http.patch(
        Uri.parse("$baseurl/tenant/complaint/$complaintId"),
        headers: {
          'Authorization': 'Bearer $Company_Token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status_id': newStatusId}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
// Counts the entries that match a given status key ("pending", "under_process", "closed", etc.)
    int _countForKey(String keyId) {
      int count = 0;
      for (final e in _entries) {
        final st = e['status'];
        if (st == null) {
          if (keyId == 'pending') count++;
        } else {
          final nameKey = _toKey((st['name'] ?? '').toString());
          if (nameKey == keyId) count++;
        }
      }
      return count;
    }
  }


// Color + icon per status (keeps things consistent)
_ChipVisual _chipStyleFor(String keyId, String label) {
  final l = label.toLowerCase();
  if (keyId == 'pending' || l == 'pending') {
    return _ChipVisual(Colors.orange, Icons.access_time);
  }
  if (l.contains('close')) {
    return _ChipVisual(Colors.green, Icons.check_circle);
  }
  if (l.contains('process')) {
    return _ChipVisual(Colors.orange, Icons.sync);
  }
  // default accent for unknowns
  return _ChipVisual(Colors.blueGrey, Icons.info_outline);
}

class _ChipVisual {
  final Color color;
  final IconData icon;
  _ChipVisual(this.color, this.icon);
}

class _StatusStyle {
  final Color color;
  final IconData icon;
  const _StatusStyle(this.color, this.icon);
}

_StatusStyle _statusStyle(String? category) {
  final cat = (category ?? '').toLowerCase();

  if (cat  == 'normal') return _StatusStyle(Colors.orange, Icons.sync);
  if (cat  == 'close') return _StatusStyle(Colors.green, Icons.check_circle);

  // fallback/unknown
  return _StatusStyle(Colors.orange, Icons.info_outline);
}
Widget _statusPill({
  required String keyId,
  required String label,
  required IconData icon,
  required Color color,
  required bool selected,
  required int count,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? color.withOpacity(0.35) : Colors.grey.shade300),
        color: selected ? color.withOpacity(0.01) : Colors.white,
        boxShadow: selected
            ? [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? color : Colors.blueGrey),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? color : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          // count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.09) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "$count",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}






