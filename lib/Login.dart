import 'dart:convert';
import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:http/http.dart' as http;
import 'package:cshrealestatemobile/SalesDashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'FlatSelection.dart';
import 'SerialSelect.dart';
import 'constants.dart';
import 'models/serial_model.dart'; // ✅ Import common Serial model


class Login extends StatefulWidget {
  const Login({super.key, required this.title});
  final String title;

  @override
  State<Login> createState() => _LoginPageState();
}



// User Model
class User {
  final int id;
  final String name;
  final String email;
  final String token;
  final int? companyId;
  final String? companyName; // Now added to extract company name


  User({required this.id, required this.name, required this.email, required this.token, this.companyId,    this.companyName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Unknown",
      email: json['email'] ?? "Unknown",
      token: json['token'] ?? "",
      companyId: json['company_id'],
      companyName: json['company'] != null ? json['company']['name'] : "Unknown Company", // Extracts company name correctly

    );
  }
}

class _LoginPageState extends State<Login> {

  bool isVisibleAdminLoginForm= true,_isLoading = false,isButtonDisabled = false;

  Color _buttonColor = appbar_color;

  bool isAdmin = false; // Toggle state


  final _formKey = GlobalKey<FormState>();

  GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final passwordController = TextEditingController();

  dynamic response_login;

  final emailController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscureText = true;

  bool remember_me = true;

  late String email, password;

  final requiredLength = 4; // the required length of the password

  void _onPasswordChanged() {
    // Check the length of the password
    if (passwordController.text.length < requiredLength) {
      // If the password is too short, update the button color to grey
      setState(() {
        _buttonColor = Colors.grey;
        isButtonDisabled = true;
      });
    }
    else
    {
      setState(() {
        _buttonColor = appbar_color;
        isButtonDisabled = false;
      });
    }
  }

