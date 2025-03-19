import 'package:cshrealestatemobile/UsersReport.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'constants.dart';
import 'package:google_fonts/google_fonts.dart';

class ModifyUser extends StatefulWidget
{
  const ModifyUser({Key? key}) : super(key: key);
  @override
  _ModifyUserPageState createState() => _ModifyUserPageState();
}

class _ModifyUserPageState extends State<ModifyUser> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoUserFound = false,
      _isFocused_email = false,
      _isFocus_name = false;

  final _formKey = GlobalKey<FormState>();



  List<dynamic> myData_roles = [
    {'role_name': 'Sales'},
    {'role_name': 'Accountant'},
    {'role_name': 'Manager'},
  ];

  dynamic _selectedrole;
  List<String> _selectedCompanies = [];
  List<String> myDataCompanies = [];


  String user_email_fetched = "";

  late final TextEditingController controller_email = TextEditingController();
  late final TextEditingController controller_password = TextEditingController();
  late final TextEditingController controller_name = TextEditingController();

  bool _isFocused_password = false;
  bool _obscureText = true;

  String name = "",email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      _selectedrole = myData_roles.first;

    });


    /*setState(() {
      hostname = prefs.getString('hostname');

      company  = prefs.getString('company_name');
      company_lowercase = company!.replaceAll(' ', '').toLowerCase();
      serial_no = prefs.getString('serial_no');
      username = prefs.getString('username');

      SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

      String? email_nav = prefs.getString('email_nav');
      String? name_nav = prefs.getString('name_nav');

      if (email_nav!=null && name_nav!= null)
      {
        name = name_nav;
        email = email_nav;
      }

      if(SecuritybtnAcessHolder == "True")
      {
        isRolesVisible = true;
        isUserVisible = true;
      }
      else
      {
        isRolesVisible = false;
        isUserVisible = false;
      }
      fetchRoles(serial_no!);
      fetchCompany(serial_no!);
    });*/
  }

  /*Future<void> userRegistration(String selectedserial,String email,String password,String rolename, String name) async {
    setState(() {
      _isLoading = true;
    });

    try
    {
      final url = Uri.parse('$BASE_URL_config/api/login/userRegistration');


      Map<String,String> headers = {
        'Authorization' : 'Bearer $authTokenBase',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        "username": email ,
        "serialno" :selectedserial,
        "password": password,
        "rolename": rolename,
        "name": name,
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        String responsee = response.body;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responsee),
          ),
        );
        if(responsee == "User Registered Successfully")
        {
          addAllowedCompanies(email, serial_no!, _selectedCompanies);

          controller_email.clear();
          controller_name.clear();
          controller_password.clear();
          _selectedrole =   myData_roles[0];
          FocusScope.of(context).unfocus();

        }
        else if (responsee == "No of users exceeded")
        {
          controller_email.clear();
          controller_name.clear();
          controller_password.clear();
          _selectedrole =   myData_roles.first;
          FocusScope.of(context).unfocus();

        }
        else
        {
          controller_email.clear();
          controller_name.clear();
          controller_password.clear();
          _selectedrole =   myData_roles[0];
          FocusScope.of(context).unfocus();
        }
      }
      else
      {
        Map<String, dynamic> data = json.decode(response.body);
        String error = '';

        if (data.containsKey('error')) {
          setState(() {
            error = data['error'];
          });
        }
        else
        {
          error = 'Something went wrong!!!';
        }

        Fluttertoast.showToast(msg: error);

      }
      setState(() {
        _isLoading = false;
      });
    }
    catch (e)
    {print(e);
    setState(() {
      _isLoading = false;
    });}

  }

  Future<void> fetchRoles(String selectedserial) async {
    setState(() {
      _isLoading = true;
    });

    try
    {
      final url = Uri.parse('$BASE_URL_config/api/roles/get');
      Map<String,String> headers = {
        'Authorization' : 'Bearer $authTokenBase',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        'serialno': selectedserial,

      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        myData_roles = jsonDecode(response.body);
        if (myData_roles != null) {
          setState(() {
            _selectedrole = myData_roles.first;
          });



        }
        else
        {
          throw Exception('Failed to fetch data');
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
    catch (e)
    {print(e);
    setState(() {
      _isLoading = false;
    });}
  }

  Future<void> fetchCompany(String selectedserial) async {
    myDataCompanies.clear();
    final url = Uri.parse('$BASE_URL_config/api/admin/getCompany');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': selectedserial
    });

    final response = await http.post(
        url,
        body : body,
        headers : headers
    );

    if (response.statusCode == 200)
    {
      final List<dynamic> responseData = jsonDecode(response.body);
      if (responseData != null) {
        setState(() {
          myDataCompanies = responseData.map<String>((item) {
            return item['company_name'] as String;
          }).toList();
        });
      }
      else
      {

        throw Exception('Failed to fetch data');
      }
      setState(() {
        _isLoading = false;
      });
    }
    else
    {
      Map<String, dynamic> data = json.decode(response.body);
      String error = '';

      if (data.containsKey('error')) {
        setState(() {
          error = data['error'];
        });
      }
      else
      {
        error = 'Something went wrong!!!';
      }
      Fluttertoast.showToast(msg: error);

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> addAllowedCompanies(String email, String serialno, List<String> companies_list) async {
    myDataCompanies.clear();
    final url = Uri.parse('$BASE_URL_config/api/roles/allowed_companies');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    print('$serialno, $email, $companies_list');

    var body = jsonEncode({
      'serial_no': serialno,
      'user_name' : email,
      'companies' : companies_list
    });

    final response = await http.post(
        url,
        body : body,
        headers : headers
    );

    if (response.statusCode == 200)
    {
      print(response.body);
    }
    else
    {
      Map<String, dynamic> data = json.decode(response.body);
      String error = '';

      if (data.containsKey('error')) {
        setState(() {
          error = data['error'];
        });
      }
      else
      {
        error = 'Something went wrong!!!';
      }
      Fluttertoast.showToast(msg: error);

      setState(() {
        _isLoading = false;
      });
    }
  }*/


  /*void _openMultiSelectDialog() async {
    final selectedValues = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Companies'),
          content: StatefulBuilder(
            builder: (context, setState) {
              bool isAllSelected = _selectedCompanies.length == myDataCompanies.length;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All Checkbox
                    CheckboxListTile(
                      title: const Text('Select All'),
                      value: isAllSelected,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            // Select all companies
                            _selectedCompanies = List.from(myDataCompanies);
                          } else {
                            // Deselect all companies
                            _selectedCompanies.clear();
                          }
                        });
                      },
                      activeColor: Colors.teal, // Customize the checkbox color
                    ),
                    const Divider(), // Optional: Separate "Select All" from individual options
                    // Individual Company Checkboxes
                    ...myDataCompanies.map((company) {
                      return CheckboxListTile(
                        title: Text(company),
                        value: _selectedCompanies.contains(company),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedCompanies.add(company);
                            } else {
                              _selectedCompanies.remove(company);
                            }
                          });
                        },
                        activeColor: Colors.teal, // Customize the checkbox color
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null); // Cancel
              },
              child: const Text('Cancel',
                style: GoogleFonts.poppins(
                    color: Colors.black
                ),),

            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedCompanies); // Confirm
              },
              child: const Text('OK',
                  style: GoogleFonts.poppins(
                      color: Colors.black
                  )
              ),
            ),
          ],
        );
      },
    );

    // Update the selected companies if dialog returns valid data
    if (selectedValues != null) {
      setState(() {
        _selectedCompanies = selectedValues;
      });
    }
  }*/


  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }


  bool isValidEmail(String email) {
    // Simple email validation pattern
    final RegExp emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UsersReport()),
        );
        return true;
      },
      child:Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(

          leading: GestureDetector(
            onTap: ()
            {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UsersReport()),
              );
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),),

          title: GestureDetector(
            onTap: () {
              /*Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SerialSelect()),
              );*/
            },
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Modify Users',
                      style: GoogleFonts.poppins(
                          color: Colors.white
                      ),
                      overflow: TextOverflow.ellipsis, // Truncate text if it overflows
                      maxLines: 1, // Display only one line of text
                    ),
                  ),
                  SizedBox(width: 10), // Add some spacing between text and image
                  Icon(

                      Icons.edit,
                      color: appbar_color
                  )
                ],
              ),
            ),
          ),
          backgroundColor: appbar_color,
          automaticallyImplyLeading: false,

        ),
        drawer: Sidebar(
            isDashEnable: isDashEnable,
            isRolesVisible: isRolesVisible,
            isRolesEnable: isRolesEnable,
            isUserEnable: isUserEnable,
            isUserVisible: isUserVisible,
            ),
        body:Stack(
          children: [
            Visibility(
              visible: _isLoading,
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            ),

            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(
                        left: 20,
                        top: 20,
                        right: 30,
                        bottom: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [Text(
                          'User Modification',
                          textAlign: TextAlign.start,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                          SizedBox(height: 5,),
                          Text(
                            'Modify your users for the app',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      )
                  ),

                  Container(

                      height: MediaQuery.of(context).size.height,
                      child:  Form(
                          key: _formKey,
                          child: ListView(
                              children: [
                                Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Name:",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16

                                          )
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        '*', // Red asterisk for required field
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          color: Colors.red, // Red color for the asterisk
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(

                                    padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: controller_name,

                                      keyboardType: TextInputType.name,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Name is required';
                                        }

                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Name',
                                        contentPadding: EdgeInsets.all(15),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Set the border radius
                                          borderSide: BorderSide(
                                            color: Colors.black, // Set the border color
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color:  Colors.black, // Set the focused border color
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocus_name = true;
                                          _isFocused_email = false;
                                          _isFocused_password = false;

                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                          _isFocused_password = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocus_name = true;
                                          _isFocused_email = false;
                                          _isFocused_password = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                          _isFocused_password = false;
                                        });
                                      },

                                    )),

                                Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Email Address:",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16

                                          )
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        '*', // Red asterisk for required field
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          color: Colors.red, // Red color for the asterisk
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(

                                    padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: controller_email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!isValidEmail(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Email Address',
                                        contentPadding: EdgeInsets.all(15),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Set the border radius
                                          borderSide: BorderSide(
                                            color: Colors.black, // Set the border color
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color:  Colors.black, // Set the focused border color

                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocused_email = true;
                                          _isFocus_name = false;
                                          _isFocused_password = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocused_email = false;
                                          _isFocus_name = false;
                                          _isFocused_password = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocused_email = true;
                                          _isFocus_name = false;
                                          _isFocused_password = false;

                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocused_email = false;
                                          _isFocus_name = false;
                                          _isFocused_password = false;
                                        });
                                      },

                                    )),

                                Container(
                                  margin: EdgeInsets.only( top:15,
                                      bottom: 0,
                                      left: 20,
                                      right: 20),
                                  child: Row(
                                    children: [
                                      Text("Password:",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16

                                          )
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        '*', // Red asterisk for required field
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          color: Colors.red, // Red color for the asterisk
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(padding: EdgeInsets.only(top:0,left: 20,right: 20,bottom: 0),

                                    child: TextFormField(
                                      controller: controller_password,
                                      obscureText: _obscureText,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (value.length < 4) {
                                          return 'Password must be at least 4 characters';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Password',
                                        contentPadding: EdgeInsets.all(15),

                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureText ? Icons.visibility_off : Icons.visibility,
                                            color: _isFocused_password ? appbar_color : Colors.black,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureText = !_obscureText;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10), // Set the border radius
                                          borderSide: BorderSide(
                                            color: Colors.black, // Set the border color
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color:  Colors.black, // Set the focused border color
                                          ),
                                        ),
                                        labelStyle: GoogleFonts.poppins(
                                          color: _isFocused_password ? appbar_color : Colors.black,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _isFocused_password = true;
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        setState(() {
                                          _isFocused_password = false;
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isFocused_password = true;
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _isFocused_password = false;
                                          _isFocus_name = false;
                                          _isFocused_email = false;
                                        });
                                      },
                                    )


                                ),

                                Container(
                                  child: Column(

                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(padding: EdgeInsets.only(top: 15,left:20),

                                        child:Row(
                                          children: [
                                            Text("Select Role:",
                                                style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16

                                                )
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              '*', // Red asterisk for required field
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                color: Colors.red, // Red color for the asterisk
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Padding(
                                        padding: EdgeInsets.only(top:0,left:20,right:20,bottom :0),

                                        child: DropdownButtonFormField<dynamic>(
                                          decoration: InputDecoration(

                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.black),
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: appbar_color),
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                              borderSide: BorderSide(color: Colors.black),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                          ),


                                          hint: Text('Role Name'), // Add a hint
                                          value: _selectedrole,
                                          items: myData_roles.map((item) {
                                            return DropdownMenuItem<dynamic>(
                                              value: item,
                                              child: Text(item['role_name']),
                                            );
                                          }).toList(),
                                          onChanged: (value) async {
                                            _selectedrole = value!;
                                          },

                                          onTap: ()
                                          {
                                            setState(() {
                                              _isFocused_email = false;
                                              _isFocus_name = false;
                                              _isFocused_password = false;
                                            });

                                          },
                                        ),
                                      ),

                                      /*Padding(padding: EdgeInsets.only(top: 10,left:20),

                          child:Text(
                            'Allowed Companies',
                            style: GoogleFonts.poppins(

                                fontWeight: FontWeight.bold
                            ),)
                          ,),*/

                                      /* Padding(
                          padding: EdgeInsets.only(top:5,left:20,right:20,bottom :0),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _openMultiSelectDialog,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  child: Text(
                                    _selectedCompanies.isNotEmpty
                                        ? _selectedCompanies.map((e) => e).join('\n')
                                        : 'Tap to select companies',
                                    style: const GoogleFonts.poppins(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),*/
                                    ],
                                  ),
                                ),

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
                                                borderRadius: BorderRadius.circular(5), // Rounded corners
                                                side: BorderSide(
                                                  color: Colors.grey, // Border color
                                                  width: 0.5, // Border width
                                                ),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {

                                                _formKey.currentState?.reset();
                                                _selectedrole = myData_roles.first;

                                                /*print(_selectedrole['role_name']);*/

                                                controller_email.clear();
                                                controller_name.clear();
                                                controller_password.clear();



                                              });
                                            },
                                            child: Text('Clear'),
                                          ),

                                          SizedBox(width: 20,),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: appbar_color, // Button background color
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5), // Rounded corners
                                                side: BorderSide(
                                                  color: Colors.grey, // Border color
                                                  width: 0.5, // Border width
                                                ),
                                              ),
                                            ),
                                            onPressed: () {

                                              if (_formKey.currentState != null &&
                                                  _formKey.currentState!.validate()) {
                                                _formKey.currentState!.save();

                                                String fetched_email = controller_email.text;
                                                String fetched_name = controller_name.text;
                                                String fetched_password = controller_password.text;
                                                String fetched_role = _selectedrole["role_name"];

                                                setState(() {
                                                  _isFocused_email = false;
                                                  _isFocus_name = false;
                                                  _isFocused_password = false;
                                                });
                                                /*userRegistration(serial_no!,fetched_email,fetched_password,fetched_role,fetched_name);*/


                                              }},
                                            child: Text('Modify'),
                                          ),

                                        ],)


                                  ),)

                              ]))
                  )


                ],
              ),)
          ],
        ) ,
      ),
    );
    // TODO: implement build
  }
}