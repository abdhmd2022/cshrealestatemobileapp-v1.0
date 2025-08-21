import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Sidebar.dart';
import 'constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class AvailableUnitsReport extends StatefulWidget {
  const AvailableUnitsReport({Key? key}) : super(key: key);
  @override
  _AvailableUnitsReportPageState createState() => _AvailableUnitsReportPageState();
}

class _AvailableUnitsReportPageState extends State<AvailableUnitsReport> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      isVisibleNoUserFound = false;

  String statusFilter = "All"; // NEW: "All" | "Rent" | "Buy"


  bool isLoading = true;

  int currentFlatPage = 1;
  int totalFlatPages = 1;
  bool isFetchingMoreFlats = false;

  String searchQuery = "";
  String name = "", email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late SharedPreferences prefs;

  String? hostname = "", company = "", company_lowercase = "", serial_no = "", username = "", HttpURL = "", SecuritybtnAcessHolder = "";
  late Future<List<Flat>> futureFlats;
  List<Flat> filteredUnits = []; // List to store API data
  List<Flat> allUnits = []; // Stores all units fetched from API

  bool isPriceRangeModified = false;

  String? selectedSortLabel; // e.g. "Price: Low → High"

  double rangeMin = 10000;

  double rangeMax = 100000;

  String selectedSort = "none"; // Options: "low_to_high", "high_to_low"

  List<String> availableFlatTypes = [];
  List<String> availableAmenities = [];
  List<String> selectedFlatTypes = [];
  RangeValues selectedPriceRange = const RangeValues(0, 2000000);
  List<String> selectedAmenities = [];

  PdfColor _statusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s == 'buy') return PdfColors.blue600;
    if (s == 'rent') return PdfColors.green600;
    return PdfColors.grey600;
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    rangeMin = prefs.getDouble('range_min') ?? 0;
    rangeMax = prefs.getDouble('range_max') ?? 2000000;

    selectedPriceRange = RangeValues(rangeMin, rangeMax); // default full range
    setState(() {
      fetchFiltersData(); // 👈 Add this

      fetchFlats();
    });
  }
  // CHANGED: unit-wise price when statusFilter == "All"
  // --- Dynamic price & label (unit-wise) ---
  int? _currentPrice(Flat u) {
    return (u.status == "Buy") ? u.basicSaleValue : u.basicRent;
  }

  String _priceLabelFor(Flat u) {
    return (u.status == "Buy") ? "Price" : "Rent";
  }