  SharedPreferences? prefs;


  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);

    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
     prefs= await SharedPreferences.getInstance();
  }

  Future<void> _adminlogin(String email, String password) async {

        String url = "$BASE_URL_config/v1/auth/login";
    String token = 'Bearer $authTokenBase';

    setState(() => _isLoading = true);
    dynamic responseData;

    try {
      Map<String, String> headers = {
        'Authorization': token,
        "Content-Type": "application/json"
      };

      var body = jsonEncode({'email': email, 'password': password});

      var response = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );
      responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<User> usersList = [];

        print('data ${responseData['data']}');

        if (responseData['data'].containsKey('users')) {
          // Admin case
          usersList = (responseData['data']['users'] as List)
              .map((user) => User.fromJson(user))
              .toList();
        } else if (responseData['data'].containsKey('tenents')) {
          // Tenant case
          usersList = (responseData['data']['tenents'] as List)
              .map((tenant) => User.fromJson(tenant))
              .toList();
        } else {
          throw Exception("Unexpected response format");
        }

        if (usersList.isNotEmpty) {
          User firstUser = usersList[0];

          await prefs.setInt("user_id", firstUser.id);
          await prefs.setString("user_name", firstUser.name);
          await prefs.setString("user_email", firstUser.email);
          await prefs.setString("company_token", firstUser.token);
          await prefs.setInt("company_id", firstUser.companyId ?? 0);
          await prefs.setBool('is_admin', isAdmin==true ? true : false);

          List<Map<String, dynamic>> companiesJson = usersList
              .map((user) => {
            'id': user.companyId ?? 0,
            'name': user.companyName ?? 'Unknown Company', // Use company name
            'token': user.token,
          })
              .toList();

          await prefs.setString("companies_list", jsonEncode(companiesJson));

          loadTokens();

          // Redirect based on user type and company count
          if (usersList.length > 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CompanySelection()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>
              isAdmin ? SalesDashboard() : TenantDashboard()),
            );
          }
        }
      } else {
        throw Exception("Invalid credentials");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${responseData['message'] ?? 'Login failed'}"),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> tenantLogin(String email, String password) async {
    String url = "$BASE_URL_config/v1/auth/tenent/login";
    String token = 'Bearer $authTokenBase';

    setState(() => _isLoading = true);
    dynamic responseData;

    try {
      Map<String, String> headers = {
        'Authorization': token,
        "Content-Type": "application/json"
      };

      var body = jsonEncode({'email': email, 'password': password});
      var response = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );
      responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        List<dynamic> tenantsData = responseData['data']['tenents'] ?? [];

        if (tenantsData.isNotEmpty) {
          var firstTenant = tenantsData[0];

          // ✅ Fetching Tenant Details
          await prefs.setInt("user_id", firstTenant['id']);
          await prefs.setString("user_name", firstTenant['name']);
          await prefs.setString("user_email", firstTenant['email']);
          await prefs.setString("company_token", firstTenant['token']);
          await prefs.setInt("company_id", firstTenant['company_id'] ?? 0);
          await prefs.setBool('is_admin', false);

          // ✅ Extract Flats (Instead of Companies)
          List<Map<String, dynamic>> flatsList = tenantsData.expand((tenant) {
            return ((tenant['flats'] as List<dynamic>? ?? []).map((flatObj) {
              if (flatObj is Map<String, dynamic> && flatObj.containsKey('flat')) {
                var flat = (flatObj['flat'] as Map<dynamic, dynamic>).cast<String, dynamic>();

                return {
                  'id': flat['id'] ?? 0,
                  'name': flat['name'] ?? 'Unknown Flat',
                  'floor': (flat['floor'] as Map?)?.cast<String, dynamic>()['name'] ?? 'Unknown Floor',
                  'flat_type': (flat['flat_type'] as Map?)?.cast<String, dynamic>()['name'] ?? 'Unknown Type',
                  'building': (flat['building'] as Map?)?.cast<String, dynamic>()['name'] ?? 'Unknown Building',
                  'area': (flat['building']?['area'] as Map?)?.cast<String, dynamic>()['name'] ?? 'Unknown Area',
                  'state': (flat['building']?['area']?['state'] as Map?)?.cast<String, dynamic>()['name'] ?? 'Unknown State',
                  'country': (flat['building']?['area']?['state']?['country'] as Map?)?.cast<String, dynamic>()['name'] ?? 'Unknown Country',
                };
              }
              return null; // Instead of an empty map, return null to filter out later
            }).where((flat) => flat != null).cast<Map<String, dynamic>>()).toList();
          }).toList();

          await prefs.setString("flats_list", jsonEncode(flatsList));

          loadTokens();

          // ✅ Redirect to Flat Selection if multiple flats exist
          if (flatsList.length > 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CompanySelection()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TenantDashboard()),
            );
          }
        } else {
          throw Exception("No tenant data found.");
        }
      } else {
        throw Exception("Invalid credentials");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${responseData['message'] ?? 'Login failed'}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void loginUser(String email, String password, bool isAdmin) {
    if (isAdmin) {
      _adminlogin(email, password).then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CompanySelection()),
        );
      });
    } else {
      tenantLogin(email, password).then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FlatSelection()),
        );
      });
    }
  }




  /*Future<void> _adminlogin(String email, String password) async {

    String url = isAdmin ? "$BASE_URL_config/v1/auth/login" : "$BASE_URL_config/v1/auth/tenet/login";

    String token = 'Bearer $authTokenBase';

    setState(() {
      _isLoading = true;
    });


    try {
      Map<String, String> headers = {
        'Authorization': token,
        "Content-Type": "application/json"
      };

      var body = jsonEncode({
        'email': email,
        'password': password
      });

      response_login = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );

      if (response_login.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response_login.body);

        if (responseData['success']) {
          ApiResponse apiResponse = ApiResponse.fromJson(responseData);

          if (apiResponse.users.isNotEmpty) {
            // ✅ Save user details
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("user_name", apiResponse.users[0].name);
            await prefs.setString("user_email", apiResponse.users[0].email);

            List<Map<String, dynamic>> usersJson =
            apiResponse.users.map((user) => {
              'id': user.id,
              'name': user.name,
              'email': user.email,
              'token': user.token,
              'company_id': user.companyId
            }).toList();

            List<Map<String, dynamic>> companiesJson =
            apiResponse.companies.map((company) => company.toJson()).toList();

            *//*print("✅ Extracted Users Before Saving:");
            for (var user in apiResponse.users) {
              print("📌 User: ${user.name}, Token: ${user.token}");
            }

            print("✅ Extracted Companies Before Saving:");
            for (var company in apiResponse.companies) {
              print("📌 Company ID: ${company.id}, Token: ${company.token}");
            }*//*

            await prefs.setString("users_list", jsonEncode(usersJson));
            await prefs.setString("companies_list", jsonEncode(companiesJson));

            // ✅ Navigate based on available users/companies
            if (apiResponse.companies.isNotEmpty) {
              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CompanySelection()), // Update screen if needed
              );
            } else {
              print("❌ No companies found, showing Snackbar...");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No companies found.")),
              );
            }
          }
        } else {
          throw Exception("Invalid login credentials");
        }
      } else {
        throw Exception("Failed to login");
      }
    } catch (e) {
      print("❌ Exception: $e");
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: appbar_color.withOpacity(0.9),
          automaticallyImplyLeading:false,
          title: Text(widget.title,

          style: TextStyle(
            color: Colors.white
          ),),
        ),
        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
          color: Colors.white,
            /*decoration:BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Color(0xFFD9FCF6),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
              ),
            ),*/
            child:    SingleChildScrollView(
              child:  Column(
                  children: [
                    Container(
                        padding: EdgeInsets.only(top: 50,bottom: 30),
                        child: Icon(
                          Icons.real_estate_agent_outlined,
                          size: 120,
                          color: appbar_color,
                        )
                    ),



                    Visibility(
                        visible: isVisibleAdminLoginForm,
                        child:Container(
                            padding: EdgeInsets.only(left: 32,right: 32,top : 20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 0, // Spread radius
                                    blurRadius: 20, // Blur radius
                                    offset: Offset(0, -10),
                                  ),
                                ],
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(50),
                                    topRight: Radius.circular(50)
                                )
                            ),
                            child:Form(
                                key: _formKey,
                                child: Column(

                                    children: [


                                      Container(
                                        margin: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            )
                                          ],
                                        ),
                                        child: ToggleButtons(

                                          isSelected: [!isAdmin, isAdmin],
                                          onPressed: (index) => setState(() => isAdmin = index == 1),
                                          borderRadius: BorderRadius.circular(30),
                                          selectedColor: Colors.white,
                                          color: Colors.black54,
                                          fillColor: appbar_color,
                                          children: [
                                            Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Tenant")),
                                            Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Admin")),

                                          ],
                                        ),
                                      ),
                                      Container(padding: EdgeInsets.only(top: 5),
                                        child: TextFormField(
                                          controller: emailController,
                                          focusNode: _emailFocusNode,
                                          decoration: InputDecoration(
                                            labelText: 'Email Address',
                                            filled: true,
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                              borderSide: BorderSide(
                                                color: Colors.black12,
                                              ),
                                            ),
                                            fillColor: Colors.white,
                                            labelStyle: TextStyle(
                                              color: Colors.black54, // Set the label text color to black
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.black),
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),

                                          validator: (value) {
                                            if (value == null || value.isEmpty)
                                            {
                                              return 'Please enter your email address';
                                            }
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                                            {
                                              return 'Please enter a valid email address';
                                            }
                                            return null;
                                          },
                                          onSaved: (value) => email = value!,
                                        ),),

                                      SizedBox(height: 16.0),

                                      TextFormField(
                                        controller: passwordController,
                                        focusNode: _passwordFocusNode,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(5.0),
                                            borderSide: BorderSide(
                                              color: Colors.black12,
                                            ),
                                          ),

                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _obscureText = !_obscureText;
                                              });
                                            },
                                            child: Icon(
                                              _obscureText ? Icons.visibility_off :  Icons.visibility,
                                            ),
                                          ),

                                          labelText: 'Password',
                                          filled: true,
                                          fillColor: Colors.white,
                                          labelStyle: TextStyle(
                                            color: Colors.black54, // Set the label text color to black
                                          ),

                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.black),

                                          ),
                                        ),
                                        obscureText: _obscureText,

                                        validator: (value)
                                        {
                                          if (value == null || value.isEmpty)
                                          {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) => password = value!,
                                      ),

                                      SizedBox(height: 5), // Ad

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Handle "Forgot Password" tap event here
                                              setState(() {
                                                /*isVisibleLoginForm = false;*/

                                                /*resetemailController.text = usernameController.text;*/

                                                /*passwordController.clear();*/
                                                /*isVisibleResetPassForm = true;*/
                                              });
                                            },
                                            child: Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.start,children: [

                                            Checkbox(
                                              value: remember_me,
                                              activeColor: appbar_color,
                                              checkColor: Colors.white, // Optional: sets the color of the check icon
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  remember_me = value!;
                                                });
                                              },
                                            ),

                                            Text(
                                              'Remember Me',
                                              style: TextStyle(fontSize: 16,color: Colors.black54),
                                            ),

                                          ]))
                                        ],
                                      ),

                                      SizedBox(height: 32.0),

                                      Container(
                                        width: MediaQuery.of(context).size.width,
                                        child: _isLoading
                                            ? CupertinoActivityIndicator(
                                          radius: 20.0,
                                        )
                                            : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _buttonColor,
                                            elevation: 5, // Adjust the elevation to make it look elevated
                                            shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                          ),
                                          onPressed: () {
                                            if (_formKey.currentState != null &&
                                              _formKey.currentState!.validate()) {
                                            _formKey.currentState!.save();

                                            String email = emailController.text;
                                            String pass = passwordController.text;
                                            loginUser(email,pass,isAdmin);
                                            /*_adminlogin(email,pass,isAdmin);*/
                                          }


                                          },
                                          child: Text('Login',
                                              style: TextStyle(
                                                  color: Colors.white
                                              )),
                                        ),
                                      ),

                                      /*SizedBox(height: 5),

                                    GestureDetector(onTap: ()
                                    {
                                      navigateToPDFView(context);
                                    },
                                        child: Container(
                                            width: MediaQuery.of(context).size.width,
                                            child : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children:[
                                                  Text('Not Registered?',
                                                      style: TextStyle(color: Colors.black54)),

                                                  Text('Click here for instructions',
                                                      style: TextStyle(color: Colors.black54,
                                                          fontWeight: FontWeight.bold,
                                                          decoration: TextDecoration.underline))
                                                ])))*/]))

                        )
                    ),
                    /*Visibility(
                      visible: isVisibleResetPassForm,
                      child:Expanded(child:Container(


                          padding: EdgeInsets.only(left: 32,right: 32,top: 70),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [

                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 0, // Spread radius
                                  blurRadius: 20, // Blur radius
                                  offset: Offset(0, -10),

                                  // Shadow position
                                ),
                              ],

                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                  topRight: Radius.circular(50)
                              )
                          ),
                          child: Form(
                              key: _resetformKey,
                              child: ListView(

                                  children: [
                                    Container(

                                      padding: EdgeInsets.only(top: 5),
                                      child: TextFormField(

                                        controller: resetemailController,
                                        focusNode: _resetemailFocusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Registered Email Address',
                                          filled: true,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(5.0),
                                            borderSide: BorderSide(
                                              color: Colors.black12,
                                            ),
                                          ),
                                          fillColor: Colors.white,
                                          labelStyle: TextStyle(
                                            color: Colors.black54, // Set the label text color to black
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color(int.parse('0xFF30D5C8'))),
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),

                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                          {
                                            return 'Please enter your email address';
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                                          {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) => resetemail = value!,
                                      ),),


                                    SizedBox(height: 32.0),

                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: _isLoadingResetPass
                                          ? CupertinoActivityIndicator(
                                        radius: 20.0,
                                      )
                                          : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _resetbuttonColor,
                                          elevation: 5, // Adjust the elevation to make it look elevated
                                          shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                        ),
                                        onPressed: isResetPassButtonDisabled ? null : () {
                                          if (_resetformKey.currentState != null &&
                                              _resetformKey.currentState!.validate()) {
                                            _resetformKey.currentState!.save();

                                            if(resetemailController.text.trim() == 'demouser@ca-eim.com')
                                            {
                                              _scaffoldMessengerKey.currentState?.showSnackBar(
                                                SnackBar(
                                                  content: Text('Reset password is not allowed for Demo User'),
                                                ),
                                              );
                                            }
                                            else
                                            {
                                              _resetpass();
                                            }
                                          }
                                        },
                                        child: Text('Reset Password',
                                            style: TextStyle(
                                                color: Colors.white
                                            )),
                                      ),
                                    ),

                                    Container(
                                        width: MediaQuery.of(context).size.width,
                                        child:ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(int.parse('0xFF30D5C8')),
                                              elevation: 5, // Adjust the elevation to make it look elevated
                                              shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                            ),
                                            onPressed: () {

                                              setState(() {
                                                usernameController.text = resetemailController.text;
                                                resetemailController.clear();
                                                isVisibleResetPassForm = false;
                                                isVisibleLoginForm = true;
                                              });
                                            },
                                            child: Text('Cancel',
                                                style: TextStyle(
                                                    color: Colors.white
                                                ))))]))))),
                  Visibility(
                      visible: isVisibleOTPForm,
                      child:Expanded(child:Container(

                          padding: EdgeInsets.only(left: 32,right: 32,top: 30),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 0, // Spread radius
                                  blurRadius: 20, // Blur radius
                                  offset: Offset(0, -10),
                                  // Shadow position
                                ),
                              ],
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                  topRight: Radius.circular(50)
                              )
                          ),
                          child: Form(
                              key: _otpformKey,
                              child: ListView(
                                  children:[

                                    Icon(Icons.mark_email_read_outlined, size: 100,
                                        color: Color(0xFF30D5C8)), // Mobile phone icon
                                    SizedBox(height: 20),
                                    Text(
                                      'Enter Verification Code',
                                      style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 5.0),
                                    Center(child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "We've sent you an OTP on ",
                                            style: TextStyle(color: Colors.black54),

                                          ),
                                          TextSpan(
                                            text: maskedEmail, // The masked email value
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), // Bold style
                                          ),

                                        ],
                                      ),
                                    ),),

                                    Text(
                                        ". Please enter that code below to continue."
                                        ,style: TextStyle(color: Colors.black54),
                                        textAlign: TextAlign.center// Regular text style
                                    ),

                                    Padding(
                                      padding: EdgeInsets.only(left: 5,right: 5,top: 16),
                                      child: PinCodeTextField(
                                        appContext: context,
                                        pastedTextStyle: TextStyle(
                                          color: Colors.green.shade600,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        length: 4, // Specify the length of OTP
                                        onChanged: (value) {
                                          currentText = value;
                                        },
                                        pinTheme: PinTheme(
                                            shape: PinCodeFieldShape.box,
                                            borderRadius: BorderRadius.circular(15),
                                            fieldHeight: 50,
                                            fieldWidth: 50,
                                            activeFillColor: Color(0xFF30D5C8),
                                            inactiveFillColor: Colors.white,
                                            activeColor: Color(0xFF30D5C8),
                                            inactiveColor: Colors.grey,
                                            borderWidth: 1,
                                            selectedColor: Color(0xFF30D5C8)
                                        ),
                                        controller: otpController,
                                        keyboardType: TextInputType.number,
                                        onCompleted: (value) {
                                          // OTP entry is complete
                                        },
                                        obscureText: true,
                                      ),
                                    ),
                                    SizedBox(height: 20),

                                    Visibility(visible: isVisibleTimer,
                                      child: Column(children: [
                                        Text(
                                          "Resend OTP in: $_formattedTime", // Display remaining time
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 16, color: Colors.black54),
                                        ),
                                        SizedBox(height: 20),


                                      ],),),

                                    Visibility(visible: _isButtonEnabled,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(int.parse('0xFF30D5C8')), // Change button color based on enabled state
                                        ),
                                        onPressed: () {
                                          sendOTP(usernamee);
                                          setState(() {
                                            _isButtonEnabled = false;
                                            isVisibleTimer = true;
                                            _startTimer();
                                          });

                                        }, // Disable button if not enabled
                                        child: Text(
                                          'Resend OTP',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),),

                                    SizedBox(height: 10),

                                    ElevatedButton(

                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _buttonColor,
                                      ),
                                      onPressed: () {

                                        if (currentText.length == 4) {
                                          final generatedOTP = generatedotp;
                                          final enteredOTP = currentText;

                                          if (enteredOTP == generatedOTP) {

                                            socket.emit('deleteMyId', socket_data);

                                            isOTPVerified = true;
                                            isAnotherDevice = true;

                                            _directlogin();
                                          }
                                          else {
                                            isOTPVerified = false;
                                            isAnotherDevice = false;
                                            Fluttertoast.showToast(msg: 'Incorrect OTP');
                                          }
                                        }
                                        else
                                        {
                                          isOTPVerified = false;
                                          isAnotherDevice = false;
                                          Fluttertoast.showToast(msg: 'Please enter a 4-digit OTP');
                                        }
                                      },
                                      child: Text('Verify',
                                          style: TextStyle(
                                              color: Colors.white
                                          )),
                                    )
                                  ]
                              ))))),*/
                  ])
            ),
           )
        );}}
