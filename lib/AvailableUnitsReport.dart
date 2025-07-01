import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
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

  Future<void> fetchFlats() async {
    setState(() {
      isLoading = true;
      allUnits.clear(); // Reset on fresh load
    });

    List<Flat> combinedFlats = [];

    try {
      // Helper to fetch flats by status
      Future<void> fetchByStatus(String status) async {
        int currentPage = 1;

        while (true) {
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

            // Show error snackbar
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

          if (flatsJson.isEmpty) break; // No more data

          combinedFlats.addAll(flatsJson.map((json) => Flat.fromJson(json)));

          currentPage++;
        }
      }

      await fetchByStatus("Rent");
      await fetchByStatus("Buy");

      setState(() {
        allUnits = combinedFlats.reversed.toList();
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

                  // Flat Type
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Flat Types",
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

                  // Price Range
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Price Range (AED)", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: appbar_color,             // ✅ selected range color
                          inactiveTrackColor: Colors.grey.shade300,   // ✅ unselected range
                          thumbColor: appbar_color,                   // ✅ draggable circle
                          overlayColor: appbar_color.withOpacity(0.2),// ✅ circle glow on press
                          valueIndicatorColor: appbar_color,          // ✅ popup value indicator
                          trackHeight: 4,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                          rangeTrackShape: RoundedRectRangeSliderTrackShape(),
                          rangeThumbShape: RoundRangeSliderThumbShape(),
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
                      )
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
    if (allUnits.isEmpty) {
      print("⚠️ allUnits is empty. Skipping filters.");
      return;
    }

    print("🔥 APPLYING FILTERS 🔥");
    print("Selected flat types: $selectedFlatTypes");
    print("Selected price range: ${selectedPriceRange.start} - ${selectedPriceRange.end}");
    print("Is price range modified: $isPriceRangeModified");
    print("Selected amenities: $selectedAmenities");

    List<Flat> filtered = allUnits.where((unit) {
      final rent = unit.basicRent ?? 0;

      final flatTypeMatch = selectedFlatTypes.isEmpty || selectedFlatTypes.contains(unit.flatTypeName);

      final priceMatch = !isPriceRangeModified ||
          (rent >= selectedPriceRange.start && rent <= selectedPriceRange.end);

      final amenitiesMatch = selectedAmenities.every((a) => unit.amenities.contains(a));

      final finalMatch = flatTypeMatch && priceMatch && amenitiesMatch;

      print("🔎 ${unit.name} → flatTypeMatch: $flatTypeMatch | priceMatch: $priceMatch | rent: $rent | amenitiesMatch: $amenitiesMatch | Final Match: $finalMatch");

      return finalMatch;
    }).toList();

    print("✅ Filtered units before search: ${filtered.length}");

    if (searchQuery.trim().isNotEmpty) {
      filtered = filtered.where((unit) =>
      unit.flatTypeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          unit.buildingName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          unit.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          unit.areaName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          unit.stateName.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();

      print("🔎 Applied search '$searchQuery' → Final count: ${filtered.length}");
    }

    setState(() {
      filteredUnits = filtered;
    });
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

  void _sortUnitsByPrice({required bool ascending}) {
    setState(() {
      filteredUnits.sort((a, b) {
        final aIsBest = _isBestRentInFlatType(a);
        final bIsBest = _isBestRentInFlatType(b);

        if (aIsBest && !bIsBest) return -1;
        if (!aIsBest && bIsBest) return 1;

        int priceA = a.basicRent ?? 0;
        int priceB = b.basicRent ?? 0;
        return ascending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
      });

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
                                          _buildBadgeChip(
                                            Icons.price_change,
                                            "AED ${selectedPriceRange.start.round()} - ${selectedPriceRange.end.round()}",
                                            onTap: () => _showFiltersDialog(context),
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
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!isFetchingMoreFlats &&
                          scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 50) {
                        print("🔄 Re-fetching data on scroll end...");
                        fetchFlats();  // Just re-fetch everything; ideally you'd implement proper page tracking
                      }
                      return false;
                    },
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
                        buildPriceChip(unit.basicRent, unit.flatTypeName, isBest: _isBestRentInFlatType(unit)),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AvailableUnitsDialog(
                                unitno: unit.name,
                                area: unit.areaName,
                                emirate: unit.stateName,
                                unittype: unit.flatTypeName,
                                rent: unit.basicRent != null ? "AED ${unit.basicRent}" : "AED N/A",
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

  bool _isBestRentInFlatType(Flat unit) {
    final type = unit.flatTypeName;

    // Get all units of the same flat type
    final typeUnits = filteredUnits.where((u) => u.flatTypeName == type && u.basicRent != null).toList();

    // If less than 2 units of this type, don't mark any as best (nothing to compare)
    if (typeUnits.length < 2) return false;

    // Find the min rent
    final minRent = typeUnits.map((u) => u.basicRent!).reduce((a, b) => a < b ? a : b);

    // Return true if this unit's rent equals the min
    return unit.basicRent == minRent;
  }


}

Widget buildPriceChip(int? rent,String? flattype, {bool isBest = false}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      // Main chip

      if(rent!=null)
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*Icon(Icons.attach_money, size: 16, color: Colors.black87),
            SizedBox(width: 6),*/

            Text(
              rent != null ? "AED $rent" : "Rent N/A",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),

      // "Best Price" ribbon
      if (isBest)
        Positioned(
          top: -18,
          right: -8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Best Price for $flattype",
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
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
  final String rent;
  final String parking;
  final String balcony;
  final String bathrooms;

  // ✅ New fields
  final String ownership;
  final String basicRent;
  final String basicSaleValue;
  final String isExempt;
  final List<String> amenities;

  const AvailableUnitsDialog({
    Key? key,
    required this.unitno,
    required this.area,
    required this.building_name,
    required this.emirate,
    required this.unittype,
    required this.rent,
    required this.parking,
    required this.balcony,
    required this.bathrooms,
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
                        _buildDetailTile(Icons.attach_money, "Price", rent),
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

Widget _buildDecentButton(
    String label, IconData icon, Color color, VoidCallback onPressed) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(30.0),
    splashColor: color.withOpacity(0.2),
    highlightColor: color.withOpacity(0.1),
    child: Container(
      margin: EdgeInsets.only(top: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        color: Colors.white,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8.0),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
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

// Model Class
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
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}