// NEW: “best price” per flat type under current status
  bool _isBestPriceInFlatType(Flat unit) {
    // determine cohort (which units to compare against)
    final String unitStatus = (unit.status ?? '').toLowerCase();
    final String filter = statusFilter.toLowerCase();

    // when "All", compare within the unit's own status; otherwise, use the selected category
    final String cohortStatus = (filter == 'all') ? unitStatus : filter;

    // gather comparable units: same flat type, same cohort status, with a price
    final candidates = filteredUnits.where((u) {
      final s = (u.status ?? '').toLowerCase();
      if (u.flatTypeName != unit.flatTypeName) return false;
      if (s != cohortStatus) return false;

      final p = _currentPrice(u);
      return p != null;
    }).toList();

    if (candidates.length < 2) return false;

    // find min within the cohort
    final minPrice = candidates
        .map((u) => _currentPrice(u)!)
        .reduce((a, b) => a < b ? a : b);

    final myPrice = _currentPrice(unit);
    return myPrice != null && myPrice == minPrice;
  }


  Future<void> fetchFlats() async {
    setState(() {
      isLoading = true;
      allUnits.clear(); // Reset list
    });

    List<Flat> combinedFlats = [];

    try {
      Future<void> fetchByStatus(String status) async {
        int currentPage = 1;
        int totalPages = 1;

        do {
          String url =
              "$baseurl/reports/flat/available/date?date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}"
              "&status=$status"
              "&page=$currentPage";

          print("Fetching: $url");

          final response = await http.get(
            Uri.parse(url),
            headers: {
              "Authorization": "Bearer $Company_Token",
              "Content-Type": "application/json",
            },
          );

          if (response.statusCode != 200) {
            final errorMessage =
                "Failed to fetch $status flats on page $currentPage (Status: ${response.statusCode})";

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text(errorMessage)),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 3),
              ),
            );

            throw Exception(errorMessage);
          }

          final data = json.decode(response.body);
          final flatsJson = data["data"]["flats"] as List<dynamic>? ?? [];
          combinedFlats.addAll(flatsJson.map((json) => Flat.fromJson(json)));

          // Handle meta safely
          final meta = data["meta"];
          print("Meta received: $meta");

          if (meta != null) {
            int totalCount = (meta["totalCount"] ?? 0) as int;
            int size = (meta["size"] ?? 1) as int;
            if (size == 0) size = 1; // prevent division by zero
            totalPages = (totalCount / size).ceil();
          }

          currentPage++;
        } while (currentPage <= totalPages);
      }

      // Fetch for both statuses
      await fetchByStatus("Rent");
      await fetchByStatus("Buy");

      setState(() {
        allUnits = combinedFlats.reversed.toList(); // Optional: reverse order
        // ✅ Dynamic min & max based on unit prices
        final prices = allUnits
            .map((u) => _currentPrice(u))
            .where((p) => p != null)
            .cast<int>()
            .toList();


        if (prices.isNotEmpty) {
          double minPrice = prices.reduce((a, b) => a < b ? a : b).toDouble();
          double maxPrice = prices.reduce((a, b) => a > b ? a : b).toDouble();

          // ✅ Add buffer ±5000
          rangeMin = (minPrice - 5000).clamp(0, double.infinity); // prevent negative
          rangeMax = maxPrice + 5000;

          selectedPriceRange = RangeValues(rangeMin, rangeMax);
        }
        filteredUnits = allUnits;
      });
    } catch (e) {
      print("Error fetching flats: $e");
    }

    setState(() {
      isLoading = false;
      isFetchingMoreFlats = false;
    });
  }

  Future<Uint8List> buildModernUnitsPdfBytes(List<Flat> units) async {
    final pdf = pw.Document();

    // ---- 1) Load fonts (embed to avoid spacing/kerning issues) ----
    final regData  = await rootBundle.load('Inter-Regular.ttf');
    final boldData = await rootBundle.load('Inter-SemiBold.ttf');

// Pass ByteData directly (no .buffer.asUint8List())
    final fontRegular = pw.Font.ttf(regData);
    final fontBold    = pw.Font.ttf(boldData);

    // ---- 2) Optional assets (logo, AED icon) ----
    pw.ImageProvider? logoImage;
    try {
      final data = await rootBundle.load('assets/icon_realestate.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}
    pw.ImageProvider? aedIcon;
    try {
      final data = await rootBundle.load('assets/dirham.png');
      aedIcon = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    // ---- 3) Page theme (A4) with embedded fonts ----
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    final now = DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now());

    // ---- 4) Small helpers ----
    PdfColor _statusColor(String? status) {
      final s = (status ?? '').toLowerCase();
      if (s == 'buy')  return PdfColors.blue600;
      if (s == 'rent') return PdfColors.green600;
      return PdfColors.grey600;
    }

    pw.Widget _chip(String text, {PdfColor color = PdfColors.grey300, PdfColor textColor = PdfColors.black}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(12)),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: textColor)),
      );
    }

    pw.Widget _statusChip(String? status) {
      final color = _statusColor(status);
      return _chip(status ?? 'Unknown', color: color, textColor: PdfColors.white);
    }

    pw.Widget _kvTable(Map<String, String> data) {
      return pw.Table(
        border: null,
        columnWidths: const {
          0: pw.FixedColumnWidth(95),   // label column width (tweak 85–110 if needed)
          1: pw.FlexColumnWidth(),      // value column takes remaining space
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: data.entries.map((e) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Text(
                  e.key,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.left,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Text(
                  e.value,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.left,
                  softWrap: true,
                ),
              ),
            ],
          );
        }).toList(),
      );
    }

    pw.Widget _priceLine(String label, String value) {
      return pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 6),
          if (aedIcon != null) pw.Image(aedIcon, width: 10, height: 10),
          if (aedIcon != null) pw.SizedBox(width: 3),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      );
    }

    pw.Widget _unitCard(Flat u) {
      final isBuy      = (u.status ?? '').toLowerCase() == 'buy';
      final priceLabel = isBuy ? 'Price' : 'Rent';
      final priceStr   = (isBuy ? u.basicSaleValue : u.basicRent)?.toString() ?? 'N/A';

      return pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(color: PdfColors.grey300),
          boxShadow: [pw.BoxShadow(color: PdfColors.grey300, blurRadius: 8, spreadRadius: 1)],
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header row: Unit + status chip
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(u.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  _statusChip(u.status),
                ],
              ),
              pw.SizedBox(height: 8),
              _priceLine(priceLabel, priceStr),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 4),

              // Aligned key–value info
              _kvTable({
                'Building' : u.buildingName,
                'Type'     : u.flatTypeName,
                'Location' : '${u.areaName}, ${u.stateName}',
                'Parking'  : u.noOfParking.toString(),
                'Bathrooms': u.noOfBathrooms.toString(),
                'Balcony'  : u.amenities.contains('Balcony') ? 'Yes' : 'No',
              }),

              if (u.amenities.isNotEmpty) pw.SizedBox(height: 8),
              if (u.amenities.isNotEmpty)
                pw.Wrap(
                  spacing: 6, runSpacing: 6,
                  children: u.amenities.map((a) => _chip(a)).toList(),
                ),
            ],
          ),
        ),
      );
    }

    pw.Widget _headerBlock() {
      return pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 48,
                height: 48,
                padding: pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.ClipOval(
                  child: pw.Image(logoImage!, fit: pw.BoxFit.cover),
                ),
              ),
            if (logoImage != null) pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Available Units Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(now, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],

            ),
          ],
        ),
      );
    }

    // ---- 5) Build pages (synchronous build; grid via Table to avoid width math) ----
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated on $now', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (pw.Context context) {
          // Build a 2-column grid by chunking units into rows of two
          final rows = <pw.TableRow>[];
          for (int i = 0; i < units.length; i += 2) {
            final left  = _unitCard(units[i]);
            final right = (i + 1 < units.length) ? _unitCard(units[i + 1]) : pw.SizedBox();

            rows.add(
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.only(right: 6, bottom: 12), child: left),
                  pw.Padding(padding: const pw.EdgeInsets.only(left: 6, bottom: 12), child: right),
                ],
              ),
            );
          }

          return [
            _headerBlock(),
            pw.SizedBox(height: 16),
            pw.Table(
              border: null,
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(1),
              },
              children: rows,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> shareUnitsReport(List<Flat> units) async {
    final bytes = await buildModernUnitsPdfBytes(units);

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'units_report.pdf');
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/units_report.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], text: 'Available Units Report');
    }
  }

  Future<void> downloadUnitsReport(List<Flat> units) async {
    final bytes = await buildModernUnitsPdfBytes(units);

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'units_report.pdf');
    } else {
      final docs = await getApplicationDocumentsDirectory();
      final file = File('${docs.path}/units_report.pdf');
      await file.writeAsBytes(bytes, flush: true);
      // Show a toast/snackbar with path if you like
    }
  }

  Future<void> fetchFiltersData() async {
    try {
      final flatTypes = await ApiService().fetchFlatTypes();
      final amenities = await ApiService().fetchAmenities();
      setState(() {
        availableFlatTypes = flatTypes;
        availableAmenities = amenities;
      });
    } catch (e) {
      print("Error fetching filter data: $e");
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      applyFilters(); // 🔁 call combined filter
    });
  }

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _refresh() async {
    setState(() {

      fetchFlats();
    });
  }

  void _showFiltersDialog(BuildContext context) {

    List<String> tempFlatTypes = List.from(selectedFlatTypes);
    List<String> tempAmenities = [...selectedAmenities];
    RangeValues tempPriceRange = selectedPriceRange;
    bool tempIsPriceModified = isPriceRangeModified;
    String tempStatus = statusFilter; // put this near your other temp vars

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<String> flatTypes = availableFlatTypes;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Filters", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),

                  SizedBox(height: 20),


// Inside the Column children (at the top, after "Filters" title):
                SizedBox(height: 12),


            Align(
            alignment: Alignment.centerLeft,
            child:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Category", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),

                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: ["All", "Rent", "Buy"].map((s) {
                    final selected = tempStatus == s;
                    return ChoiceChip(
                      checkmarkColor: Colors.white,

                      label: Text(s, style: GoogleFonts.poppins(color: selected ? Colors.white : Colors.black87)),
                      selected: selected,
                      selectedColor: appbar_color,
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (_) => setModalState(() => tempStatus = s),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
              ],
            ),),

            SizedBox(height: 16),


            SizedBox(height: 16),

            // Flat Type
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Unit Type(s)",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: flatTypes.map((type) {
                            final isSelected = tempFlatTypes.contains(type);
                            return FilterChip(
                              label: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: appbar_color,
                              backgroundColor: Colors.grey.shade200,
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                      tempFlatTypes.add(type);

                                  } else {
                                    tempFlatTypes.remove(type);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Price Range (fields + slider)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Range", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                          /*const SizedBox(width: 4),
                          Image.asset('assets/dirham.png', width: 16, height: 16, fit: BoxFit.contain),*/
                        ],
                      ),
                      const SizedBox(height: 10),

                      // === NEW: two fields for min/max ===
                      Builder(builder: (context) {
                        // Keep controllers inside the StatefulBuilder scope
                        final minFmt = NumberFormat.decimalPattern(); // intl already imported
                        final maxFmt = NumberFormat.decimalPattern();

                        // initialize controllers based on the temp range
                        final TextEditingController minCtl = TextEditingController(
                          text: tempPriceRange.start.round().toString(),
                        );
                        final TextEditingController maxCtl = TextEditingController(
                          text: tempPriceRange.end.round().toString(),
                        );

                        // small helper to parse & clamp and keep min<=max
                        void _applyFromFields({bool fromMin = false, bool fromMax = false}) {
                          // parse
                          int? minVal = int.tryParse(minCtl.text.replaceAll(',', '').trim());
                          int? maxVal = int.tryParse(maxCtl.text.replaceAll(',', '').trim());

                          // fallback to current values if parse fails
                          double currentMin = tempPriceRange.start;
                          double currentMax = tempPriceRange.end;

                          double newMin = (minVal ?? currentMin.toInt()).toDouble();
                          double newMax = (maxVal ?? currentMax.toInt()).toDouble();

                          // clamp to slider bounds
                          newMin = newMin.clamp(rangeMin, rangeMax);
                          newMax = newMax.clamp(rangeMin, rangeMax);

                          // ensure min <= max
                          if (newMin > newMax) {
                            if (fromMin) newMax = newMin;
                            if (fromMax) newMin = newMax;
                          }

                          setModalState(() {
                            tempPriceRange = RangeValues(newMin, newMax);
                            tempIsPriceModified = true;

                            // reformat text with grouping
                            minCtl.text = minFmt.format(newMin.round());
                            maxCtl.text = maxFmt.format(newMax.round());

                            // move cursor to end
                            minCtl.selection = TextSelection.fromPosition(TextPosition(offset: minCtl.text.length));
                            maxCtl.selection = TextSelection.fromPosition(TextPosition(offset: maxCtl.text.length));
                          });
                        }

                        InputDecoration _dec(String label) => InputDecoration(
                          labelText: label,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Image.asset('assets/dirham.png', width: 16, height: 16, fit: BoxFit.contain),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2), // 👈 normal border
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: appbar_color, width: 1.8), // 👈 selected border
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        );


                        return Row(
                          children: [
                            // Min field
                            Expanded(
                              child: TextField(
                                controller: minCtl,
                                keyboardType: TextInputType.number,
                                decoration: _dec("Min"),
                                onChanged: (_) => _applyFromFields(fromMin: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Max field
                            Expanded(
                              child: TextField(
                                controller: maxCtl,
                                keyboardType: TextInputType.number,
                                decoration: _dec("Max"),
                                onChanged: (_) => _applyFromFields(fromMax: true),
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 12),

                      // === Slider ===
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: appbar_color,
                          inactiveTrackColor: Colors.grey.shade300,
                          thumbColor: appbar_color,
                          overlayColor: appbar_color.withOpacity(0.2),
                          valueIndicatorColor: appbar_color,
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                          rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                          rangeThumbShape: const RoundRangeSliderThumbShape(),
                        ),
                        child: RangeSlider(
                          values: tempPriceRange,
                          min: rangeMin,
                          max: rangeMax,
                          divisions: 100,
                          labels: RangeLabels(
                            tempPriceRange.start.round().toString(),
                            tempPriceRange.end.round().toString(),
                          ),
                          onChanged: (range) {
                            setModalState(() {
                              tempPriceRange = range;
                              tempIsPriceModified = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),


                  SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                    Text("Amenities", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),

                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: availableAmenities.map((amenity) {
                        final isSelected = tempAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(
                            amenity,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: appbar_color,
                          backgroundColor: Colors.grey.shade200,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              selected
                                  ? tempAmenities.add(amenity)
                                  : tempAmenities.remove(amenity);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔁 Reset Button - Styled Outlined
                      OutlinedButton.icon(
                        onPressed: () {

                          setModalState(() {
                            tempStatus = "All"; // ✅ reset category too
                            tempFlatTypes.clear();
                            tempAmenities.clear();
                            tempPriceRange = RangeValues(rangeMin, rangeMax); // shared prefs wala
                            tempIsPriceModified = false;
                            searchQuery = '';
                          });
                        },
                        icon: Icon(Icons.refresh, color: Colors.black87),
                        label: Text(
                          "Reset",
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.black87, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),

                      SizedBox(width: 16), // spacing between buttons

                      // ✅ Apply Filters Button - Styled Elevated
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            statusFilter = tempStatus; // NEW
                            selectedFlatTypes = List.from(tempFlatTypes);
                            selectedAmenities = [...tempAmenities];
                            selectedPriceRange = tempPriceRange;
                            isPriceRangeModified = tempIsPriceModified;
                          });
                          Navigator.pop(context);
                          applyFilters();
                        },
                        icon: Icon(Icons.check, color: Colors.white),
                        label: Text(
                          "Apply Filters",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appbar_color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sortUnitsByFlatType({required bool ascending}) {
    setState(() {
      filteredUnits.sort((a, b) {
        return ascending
            ? a.flatTypeName.toLowerCase().compareTo(b.flatTypeName.toLowerCase())
            : b.flatTypeName.toLowerCase().compareTo(a.flatTypeName.toLowerCase());
      });

      selectedSort = ascending ? "flat_type_az" : "flat_type_za";
      selectedSortLabel = ascending ? "Flat Type: A → Z" : "Flat Type: Z → A";
    });
  }


  void applyFilters() {
    if (allUnits.isEmpty) return;

    List<Flat> filtered = allUnits.where((unit) {
      // ✅ Category filter first
      final statusMatch = (statusFilter == "All") || ((unit.status ?? "") == statusFilter);

      // ✅ Price is dynamic per unit
      final price = _currentPrice(unit);

      // ✅ Other filters
      final flatTypeMatch = selectedFlatTypes.isEmpty || selectedFlatTypes.contains(unit.flatTypeName);

      final priceMatch = !isPriceRangeModified ||
          (price != null &&
              price >= selectedPriceRange.start &&
              price <= selectedPriceRange.end);

      final amenitiesMatch = selectedAmenities.every((a) => unit.amenities.contains(a));

      return statusMatch && flatTypeMatch && priceMatch && amenitiesMatch; // <-- include statusMatch
    }).toList();

    if (searchQuery.trim().isNotEmpty) {
      filtered = filtered.where((unit) =>
      unit.flatTypeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          unit.buildingName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          unit.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          unit.areaName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          unit.stateName.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    setState(() => filteredUnits = filtered);
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Sort By",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade300),

              // ✅ Option 1
              ListTile(
                leading: Icon(
                  Icons.arrow_upward,
                  color: selectedSort == "low_to_high" ? appbar_color : Colors.grey,
                ),
                title: Text(
                  "Price: Low to High",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: selectedSort == "low_to_high" ? FontWeight.bold : FontWeight.normal,
                    color: selectedSort == "low_to_high" ? appbar_color : Colors.black87,
                  ),
                ),
                trailing: selectedSort == "low_to_high"
                    ? Icon(Icons.check, color: appbar_color)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _sortUnitsByPrice(ascending: true);
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),

              // ✅ Option 2
              ListTile(
                leading: Icon(
                  Icons.arrow_downward,
                  color: selectedSort == "high_to_low" ? appbar_color : Colors.grey,
                ),
                title: Text(
                  "Price: High to Low",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: selectedSort == "high_to_low" ? FontWeight.bold : FontWeight.normal,
                    color: selectedSort == "high_to_low" ? appbar_color : Colors.black87,
                  ),
                ),
                trailing: selectedSort == "high_to_low"
                    ? Icon(Icons.check, color: appbar_color)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _sortUnitsByPrice(ascending: false);
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),

              // Flat Type: A-Z
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha,
                  color: selectedSort == "flat_type_az" ? appbar_color : Colors.grey,
                ),
                title: Text(
                  "Flat Type: A to Z",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: selectedSort == "flat_type_az" ? FontWeight.bold : FontWeight.normal,
                    color: selectedSort == "flat_type_az" ? appbar_color : Colors.black87,
                  ),
                ),
                trailing: selectedSort == "flat_type_az"
                    ? Icon(Icons.check, color: appbar_color)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _sortUnitsByFlatType(ascending: true);
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),

// Flat Type: Z-A
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha,
                  color: selectedSort == "flat_type_za" ? appbar_color : Colors.grey,
                ),
                title: Text(
                  "Flat Type: Z to A",

                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: selectedSort == "flat_type_za" ? FontWeight.bold : FontWeight.normal,
                    color: selectedSort == "flat_type_za" ? appbar_color : Colors.black87,
                  ),
                ),
                trailing: selectedSort == "flat_type_za"
                    ? Icon(Icons.check, color: appbar_color)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _sortUnitsByFlatType(ascending: false);
                },
              ),

            ],
          ),
        );
      },
    );
  }

