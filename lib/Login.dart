import 'dart:convert';
import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:cshrealestatemobile/AdminDashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'FlatSelection.dart';
import 'SerialSelect.dart';
import 'constants.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final String? is_admin; // Now added to extract company name

  final String? baseurl;
  final String? adminurl;
  final int? allowed_companies;
  final int? allowed_users_per_company;
  final int? allowed_tenants_per_company;
  final int? allowed_buildings_per_company;
  final int? allowed_flats_per_company;
  final String? license_expiry;

  User({required this.id, required this.name, required this.email, required this.token, this.companyId,this.is_admin,
    this.companyName, this.baseurl,this.adminurl,this.allowed_buildings_per_company, this.allowed_companies,
  this.allowed_flats_per_company,this.allowed_tenants_per_company,this.allowed_users_per_company,this.license_expiry
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Unknown",
      email: json['email'] ?? "Unknown",
      token: json['accessToken'] ?? "",
      companyId: json['company_id'],
      is_admin:  json["is_admin"],
      companyName: json['company'] != null ? json['company']['name'] : "Unknown Company", // Extracts company name correctly
      baseurl: json['company'] != null ? json['company']['hosting']['baseurl'] : "Unknown baseURL",
      adminurl: json['company'] != null ? json['company']['hosting']['adminurl'] : "Unknown adminurl",
      allowed_companies: json['company'] != null ? json['company']['hosting']['allowed_companies'] : "Unknown allowed_companies",
      allowed_users_per_company: json['company'] != null ? json['company']['hosting']['allowed_users_per_company'] : "Unknown allowed_users_per_company",
      allowed_buildings_per_company:json['company'] != null ? json['company']['hosting']['allowed_buildings_per_company'] : "Unknown allowed_buildings_per_company",
      allowed_flats_per_company:json['company'] != null ? json['company']['hosting']['allowed_flats_per_company'] : "Unknown allowed_flats_per_company",
      license_expiry:json['company'] != null ? json['company']['hosting']['license_expiry'] : "Unknown license_expiry",
    );
  }
}

class _LoginPageState extends State<Login> {

  bool isVisibleAdminLoginForm= true,_isLoading = false,isButtonDisabled = false;

  Color _buttonColor = Colors.grey;

  bool isAdmin = false; // Toggle state

  bool isOwner = false;


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

