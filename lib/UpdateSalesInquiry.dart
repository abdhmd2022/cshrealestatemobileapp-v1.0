import 'package:cshrealestatemobile/SalesInquiryReport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'constants.dart';

class UpdateInquiryScreen extends StatefulWidget {
  final String name;

  final String contactno;
  final String whatsapp_no;

  final String email;
  final String id;
  final String property_type;
  final String interest_type;

  const UpdateInquiryScreen({
    Key? key,
    required this.name,

    required this.contactno,
    required this.email,
    required this.id,
    required this.whatsapp_no,
    required this.property_type,
    required this.interest_type,

  }) : super(key: key);

  @override
  State<UpdateInquiryScreen> createState() => _UpdateInquiryScreenState();
}

class _UpdateInquiryScreenState extends State<UpdateInquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController = TextEditingController();
  late TextEditingController phoneController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController whatsappController = TextEditingController();

  int selectedInterestType = 0; // 0 = Rent, 1 = Buy
  String? selectedPropertyType;
  final List<String> propertyTypes = ["Residential", "Commercial"];

  bool _useContactAsWhatsapp = false;

  String _selectedCountryCode = "+971"; // Default UAE
  String _selectedCountryFlag = "🇦🇪";

  String _selectedCountryCodeWhatsapp = "+971";
  String _selectedCountryFlagWhatsapp = "🇦🇪";
  bool _isSubmittingInquiry = false;


  Future<void> updateInquiry({
    required String id,
    required String name,
    required String contactno,
    required String whatsappNo,
    required String email,
    required String interestType,   // "Rent" or "Buy"
    required String propertyType,   // "Residential" / "Commercial"
  }) async {
    final url = Uri.parse("$baseurl/lead/$id"); // replace with your API

    try {
      var uuid = Uuid();

      String uuidValue = uuid.v4();

      dynamic body = jsonEncode({
      "uuid": uuidValue,
      "id": id,
      "name": name,
      "mobile_no": contactno,
      "whatsapp_no": whatsappNo,
      "email": email,
      "interest_type": interestType,   // match API field name
      "property_type": propertyType,   // match API field name

      });

      print(body);

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Company_Token", // if token required
        },
          body:body
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Inquiry updated successfully: $data");
      } else {
        print("❌ Failed to update inquiry: ${response.body}");
        throw Exception("Failed to update inquiry");
      }
    } catch (e) {

      print("⚠️ Error updating inquiry: $e");
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);

    // Don’t set phoneController directly with widget.contactno
    // Instead split it
    _splitPhone(widget.contactno, isWhatsapp: false);

    // WhatsApp
    if (widget.whatsapp_no == widget.contactno) {
      _useContactAsWhatsapp = true;
      whatsappController = TextEditingController(text: phoneController.text);
      _selectedCountryCodeWhatsapp = _selectedCountryCode;
      _selectedCountryFlagWhatsapp = _selectedCountryFlag;
    } else {
      _splitPhone(widget.whatsapp_no, isWhatsapp: true);
    }

    // Interest type preload
    selectedInterestType =
    widget.interest_type.toLowerCase() == "buy" ? 1 : 0;

    // Property type preload
    if (propertyTypes.contains(widget.property_type)) {
      selectedPropertyType = widget.property_type;
    }
  }

  /// Helper function to split code and number dynamically
  void _splitPhone(String fullNumber, {required bool isWhatsapp}) {
    if (fullNumber.startsWith("+")) {
      final cleaned = fullNumber.replaceAll(RegExp(r'[^0-9]'), '');

      // match against country list from package
      for (final country in CountryService().getAll()) {
        if (cleaned.startsWith(country.phoneCode)) {
          final code = "+${country.phoneCode}";
          final flag = country.flagEmoji;

          final localNumber = cleaned.substring(country.phoneCode.length);

          if (isWhatsapp) {
            _selectedCountryCodeWhatsapp = code;
            _selectedCountryFlagWhatsapp = flag;
            whatsappController = TextEditingController(text: localNumber);
          } else {
            _selectedCountryCode = code;
            _selectedCountryFlag = flag;
            phoneController = TextEditingController(text: localNumber);
          }
          return;
        }
      }
    }

    // fallback → if nothing matched
    if (isWhatsapp) {
      whatsappController = TextEditingController(text: fullNumber);
    } else {
      phoneController = TextEditingController(text: fullNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        leading: GestureDetector(
          onTap: () =>{
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(
          builder: (context) => SalesInquiryReport()
          )
          ),

          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text("Update Inquiry",
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Interest Type
                Padding(
                  padding: const EdgeInsets.only(
                      top: 10, left: 20, right: 20, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Interest Type:",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 2),
                          Text('*',
                              style: GoogleFonts.poppins(
                                  fontSize: 20, color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "Rent",
                            style: GoogleFonts.poppins(
                              color: selectedInterestType == 0
                                  ? appbar_color
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          FlutterSwitch(
                            width: 60,
                            height: 30,
                            toggleSize: 20,
                            borderRadius: 20,
                            activeColor: appbar_color.shade200,
                            inactiveColor: appbar_color.shade200,
                            value: selectedInterestType == 1,
                            onToggle: (val) {
                              setState(() {
                                selectedInterestType = val ? 1 : 0;
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Buy",
                            style: GoogleFonts.poppins(
                              color: selectedInterestType == 1
                                  ? appbar_color
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// Property Type
                Padding(
                  padding: const EdgeInsets.only(
                      left: 20.0, right: 20, top: 8, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Property Type:",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 2),
                          Text('*',
                              style: GoogleFonts.poppins(
                                  fontSize: 20, color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: propertyTypes.map((type) {
                          final isSelected = selectedPropertyType == type;
                          return ChoiceChip(
                            label: Column(
                              children: [
                                Icon(
                                  type == "Residential"
                                      ? Icons.home
                                      : Icons.business,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  type,
                                  style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: appbar_color.shade400,
                            onSelected: (sel) {
                              setState(() {
                                selectedPropertyType =
                                sel ? type : null;
                              });
                            },
                            showCheckmark: false,
                            backgroundColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                /// Name
                Padding(
                  padding: const EdgeInsets.only(
                      top: 10, left: 20, right: 20, bottom: 0),
                  child: TextFormField(
                    controller: nameController,
                    keyboardType: TextInputType.name,
                    validator: (val) =>
                    val == null || val.isEmpty ? "Name is required" : null,
                    decoration: InputDecoration(
                      hintText: 'Enter Name',
                      label: const Text("Name"),
                      contentPadding: const EdgeInsets.all(15),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: appbar_color)),
                    ),
                  ),
                ),

                /// Email
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20, left: 20, right: 20, bottom: 0),
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Email is required";
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(val)) return "Enter valid email";
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter Email Address',
                      label: const Text("Email Address"),
                      contentPadding: const EdgeInsets.all(15),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: appbar_color)),
                    ),
                  ),
                ),

                /// Phone No.
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20, left: 20, right: 20, bottom: 0),
                  child: TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                    val == null || val.isEmpty ? "Contact No. is required" : null,
                    decoration: InputDecoration(
                      hintText: 'Enter Contact No.',
                      label: const Text("Contact No"),
                      contentPadding: const EdgeInsets.all(15),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: appbar_color)),
                      prefixIcon: GestureDetector(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: true,
                            onSelect: (Country country) {
                              setState(() {
                                _selectedCountryCode = '+${country.phoneCode}';
                                _selectedCountryFlag = country.flagEmoji;
                              });
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedCountryFlag,
                                  style: GoogleFonts.poppins(fontSize: 18)),
                              const SizedBox(width: 5),
                              Text(_selectedCountryCode,
                                  style: GoogleFonts.poppins(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _useContactAsWhatsapp = !_useContactAsWhatsapp;
                            if (_useContactAsWhatsapp) {
                              whatsappController.text = phoneController.text;
                              _selectedCountryCodeWhatsapp = _selectedCountryCode;
                              _selectedCountryFlagWhatsapp = _selectedCountryFlag;
                            } else {
                              whatsappController.clear();
                            }
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: _useContactAsWhatsapp
                                        ? appbar_color
                                        : Colors.black,
                                    width: 1),
                                color: _useContactAsWhatsapp
                                    ? appbar_color
                                    : Colors.transparent,
                              ),
                              child: _useContactAsWhatsapp
                                  ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            const Icon(FontAwesomeIcons.whatsapp,
                                color: Colors.green),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (_useContactAsWhatsapp) {
                        setState(() {
                          whatsappController.text = val;
                          _selectedCountryCodeWhatsapp = _selectedCountryCode;
                          _selectedCountryFlagWhatsapp = _selectedCountryFlag;
                        });
                      }
                    },
                  ),
                ),

                /// WhatsApp No. (if not auto-filled)
                if (!_useContactAsWhatsapp)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 20, left: 20, right: 20, bottom: 0),
                    child: TextFormField(
                      controller: whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter WhatsApp No.',
                        label: const Text("WhatsApp No"),
                        contentPadding: const EdgeInsets.all(15),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: appbar_color)),
                        prefixIcon: GestureDetector(
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: true,
                              onSelect: (Country country) {
                                setState(() {
                                  _selectedCountryCodeWhatsapp =
                                  '+${country.phoneCode}';
                                  _selectedCountryFlagWhatsapp =
                                      country.flagEmoji;
                                });
                              },
                            );
                          },
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_selectedCountryFlagWhatsapp,
                                    style: GoogleFonts.poppins(fontSize: 18)),
                                const SizedBox(width: 5),
                                Text(_selectedCountryCodeWhatsapp,
                                    style: GoogleFonts.poppins(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                        suffixIcon: const Icon(FontAwesomeIcons.whatsapp,
                            color: Colors.green),
                      ),
                    ),
                  ),



                /// Update Button
                Padding(padding: EdgeInsets.only(left: 20,right: 20,top: 40,bottom: 50),
                  child: Container(
                      child: Row(
                        mainAxisAlignment:MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // Button background color
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // Rounded corners
                                side: BorderSide(
                                  color: Colors.grey, // Border color
                                  width: 0.5, // Border width
                                ),
                              ),
                            ),
                            onPressed: () {
                              setState(() {

                                _formKey.currentState?.reset();

                                selectedInterestType = 0;
                                selectedPropertyType = null;


                                _selectedCountryCode = '+971'; // Default to UAE country code
                                _selectedCountryFlag = '🇦🇪'; // Default UAE flag emoji

                                nameController.clear();
                                phoneController.clear();
                                emailController.clear();
                                whatsappController.clear();

                              });
                            },
                            child: Text('Clear'),
                          ),

                          SizedBox(width: 20,),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appbar_color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                            ),
    onPressed: () async {
    if (_formKey.currentState!.validate()) {
                    final updatedName = nameController.text.trim();
                    final updatedEmail = emailController.text.trim();

                    final updatedInterestType = selectedInterestType == 1 ? "Buy" : "Rent";
                    final updatedPropertyType = selectedPropertyType ?? "";


                    final updatedContact =
                        "$_selectedCountryCode${phoneController.text.trim()}";

                    final updatedWhatsapp = _useContactAsWhatsapp
                        ? updatedContact
                        : "$_selectedCountryCodeWhatsapp${whatsappController.text.trim()}";



                    try {
                    await updateInquiry(
                    id: widget.id,
                    name: updatedName,
                    contactno: updatedContact,
                    whatsappNo: updatedWhatsapp,
                    email: updatedEmail,
                    interestType: updatedInterestType,
                    propertyType: updatedPropertyType,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                    content: Text("Inquiry updated successfully"),
                    backgroundColor: Colors.green,
                    ),
                    );
                    Navigator.pop(context);

                    } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Text("Update failed: $e"),
                    backgroundColor: Colors.red,
                    ),
                    );
                    }
                    }
                    },
    child: _isSubmittingInquiry
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text('Update'),
                          ),

                        ],)
                  ),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