// 1) Price chosen for SORT, based on the statusFilter
  int? _priceForSort(Flat u) {
    final sel = (statusFilter).trim().toLowerCase();
    if (sel == 'rent') return u.basicRent;           // only rent price matters
    if (sel == 'buy')  return u.basicSaleValue;      // only sale value matters
    // "All" → use dynamic price based on the unit's own status
    return _currentPrice(u);
  }

// 2) Null-safe compare with "nulls last"
  int _compareSortPrice(Flat a, Flat b, {required bool ascending}) {
    final pa = _priceForSort(a);
    final pb = _priceForSort(b);

    if (pa == null && pb == null) {
      // tie-breaker for stability when both are null (optional)
      return a.id.compareTo(b.id);
    }
    if (pa == null) return 1;   // a after b
    if (pb == null) return -1;  // b after a

    final cmp = pa.compareTo(pb);
    return ascending ? cmp : -cmp;
  }

// 3) Public sorter: strictly by price according to statusFilter
  void _sortUnitsByPrice({required bool ascending}) {
    setState(() {
      // Pure price sort (no "best price" boost, no badge-based logic)
      filteredUnits.sort((a, b) => _compareSortPrice(a, b, ascending: ascending));

      selectedSort = ascending ? "low_to_high" : "high_to_low";
      selectedSortLabel = ascending ? "Price: Low → High" : "Price: High → Low";
    });
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:  Colors.white,
        appBar: AppBar(

          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: "Share",
              onPressed: () async => await shareUnitsReport(filteredUnits),
            ),
            // Optional: direct download/save
             IconButton(
               icon: const Icon(Icons.download, color: Colors.white),
               tooltip: "Download PDF",
              onPressed: () async => await downloadUnitsReport(filteredUnits),
             ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  onChanged: _updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          title: Text(
            'Available Units',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: appbar_color.withOpacity(0.9),
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: GestureDetector(
            onTap: ()
            {
              Navigator.of(context).pop();

            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),),

        ),

        drawer: Sidebar(
          isDashEnable: isDashEnable,
          isRolesVisible: isRolesVisible,
          isRolesEnable: isRolesEnable,
          isUserEnable: isUserEnable,
          isUserVisible: isUserVisible,
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: isLoading
              ? Center(
            child: Platform.isIOS
                ? const CupertinoActivityIndicator(radius: 15.0)
                : CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(appbar_color),
              strokeWidth: 4.0,
            ),
          )
          : Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(0, 4),
                        )
                      ],
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔘 FILTER SECTION
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Filter Button
                            TextButton.icon(
                              onPressed: () => _showFiltersDialog(context),
                              icon: Icon(Icons.filter_list, color: appbar_color),
                              label: Text(
                                "Filters",
                                style: GoogleFonts.poppins(
                                  color: appbar_color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: appbar_color,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.grey.shade300), // 🔲 Add black border here
                                ),
                                backgroundColor: Colors.grey.shade100,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // NEW — always show current Status as a tappable badge
                            _buildBadgeChip(
                              Icons.assignment_turned_in_outlined,
                              "Category: $statusFilter",
                              onTap: () => _showFiltersDialog(context),
                            ),
                            const SizedBox(width: 10),


                            // 🔘 FILTER BADGES (right of Filter button)
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: (
                                      selectedFlatTypes.isEmpty &&
                                          selectedAmenities.isEmpty &&
                                          !isPriceRangeModified
                                          ? [
                                        _buildBadgeChip(Icons.info_outline, "No filters selected"),
                                      ] : [

                                        ...selectedFlatTypes.map((type) =>
                                            _buildBadgeChip(Icons.apartment, type, onTap: () => _showFiltersDialog(context))),
                                        ...selectedAmenities.map((a) =>
                                            _buildBadgeChip(Icons.check_circle_outline, a, onTap: () => _showFiltersDialog(context))),

                                        if (isPriceRangeModified)
    GestureDetector(
      onTap: () => _showFiltersDialog(context),
      child: Chip(
        avatar: Icon(Icons.price_change, size: 16, color: appbar_color),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/dirham.png',
              width: 14,
              height: 14,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 4),
            Text(
              "${selectedPriceRange.start.round()} - ${selectedPriceRange.end.round()}",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    ),

                                      ]
                                  ).map((chip) => Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: chip,
                                  )).toList(),
                                )
                        ))]),

                        const SizedBox(height: 8),

                        // 🔘 SORT SECTION
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sort Button
                            TextButton.icon(
                              onPressed: () => _showSortOptions(context),
                              icon: Icon(Icons.sort, color: appbar_color),
                              label: Text(
                                "Sort",
                                style: GoogleFonts.poppins(
                                  color: appbar_color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: appbar_color,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.grey.shade300), // 🔲 Add black border here
                                ),
                                backgroundColor: Colors.grey.shade100,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Always show a sort badge — with default fallback
                            _buildBadgeChip(
                              Icons.sort,
                              selectedSortLabel != null && selectedSortLabel!.isNotEmpty
                                  ? selectedSortLabel!
                                  : "Default (Latest)",
                              onTap: () => _showSortOptions(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                filteredUnits.isEmpty ?
                Expanded(
                  child:  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // center inside column
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No units found",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                ) :
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredUnits.length + (isFetchingMoreFlats ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (isFetchingMoreFlats && index == filteredUnits.length) {
                        return Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(
                            child: Platform.isAndroid
                                ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            )
                                : CupertinoActivityIndicator(radius: 15),
                          ),
                        );
                      }

                      final unit = filteredUnits[index];
                      return _buildModernUnitCard(unit);
                    },
                  ),
                )


              ],
            ),
          ),
            ),

        floatingActionButton: Stack(
          clipBehavior: Clip.none,
          children: [
            // ✅ 1. Expandable FAB (Bottom Right)
            Align(
              alignment: Alignment.bottomRight,
              child: ExpandableFab(appbarColor: appbar_color),
            ),
          ],
        ),
      ),

    );


  }

  Widget _buildModernUnitCard(Flat unit) {
    final price = _currentPrice(unit);
    final isBest = _isBestPriceInFlatType(unit);
    final priceLabel = _priceLabelFor(unit);



    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200.withOpacity(0.4)),
      ),
      child: Stack(
        children: [
          // Main card content
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.home_work_rounded, unit.flatTypeName),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.business, unit.buildingName),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.location_on_rounded, "${unit.areaName}, ${unit.stateName}"),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildPriceChip(price, unit.flatTypeName, priceLabel, isBest: isBest),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AvailableUnitsDialog(
                                unitno: unit.name,
                                area: unit.areaName,
                                status: unit.status ?? "Rent",                        // ✅ NEW
                                emirate: unit.stateName,
                                unittype: unit.flatTypeName,
                                parking: unit.noOfParking.toString(),
                                balcony: unit.amenities.contains("Balcony") ? "Yes" : "No",
                                bathrooms: unit.noOfBathrooms.toString(),
                                building_name: unit.buildingName,
                                ownership: unit.ownership ?? "N/A",
                                basicRent: unit.basicRent?.toString() ?? "N/A",
                                basicSaleValue: unit.basicSaleValue?.toString() ?? "N/A",
                                isExempt: unit.isExempt ? "true" : "false",
                                amenities: unit.amenities,
                              ),
                            );
                          },
                          child: Icon(Icons.info_outline, size: 26, color: appbar_color),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          // Status badge at top right
          Positioned(
            top: 15,
            right: 30,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: unit.status == 'Rent'
                    ? Colors.green.withOpacity(0.1)
                    : unit.status == 'Buy'
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: unit.status == 'Rent'
                      ? Colors.green
                      : unit.status == 'Buy'
                      ? Colors.blue
                      : Colors.grey,
                  width: 1,
                ),
              ),
              child: Text(
                unit.status
                    ?? 'Unknown',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: unit.status == 'Rent'
                      ? Colors.green
                      : unit.status == 'Buy'
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: appbar_color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

}