  void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
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
  }

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);

    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
     prefs= await SharedPreferences.getInstance();
     bool savedRememberMe = prefs!.getBool('remember_me') ?? false;
     if (savedRememberMe) {
       emailController.text = prefs!.getString('user_email') ?? '';
       passwordController.text = prefs!.getString('password') ?? '';
       setState(() {
         remember_me = true;
       });
     }
  }

  Future<void> _adminlogin(String email, String password) async {

    prefs!.clear();

    String url = "$OAuth_URL/oauth/token";

    /*String token = 'Bearer $authTokenBase';*/

    setState(() => _isLoading = true);
    dynamic responseData;

    try {
      Map<String, String> headers = {
        "Content-Type": "application/x-www-form-urlencoded"
      };

      Map<String, String> body = {
        'username': email,
        'password': password,
        'client_id': client_id_constant,
        'client_secret': client_password_constant,
        'scope': "user",
        "grant_type" : "password"
      };
      /*var body = jsonEncode({'email': email, 'password': password});*/

      var response = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );
      responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<User> usersList = [];

        print('data ${responseData['user']}');

        usersList = (responseData['user'] as List)
            .map((user) => User.fromJson(user))
            .toList();

        if (usersList.isNotEmpty) {
          User firstUser = usersList[0];

          await prefs.setInt("user_id", firstUser.id);
          await prefs.setBool('remember_me', true);
          await prefs.setString("scope", responseData["scope"]);
          await prefs.setString("user_name", firstUser.name);
          await prefs.setString("password", password);
          await prefs.setString("user_email", firstUser.email);
          await prefs.setString("company_token", firstUser.token);
          await prefs.setInt("company_id", firstUser.companyId ?? 0);
          await prefs.setBool('is_admin', isAdmin==true ? true : false);
          await prefs.setBool('is_admin_from_api',firstUser.is_admin.toString().toLowerCase() == "true" ? true : false );
          await prefs.setString("baseurl", firstUser.baseurl ?? "");
          await prefs.setString("adminurl", firstUser.adminurl ?? "");
          await prefs.setString("license_expiry", firstUser.license_expiry ?? "");
          await prefs.setString("company_name", firstUser.companyName ?? "");

          List<Map<String, dynamic>> companiesJson = usersList
              .map((user) => {
            'id': user.companyId ?? 0,
            'name': user.companyName ?? 'Unknown Company', // Use company name
            'token': user.token,
            'baseurl': user.baseurl,
            'adminurl': user.adminurl,
            'license_expiry': user.license_expiry,
          }).toList();

          await prefs.setString("companies_list", jsonEncode(companiesJson));

          loadTokens();

          // Redirect based on user type and company count

          print('userlist ${usersList.length}');
          if (usersList.length > 1) {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CompanySelection()),
            );
          } else {
            print("✅ Selected Company: ${ firstUser.companyName ?? ""}");
            print("🔑 Company Token: ${firstUser.token}");


            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
            );
          }
        }
      } else {
        await prefs!.setBool('remember_me', false);

        final errorMessage = responseData['message'] ?? 'Unknown error occurred';
        showErrorSnackbar(context, errorMessage);
      }
    } catch (e) {
      await prefs!.setBool('remember_me', false);

      final errorMessage = responseData['message'] ?? 'Unknown error occurred';
      showErrorSnackbar(context, errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // old tenant login function

  /*Future<void> tenantLogin(String email, String password) async {
    String url = "$OAuth_URL/oauth/token";
    String token = 'Bearer $authTokenBase';

    setState(() => _isLoading = true);
    dynamic responseData;

    try {
      Map<String, String> headers = {
        "Content-Type": "application/x-www-form-urlencoded"
      };

      Map<String, String> body = {
        'username': email,
        'password': password,
        'client_id': client_id_constant,
        'client_secret': client_password_constant,
        'scope': "tenant",
        "grant_type": "password"
      };

      var response = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );
      responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData.containsKey('user')) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        List<dynamic> tenantsData = responseData['user'] ?? [];

        if (tenantsData.isNotEmpty) {
          var firstTenant = tenantsData[0];

          await prefs.setInt("user_id", firstTenant['tenant_id']);
          await prefs.setString("user_name", firstTenant['tenant']['name']);
          await prefs.setString("user_email", firstTenant['tenant']['email']);
          await prefs.setString("company_token", firstTenant['accessToken']);
          await prefs.setInt("company_id", firstTenant['company_id'] ?? 0);
          await prefs.setBool('is_admin', false);
          await prefs.setString("license_expiry", firstTenant['tenant']['company']['hosting']['license_expiry']);
          await prefs.setString("baseurl", firstTenant['tenant']['company']['hosting']['baseurl']);
          await prefs.setString("adminurl", firstTenant['tenant']['company']['hosting']['adminurl']);

          // ✅ Extract Flats (Instead of Companies)
          List<Map<String, dynamic>> flatsList = tenantsData.map((tenant) {
            return {
              'tenant_id': tenant['tenant_id'] ?? 0,
              'id': tenant['flat_id'] ?? 0,
              'name': tenant['flat']['name'] ?? 'Unknown Flat',
              'building': tenant['flat']['building_name'] ?? 'Unknown Building',
              'company_id': tenant['tenant']['company']['id'] ?? 0,
              'baseurl': tenant['tenant']['company']['hosting']['baseurl'] ?? '',
              'adminurl': tenant['tenant']['company']['hosting']['adminurl'] ?? '',
              'license_expiry': tenant['tenant']['company']['hosting']['license_expiry'] ?? '',
              'accessToken': tenant['accessToken'] ?? '',
            };
          }).toList();

          await prefs.setString("flats_list", jsonEncode(flatsList));
          loadTokens();

          // ✅ Redirect to Flat Selection if multiple flats exist
          if (flatsList.length > 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FlatSelection()),
            );
          } else {
            await prefs.setInt("flat_id", flatsList.first['id']);
            await prefs.setString("flat_name", flatsList.first['name']);
            await prefs.setString("building", flatsList.first['building']);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TenantDashboard()),
            );
          }
        } else {
          final errorMessage = responseData['message'] ?? 'Unknown error occurred';
          showErrorSnackbar(context, errorMessage);
        }
      } else {
        final errorMessage = responseData['message'] ?? 'Unknown error occurred';
        showErrorSnackbar(context, errorMessage);
      }
    } catch (e) {
      final errorMessage = responseData['message'] ?? 'Unknown error occurred';
      showErrorSnackbar(context, errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }*/

  // new tenant login function

  Future<void> tenantLogin(String email, String password) async {
    prefs!.clear();

    String loginUrl = "$OAuth_URL/oauth/token";
    setState(() => _isLoading = true);

    try {
      // Step 1: Get token and user info
      var loginResponse = await http.post(
        Uri.parse(loginUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'username': email,
          'password': password,
          'client_id': client_id_constant,
          'client_secret': client_password_constant,
          'scope': "tenant",
          "grant_type": "password",
        },
      );

      var loginData = json.decode(loginResponse.body);
      if (loginResponse.statusCode != 200 || !loginData.containsKey('user')) {
        showErrorSnackbar(context, "${loginData['message']}" ?? 'Login failed');
        return;
      }

      final user = loginData['user'][0];
      final company = user['company'];
      final hosting = company['hosting'];
      final token = user['accessToken'];
      final tenantId = user['id']; // tenant_id

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt("user_id", tenantId);
      await prefs.setBool('remember_me', true);

      await prefs.setString("user_name", user['name']);
      await prefs.setString("scope", loginData["scope"]);
      await prefs.setString("user_email", user['email']);
      await prefs.setString("password", password);

      await prefs.setString("company_token", token);
      await prefs.setInt("company_id", user['company_id'] ?? 0);
      await prefs.setBool('is_admin', false);

      // no admin from api
      await prefs.remove('is_admin_from_api');

      await prefs.setString("license_expiry", hosting['license_expiry']);
      await prefs.setString("baseurl", hosting['baseurl']);
      await prefs.setString("adminurl", hosting['adminurl']);

      await Future.delayed(Duration(seconds: 1));

      // Step 2: Get tenant + flats details using tenantId
      final tenantUrl = "${hosting['baseurl']}/tenant/$tenantId";

      print('tenant url $tenantUrl');
      print('token -> $token');

      var tenantResponse = await http.get(
        Uri.parse(tenantUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      var tenantData = json.decode(tenantResponse.body);

      print('response -> ${tenantResponse.body}');

      if (!tenantData['success']) {
        final errorMsg = "${tenantData['message']}" ?? "Failed to fetch tenant details.";
        showErrorSnackbar(context, errorMsg);
        return;
      }

      var tenant = tenantData['data']['tenant'];
      var contracts = tenant['contracts'] as List<dynamic>;

      List<Map<String, dynamic>> flatsList = contracts.expand((contract) {
        return (contract['flats'] as List<dynamic>).map((flatData) {
          var flat = flatData['flat'];
          return {
            'tenant_id': tenant['id'],
            'id': flat['id'],
            'name': flat['name'],
            'building': flat['building']['name'] ?? 'Unknown Building',
            'company_id': tenant['company_id'],
            'baseurl': hosting['baseurl'],
            'adminurl': hosting['adminurl'],
            'license_expiry': hosting['license_expiry'],
            'accessToken': token,
          };
        });
      }).toList();

      await prefs.setString("flats_list", jsonEncode(flatsList));


      // Step 3: Redirect user
      if (flatsList.length > 1) {
        loadTokens();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FlatSelection()),
        );
      } else if (flatsList.isNotEmpty) {

        var flat = flatsList.first;
        await prefs.setInt("flat_id", flat['id']);
        await prefs.setString("flat_name", flat['name']);
        await prefs.setString("building", flat['building']);
        loadTokens();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TenantDashboard()),
        );
      } else {
        await prefs!.setBool('remember_me', false);

        showErrorSnackbar(context, "No flats found for this tenant.");
      }
    } catch (e) {
      await prefs!.setBool('remember_me', false);

      showErrorSnackbar(context, "Something went wrong during login.");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void loginUser(String email, String password, bool isAdmin) {
    if (isAdmin) {
      _adminlogin(email, password);
    } else {
      tenantLogin(email, password);
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

            */
  /*print("✅ Extracted Users Before Saving:");
            for (var user in apiResponse.users) {
              print("📌 User: ${user.name}, Token: ${user.token}");
            }

            print("✅ Extracted Companies Before Saving:");
            for (var company in apiResponse.companies) {
              print("📌 Company ID: ${company.id}, Token: ${company.token}");
            }*/
  /*

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

          style: GoogleFonts.poppins(
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
            child: SingleChildScrollView(
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
                            height: MediaQuery.of(context).size.height,

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
                                        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                                        padding: const EdgeInsets.all(12),
                                        width: MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 8.0,
                                          runSpacing: 12.0,
                                          children: [
                                            _buildToggleChip("Tenant", !isAdmin && !isOwner, () {
                                              setState(() {
                                                isAdmin = false;
                                                isOwner = false;
                                              });
                                            }),
                                            _buildToggleChip("Admin", isAdmin, () {
                                              setState(() {
                                                isAdmin = true;
                                                isOwner = false;
                                              });
                                            }),
                                            _buildToggleChip("Owner", isOwner, () {
                                              Fluttertoast.showToast(
                                                msg: "Owner access is under development",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                              );
                                            }),
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
                                            labelStyle: GoogleFonts.poppins(
                                              color: Colors.black54, // Set the label text color to black
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.black),
                                            ),
                                          ),
                                          style: GoogleFonts.poppins(
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
                                          labelStyle: GoogleFonts.poppins(
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
                                              style: GoogleFonts.poppins(
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
                                              style: GoogleFonts.poppins(fontSize: 16,color: Colors.black54),
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
                                              style: GoogleFonts.poppins(
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
                                                      style: GoogleFonts.poppins(color: Colors.black54)),

                                                  Text('Click here for instructions',
                                                      style: GoogleFonts.poppins(color: Colors.black54,
                                                          fontWeight: FontWeight.bold,
                                                          decoration: TextDecoration.underline))
                                                ])))*/
                                    ])))),
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
                                          labelStyle: GoogleFonts.poppins(
                                            color: Colors.black54, // Set the label text color to black
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color(int.parse('0xFF30D5C8'))),
                                          ),
                                        ),
                                        style: GoogleFonts.poppins(
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
                                            style: GoogleFonts.poppins(
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
                                                style: GoogleFonts.poppins(
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
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 5.0),
                                    Center(child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "We've sent you an OTP on ",
                                            style: GoogleFonts.poppins(color: Colors.black54),

                                          ),
                                          TextSpan(
                                            text: maskedEmail, // The masked email value
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black54), // Bold style
                                          ),

                                        ],
                                      ),
                                    ),),

                                    Text(
                                        ". Please enter that code below to continue."
                                        ,style: GoogleFonts.poppins(color: Colors.black54),
                                        textAlign: TextAlign.center// Regular text style
                                    ),

                                    Padding(
                                      padding: EdgeInsets.only(left: 5,right: 5,top: 16),
                                      child: PinCodeTextField(
                                        appContext: context,
                                        pastedGoogleFonts.poppins: GoogleFonts.poppins(
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
                                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
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
                                          style: GoogleFonts.poppins(color: Colors.white),
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
                                          style: GoogleFonts.poppins(
                                              color: Colors.white
                                          )),
                                    )
                                  ]
                              ))))),*/
                  ])
            ),
           )
        );}
  Widget _buildToggleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? appbar_color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? appbar_color : Colors.grey.withOpacity(0.5)),
          boxShadow: isSelected
              ? [BoxShadow(color: appbar_color.withOpacity(0.3), blurRadius: 6)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

}
