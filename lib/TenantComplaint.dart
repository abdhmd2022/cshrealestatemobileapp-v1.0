import 'dart:io';
import 'package:cshrealestatemobile/ComplaintList.dart';
import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert'; // for jsonDecode
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'Sidebar.dart';

class TenantComplaint extends StatefulWidget
{
  const TenantComplaint({Key? key}) : super(key: key);
  @override
  _TenantComplaintPageState createState() => _TenantComplaintPageState();
}

class _TenantComplaintPageState extends State<TenantComplaint> with TickerProviderStateMixin {

  String? selectedType = "";

  final List<String> type_list = [
    'Complaint',
    'Suggestion',
  ];

  TextEditingController _descriptionController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSubmitting = false;

  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoRoleFound = false;

  String name = "",email = "";

  bool selectAll = false;
  final _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }


  Future<void> _submitForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {

        var uuid = Uuid();
        String uuidValue = uuid.v4();
        final response = await http.post(
          Uri.parse('$baseurl/tenant/complaint'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            'Authorization': 'Bearer $Company_Token',
          },
          body: jsonEncode({
            'tenant_id' : user_id,
            'status_id':1,

            'uuid':uuidValue,
            'type': selectedType,
            'description': _descriptionController.text.trim(),
          }),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201 || responseData['success'] == true) {



          // Reset form
          setState(() {
            selectedType = "";
            _descriptionController.clear();
          });
        } else {
          String error = responseData['message'] ?? 'Something went wrong';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }

        showResponseSnackbar(context, responseData);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _initSharedPreferences() async {
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: appbar_color.withOpacity(0.9),
          automaticallyImplyLeading: false,
          leading: GestureDetector(
            onTap: ()
            {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ComplaintListScreen()),
              );
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),),

          title: Text('Complaint/Suggestions',
            style: GoogleFonts.poppins(
                color: Colors.white
            ),),
        ),

        drawer: Sidebar(
            isDashEnable: isDashEnable,
            isRolesVisible: isRolesVisible,
            isRolesEnable: isRolesEnable,
            isUserEnable: isUserEnable,
            isUserVisible: isUserVisible,
            ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Container(
          color: Colors.white,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Dropdown
                Text.rich(
                  TextSpan(
                    text: 'Type',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType!.isNotEmpty ? selectedType : null,
                  hint: Text('Select Type'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: type_list.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Type is required' : null,
                ),

                SizedBox(height: 25),

                // Description Field
                Text.rich(
                  TextSpan(
                    text: 'Description',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,

                  maxLength: 500,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Description is required' : null,
                  decoration: InputDecoration(
                    hintText: 'Enter your complaint or suggestion...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appbar_color),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(fontSize: 15),
                ),

                SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isSubmitting
                        ? Platform.isIOS
                        ? CupertinoActivityIndicator(color: Colors.white)
                        : SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )

                        : Icon(Icons.send_rounded,color:Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    onPressed: _isSubmitting ? null : _submitForm,


                  label: _isSubmitting
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Text(
                          'Submitting...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                        : Text(
                      'Submit',
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

    );}}