Widget buildPriceChip(int? price, String? flattype, String priceLabel, {bool isBest = false}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      if (price != null)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              /*Text("$priceLabel: ", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(width: 2),*/
              Image.asset('assets/dirham.png', width: 14, height: 14, fit: BoxFit.contain),
              const SizedBox(width: 4),
              Text(
                "$price",
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      if (isBest)
        Positioned(
          top: -18,
          left: -5,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.shade400, borderRadius: BorderRadius.circular(12)),
            child: Text(
              "Best $priceLabel for $flattype",
              style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ),
    ],
  );
}


class AvailableUnitsDialog extends StatelessWidget {
  final String unitno;
  final String building_name;
  final String area;
  final String emirate;
  final String unittype;

  // REMOVE: final String rent;  // ❌ not needed now
  final String parking;
  final String balcony;
  final String bathrooms;

  // ✅ New / existing fields
  final String status;           // ✅ NEW: "Rent" | "Buy"
  final String ownership;
  final String basicRent;        // keep as String since you pass String
  final String basicSaleValue;   // keep as String since you pass String
  final String isExempt;
  final List<String> amenities;

  const AvailableUnitsDialog({
    Key? key,
    required this.unitno,
    required this.area,
    required this.building_name,
    required this.emirate,
    required this.unittype,
    // required this.rent,        // ❌ remove
    required this.parking,
    required this.balcony,
    required this.bathrooms,
    required this.status,        // ✅ NEW
    required this.ownership,
    required this.basicRent,
    required this.basicSaleValue,
    required this.isExempt,
    required this.amenities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double maxDialogHeight = screenHeight * 0.8;
// 🔽 compute dynamic label + value
    final String priceLabel = (status == "Buy") ? "Price" : "Rent";
    // Prefer sale value for Buy; rent for Rent. Fallback to "N/A" if empty.
    final String priceValueRaw = (status == "Buy") ? basicSaleValue : basicRent;
    final String priceValue = (priceValueRaw.isNotEmpty && priceValueRaw != "null") ? priceValueRaw : "N/A";


    final priceTile = Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.attach_money, color: appbar_color.shade200),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // dynamic label here
                Text(
                  "$priceLabel",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Image.asset(
                      'assets/dirham.png',
                      width: 14,
                      height: 14,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      priceValue, // dynamic value here
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      elevation: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxDialogHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [appbar_color.shade200, appbar_color.shade400],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Icon(Icons.home, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "$unitno",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),

                // Scrollable Details
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailTile(Icons.apartment, "Unit Type", unittype),
                        _buildDetailTile(Icons.business, "Building", building_name),
                        _buildDetailTile(Icons.location_on, "Location", "$area, $emirate"),
                        priceTile, // <-- use dynamic price tile here

                        // _buildDetailTile(Icons.attach_money, "Price", rent),
                        _buildDetailTile(Icons.local_parking, "Parking", parking),
                        _buildDetailTile(Icons.balcony, "Balcony", balcony),
                        _buildDetailTile(Icons.bathtub, "Bathrooms", bathrooms),

                        // ✅ New fields
                        if (amenities.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                            color: Colors.white,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.checklist, color: appbar_color.shade200),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Amenities",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: amenities.map((amenity) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 2,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              amenity,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                      ],
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // Close Button
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      "Close",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Detail Tile Widget
  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      color: Colors.white,
      child: Row(
        children: [
          Icon(icon, color: appbar_color.shade200),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ApiService {

  Future<List<String>> fetchFlatTypes() async {
    final response = await http.get(
      Uri.parse("$baseurl/master/flatType"),
      headers: {
        "Authorization": "Bearer $Company_Token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> flatTypeList = jsonData["data"]["flatTypes"];

      return flatTypeList.map((e) => e["name"].toString()).toList();
    } else {
      throw Exception("Failed to load flat types");
    }
  }

  Future<List<String>> fetchAmenities() async {
    final response = await http.get(
      Uri.parse("$baseurl/lead/amenity"),
      headers: {
        "Authorization": "Bearer $Company_Token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> amenitiesList = jsonData["data"]["amenities"];

      return amenitiesList.map((e) => e["name"].toString()).toList();
    } else {
      throw Exception("Failed to load amenities");
    }
  }
}

class Flat {
  final int id;
  final String name;
  final String? grossArea;
  final String buildingName;
  final String floorName;
  final String flatTypeName;
  final String areaName;
  final String stateName;
  final String countryName;
  final String createdAt;
  final int noOfBathrooms;
  final int noOfParking;
  final String? status;

  // New fields
  final String? ownership;
  final int? basicRent;
  final int? basicSaleValue;
  final bool isExempt;
  final int? companyId;
  final int? buildingId;
  final int? floorId;
  final int? flatTypeId;

  final List<String> amenities;

  Flat({
    required this.id,
    required this.name,
    this.grossArea,
    required this.buildingName,
    required this.floorName,
    required this.flatTypeName,
    required this.areaName,
    required this.stateName,
    required this.countryName,
    required this.createdAt,
    required this.noOfBathrooms,
    required this.noOfParking,
    this.ownership,
    this.status,

    this.basicRent,
    this.basicSaleValue,
    required this.isExempt,
    this.companyId,
    this.buildingId,
    this.floorId,
    this.flatTypeId,
    required this.amenities,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json["id"],
      name: json["name"],
      grossArea: json["gross_area_in_sqft"]?.toString(),
      buildingName: json["building"]["name"],
      floorName: json["floors"]["name"],
      flatTypeName: json["flat_type"]["name"],
      areaName: json["building"]["area"]["name"],
      stateName: json["building"]["area"]["state"]["name"],
      countryName: json["building"]["area"]["state"]["country"]["name"],
      createdAt: json["created_at"],
      status :json['status'] ?? "",


      ownership: json["ownership"],
      basicRent: json["basic_rent"],
      basicSaleValue: json["basic_sale_value"],
      isExempt: json["is_exempt"]?.toString() == "true",
      noOfBathrooms: json["no_of_bathrooms"] ?? 0,
      noOfParking: json["no_of_parkings"] ?? 0,
      companyId: json["company_id"],
      buildingId: json["building_id"],
      floorId: json["floor_id"],
      flatTypeId: json["flat_type_id"],

      amenities: (json["amenities"] as List<dynamic>?)
          ?.map((e) => e["amenity"]["name"].toString())
          .toList() ??
          [],
    );
  }
}

class ExpandableFab extends StatefulWidget {
  final Color appbarColor;

  const ExpandableFab({Key? key, required this.appbarColor}) : super(key: key);

  @override
  _ExpandableFabState createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _toggleFab() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double radius = _isExpanded ? 100 : 0; // Distance from main button when expanded
    List<Widget> fabButtons = [];

    // Define the buttons with angles for circular expansion
    List<Map<String, dynamic>> actions = [
      {"icon": FontAwesomeIcons.whatsapp, "color": [Color(0xFF11998E), Color(0xFF38EF7D)], "action": "https://wa.me/$whatsapp_no"},
      {"icon": Icons.phone, "color": [Color(0xFF0575E6), Color(0xFF021B79)], "action": "tel:$phone"},
      {"icon": Icons.email, "color": [Color(0xFF0575E6), Color(0xFF26D0CE)], "action": "mailto:$email"},
    ];

    for (int i = 0; i < actions.length; i++) {
      double angle = (pi / 4) * i; // Adjust the angle for circular positioning
      double dx = radius * cos(angle);
      double dy = radius * sin(angle);

      fabButtons.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          right: 20 + dx,
          bottom: 20 + dy,
          child: Visibility(
            visible: _isExpanded,
            child: SizedBox(
              width: 65,
              height: 65,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: actions[i]["color"],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: "fab_${actions[i]["icon"]}",
                  backgroundColor: Colors.transparent,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(actions[i]["icon"], color: Colors.white, size: 30),
                  onPressed: () async {
                    String actionUrl = actions[i]["action"];
                    if (await canLaunchUrl(Uri.parse(actionUrl))) {
                      await launchUrl(Uri.parse(actionUrl), mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Could not open ${actions[i]["action"]}")),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ...fabButtons, // Adding all floating buttons dynamically in a curve

        // Main Floating Button
        Positioned(
          bottom: 20,
          right: 20,
          child: GestureDetector(
            onTap: _toggleFab,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isExpanded ? 70 : 62,
              height: _isExpanded ? 70 : 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isExpanded
                      ? [Color(0xFF232526), Color(0xFF414345)]
                      : [Color(0xFF0575E6), appbar_color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isExpanded
                        ? Colors.black26.withOpacity(0.5)
                        : widget.appbarColor.withOpacity(0.4),
                    blurRadius: _isExpanded ? 25 : 15,
                    spreadRadius: _isExpanded ? 4 : 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: FloatingActionButton(
                heroTag: "main_button",
                backgroundColor: Colors.transparent,
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isExpanded
                      ? const Icon(Icons.close, color: Colors.white, size: 30)
                      : const Icon(Icons.more_vert, color: Colors.white, size: 34),
                ),
                onPressed: _toggleFab,
              ))))]);}
}

Widget _buildBadgeChip(IconData icon, String label, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Chip(
      avatar: Icon(icon, size: 16, color: appbar_color),
      label: SingleChildScrollView(scrollDirection: Axis.horizontal,
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      ),),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}

