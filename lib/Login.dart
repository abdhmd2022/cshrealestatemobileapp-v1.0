import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:http/http.dart' as http;
import 'package:cshrealestatemobile/AdminDashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'FlatSelection.dart';
import 'SerialSelect.dart';
import 'constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

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

  bool isForgotPasswordMode = false;
  String? generatedotp; // already using this
  bool otpSent = false;
  bool otpVerified = false;
  String? resetToken;
  late TextEditingController otpController;
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isVisibleAdminLoginForm= true,_isLoading = false,isButtonDisabled = false;

  Color _buttonColor = Colors.grey;

  bool isAdmin = false; // Toggle state

  bool isLandlord = false;

  Timer? _otpTimer;
  int _remainingSeconds = 60;
  bool  _showResendButton = true;

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

  String selectedRole = "Tenant"; // Default selection

  bool emailLocked = true;

  bool showNewPassword = false;
  bool showConfirmPassword = false;
  bool isStrongPassword = false;

  void startOtpTimer() {
    setState(() {
      _remainingSeconds = 60;
      _showResendButton = false;
    });

    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          _showResendButton = true;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  /*Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return; // cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final String? idToken = googleAuth.idToken; // ⬅️ THIS is what we need
      final String? accessToken = googleAuth.accessToken;

      final String? email = googleUser.email;
      final String? name = googleUser.displayName;

      print("📧 Google email: $email");
      print("🪪 ID Token: $idToken");

      // ⬇️ Now call your API
       loginUser(
        emailController.text,
        passwordController.text,
        isAdmin,
        isLandlord,
      );

    } catch (e) {
      showErrorSnackbar(context, "Google Sign-In failed: $e");
    }
  }

  Future<void> _handleFacebookSignIn() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        print("Facebook Login -> ${userData["email"]}");

        // TODO: Send this info to your backend if needed or store in prefs
      } else {
        showErrorSnackbar(context, 'Facebook login failed');
      }
    } catch (e) {
      showErrorSnackbar(context, 'Facebook login error');
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (!Platform.isIOS) return;

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      print("Apple Login -> ${credential.email} | ${credential.givenName}");

      // TODO: Send this info to your backend if needed or store in prefs
    } catch (e) {
      showErrorSnackbar(context, 'Apple Sign-In failed');
    }
  }*/


  // landlord permissions
  List<Map<String, dynamic>> landlordPermissions = [
    {
      "name": "canCreateMaintenanceTicket",
      "category": "Maintenance",
      "description": "Create maintenance ticket"
    },
    {
      "name": "canViewMaintenanceTickets",
      "category": "Maintenance",
      "description": "View maintenance tickets"
    },
    {
      "name": "canCreateTicketComment",
      "category": "Maintenance",
      "description": "Create ticket comment"
    },
    {
      "name": "canViewTicketComment",
      "category": "Maintenance",
      "description": "View ticket comment"
    },
    {
      "name": "canViewTicketComplaint",
      "category": "Maintenance",
      "description": "View ticket complaint"
    },
    {
      "name": "canViewTicketFeedback",
      "category": "Maintenance",
      "description": "View ticket feedback"
    },
    {
      "name": "canCreateRequest",
      "category": "Request",
      "description": "Create request"
    },
    {
      "name": "canViewRequest",
      "category": "Request",
      "description": "View request"
    },
    {
      "name": "canViewAvailableUnits",
      "category": "Available Units",
      "description": "View available units"
    },
    {
      "name": "canCreateComplaintSuggestion",
      "category": "Analytics",
      "description": "Create complaint/suggestion"
    },
    {
      "name": "canViewComplaintSuggestions",
      "category": "Analytics",
      "description": "View complaint/suggestions"
    },
    {
      "name": "canViewAnnouncement",
      "category": "Announcement",
      "description": "View Announcement"
    },
    {
      "name": "canViewChequeDetails",
      "category": "Analytics",
      "description": "View cheque details"
    }
  ];

  // tenant permissions
  List<Map<String, dynamic>> tenantPermissions = [
    {
      "name": "canCreateMaintenanceTicket",
      "category": "Maintenance",
      "description": "Create maintenance ticket"
    },
    {
      "name": "canViewMaintenanceTickets",
      "category": "Maintenance",
      "description": "View maintenance tickets"
    },
    {
      "name": "canCreateTicketComment",
      "category": "Maintenance",
      "description": "Create ticket comment"
    },
    {
      "name": "canViewTicketComment",
      "category": "Maintenance",
      "description": "View ticket comment"
    },
    {
      "name": "canViewTicketComplaint",
      "category": "Maintenance",
      "description": "View ticket complaint"
    },
    {
      "name": "canViewTicketFeedback",
      "category": "Maintenance",
      "description": "View ticket feedback"
    },
    {
      "name": "canCreateRequest",
      "category": "Request",
      "description": "Create request"
    },
    {
      "name": "canViewRequest",
      "category": "Request",
      "description": "View request"
    },
    {
      "name": "canViewAvailableUnits",
      "category": "Available Units",
      "description": "View available units"
    },
    {
      "name": "canCreateComplaintSuggestion",
      "category": "Analytics",
      "description": "Create complaint/suggestion"
    },
    {
      "name": "canViewComplaintSuggestions",
      "category": "Analytics",
      "description": "View complaint/suggestions"
    },
    {
      "name": "canViewAnnouncement",
      "category": "Announcement",
      "description": "View Announcement"
    },
    {
      "name": "canViewChequeDetails",
      "category": "Analytics",
      "description": "View cheque details"
    }
  ];


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
    otpController = TextEditingController();
    newPasswordController.addListener(() {
      final text = newPasswordController.text;
      final isValid = _isStrongPassword(text) && text.length >= 6;
      if (isStrongPassword != isValid) {
        setState(() => isStrongPassword = isValid);
      }
    });

    _initSharedPreferences();
  }

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _otpTimer?.cancel();
    super.dispose();
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

  // old admin login function
  /*Future<void> _adminlogin(String email, String password) async {

    prefs!.clear();

    String url = "$OAuth_URL/oauth/token";

    *//*String token = 'Bearer $authTokenBase';*//*

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
      *//*var body = jsonEncode({'email': email, 'password': password});*//*

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
          await prefs.setString("access_token", firstUser.token);
          await prefs.setInt("company_id", firstUser.companyId ?? 0);
          await prefs.setBool('is_admin', isAdmin==true ? true : false);
          await prefs.setBool('is_admin_from_api',firstUser.is_admin.toString().toLowerCase() == "true" ? true : false );
          await prefs.setString("baseurl", firstUser.baseurl ?? "");
          await prefs.setBool('is_landlord', false);


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
  }*/

  Future<void> fetchAndSaveCompanyData(String baseurll,int company_id,String token) async {

    print('calling -> $baseurll');
    try {
      final url = Uri.parse('$baseurll/company/details/$company_id');
      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },);

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final company = responseJson['data']['company'];

        await saveCompanyData(company);

      } else {
        print('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchAndSaveCompanyDataTenant(String baseurll,int company_id,String token) async {

    print('calling -> $baseurll');
    try {
      final url = Uri.parse('$baseurll/company/details/$company_id');
      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },);

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final company = responseJson['data']['company'];

        await saveCompanyDataTenant(company);

      } else {
        print('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> saveCompanyData(Map<String, dynamic> company) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('mailing_name', company['mailing_name'] ?? '');
    await prefs.setString('address', company['address'] ?? '');
    await prefs.setString('pincode', company['pincode'] ?? '');
    await prefs.setString('state', company['state'] ?? '');
    await prefs.setString('country', company['country'] ?? '');
    await prefs.setString('trn', company['trn'] ?? '');
    await prefs.setString('phone', company['phone'] ?? '');
    await prefs.setString('mobile', company['mobile'] ?? '');
    await prefs.setString('email', company['email'] ?? '');
    await prefs.setString('website', company['website'] ?? '');
    await prefs.setString('logo_path', company['logo_path'] ?? '');
    await prefs.setString('whatsapp_no', company['whatsapp_no'] ?? '');

    print('Company data saved');

    loadTokens();

    print('Company data loaded');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminDashboard()),
    );
  }

  Future<void> saveCompanyDataTenant(Map<String, dynamic> company) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('mailing_name', company['mailing_name'] ?? '');
    await prefs.setString('address', company['address'] ?? '');
    await prefs.setString('pincode', company['pincode'] ?? '');
    await prefs.setString('state', company['state'] ?? '');
    await prefs.setString('country', company['country'] ?? '');
    await prefs.setString('trn', company['trn'] ?? '');
    await prefs.setString('phone', company['phone'] ?? '');
    await prefs.setString('mobile', company['mobile'] ?? '');
    await prefs.setString('email', company['email'] ?? '');
    await prefs.setString('website', company['website'] ?? '');
    await prefs.setString('logo_path', company['logo_path'] ?? '');
    await prefs.setString('whatsapp_no', company['whatsapp_no'] ?? '');

    print('Company data saved');

    loadTokens();

    print('Company data loaded');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TenantDashboard()),
    );
  }


  // new admin login function
  Future<void> _adminlogin(String email, String password) async {
    prefs!.clear();
    String url = "$OAuth_URL/token";
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
        "grant_type": "password"
      };

      var response = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );
      responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<dynamic> usersJsonList = responseData['user'];

        List<Map<String, dynamic>> companiesJson = [];

        for (var userJson in usersJsonList) {
          final company = userJson['company'] ?? {};
          final hosting = company['hosting'] ?? {};
          final role = userJson['role'] ?? {};

          companiesJson.add({
            'id': userJson['company_id'] ?? 0,
            'name': company['name'] ?? 'Unknown Company',
            'allowed_users_per_company': hosting['allowed_users_per_company'] ?? 0,
            'token': userJson['accessToken'] ?? responseData['accessToken'],
            'token_expiry': userJson['accessTokenExpiresAt'] ?? responseData['accessTokenExpiresAt'],
            'baseurl': hosting['baseurl'] ?? '',
            'adminurl': hosting['adminurl'] ?? '',
            'license_expiry': hosting['license_expiry'] ?? '',
            'permissions': role['permissions'] ?? [],
            'role_name': role['name'] ?? '',
            'is_active': userJson['is_active'].toString().toLowerCase() == 'true',
            'user_id': userJson['id'],
            'user_email': userJson['email'],
            'user_name': userJson['name'],
            'is_admin': userJson['is_admin'].toString().toLowerCase() == 'true',
          });
        }

        // Store first user/company context
        var first = companiesJson[0];

        await prefs.setBool('remember_me', true);
        await prefs.setString("scope", responseData["scope"]);
        await prefs.setInt("user_id", first["user_id"]);
        await prefs.setString("user_name", first["user_name"]);
        await prefs.setString("user_email", first["user_email"]);
        await prefs.setString("password", password);
        await prefs.setString("access_token", first["token"]);
        await prefs.setString("access_token_expiry", first["token_expiry"]);
        await prefs.setBool('is_admin', isAdmin==true ? true : false);
        await prefs.setBool('is_admin_from_api', first["is_admin"]);
        await prefs.setString("role_name", first["role_name"]);
        await prefs.setBool("is_active", first["is_active"]);
        await prefs.setInt("company_id", first["id"]);
        await prefs.setString("company_name", first["name"]);
        await prefs.setString("baseurl", first["baseurl"]);
        await prefs.setString("adminurl", first["adminurl"]);
        await prefs.setString("license_expiry", first["license_expiry"]);
        await prefs.setBool('is_landlord', false);
        await prefs.setString("user_permissions", jsonEncode(first["permissions"]));

        // Store all companies with roles
        await prefs.setString("companies_list", jsonEncode(companiesJson));

        loadTokens();

        if (companiesJson.length > 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CompanySelection()),
          );
        } else {
          // Parse license expiry date
          final expiryString = first["license_expiry"];
          if (expiryString != null && expiryString.isNotEmpty) {
            final expiryDate = DateTime.tryParse(expiryString);
            final now = DateTime.now();

            if (expiryDate != null && expiryDate.isBefore(now)) {
              showErrorSnackbar(
                context,
                'Your license against "${first["name"]}" is expired. Please contact your service provider for renewal.',
              );
              return; // Don't proceed to dashboard
            }
          }
          fetchAndSaveCompanyData(first["baseurl"],first["id"],first["token"]);
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
          await prefs.setString("access_token", firstTenant['accessToken']);
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

    String loginUrl = "$OAuth_URL/token";
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

      await prefs.setString("access_token", token);
      await prefs.setInt("company_id", user['company_id'] ?? 0);
      await prefs.setBool('is_admin', false);
      await prefs.setBool('is_landlord', false);

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

      print('response 2 tenant login-> ${tenantResponse.body}');

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
      await prefs.setString("user_permissions", jsonEncode(tenantPermissions));
      await prefs.setString("role_name", 'Tenant');


      // Step 3: Redirect user
      if (flatsList.length > 1) {
        loadTokens();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FlatSelection()),
        );
      }
      else if (flatsList.isNotEmpty) {



        var flat = flatsList.first;
        await prefs.setInt("flat_id", flat['id']);
        await prefs.setString("flat_name", flat['name']);
        await prefs.setString("building", flat['building']);

        await fetchAndSaveCompanyDataTenant(
          flat['baseurl'],
          flat['company_id'],
          flat['accessToken'],
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

  // new landlord function
  Future<void> landlordLogin(String email, String password) async {
    prefs!.clear();

    String loginUrl = "$OAuth_URL/token";
    setState(() => _isLoading = true);

    try {
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
          'scope': "landlord",
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
      final landlordId = user['id'];

      await prefs!.setInt("user_id", landlordId);
      await prefs!.setBool('remember_me', true);
      await prefs!.setString("user_name", user['name']);
      await prefs!.setString("scope", loginData["scope"]);
      await prefs!.setString("user_email", user['email']);
      await prefs!.setString("password", password);

      await prefs!.setString("access_token", token);
      await prefs!.setInt("company_id", user['company_id'] ?? 0);
      await prefs!.setBool('is_admin', false);
      await prefs!.setBool('is_landlord', true);
      await prefs!.remove('is_admin_from_api');
      await prefs!.setString("role_name", 'Landlord');
      await prefs!.setString("license_expiry", hosting['license_expiry']);
      await prefs!.setString("baseurl", hosting['baseurl']);
      await prefs!.setString("adminurl", hosting['adminurl']);
      await prefs!.setString("user_permissions", jsonEncode(landlordPermissions));

      await Future.delayed(Duration(seconds: 1));

      final landlordUrl = "${hosting['baseurl']}/landlord/$landlordId";

      var landlordResponse = await http.get(
        Uri.parse(landlordUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      var landlordData = json.decode(landlordResponse.body);

      if (!landlordData['success']) {
        final errorMsg = "${landlordData['message']}" ?? "Failed to fetch landlord details.";
        showErrorSnackbar(context, errorMsg);
        return;
      }

      var landlord = landlordData['data']['landlord'];
      var contracts = landlord['bought_contracts'] as List<dynamic>;

      List<Map<String, dynamic>> flatsList = contracts.expand((contract) {
        return (contract['flats'] as List<dynamic>).map((flatData) {
          var flat = flatData['flat'];
          return {
            'landlord_id': landlord['id'],
            'id': flat['id'],
            'name': flat['name'],
            'building': flat['building']['name'] ?? 'Unknown Building',
            'company_id': landlord['company_id'],
            'baseurl': hosting['baseurl'],
            'adminurl': hosting['adminurl'],
            'license_expiry': hosting['license_expiry'],
            'accessToken': token,
          };
        });
      }).toList();

      await prefs!.setString("flats_list", jsonEncode(flatsList));

      if (flatsList.length > 1) {
        loadTokens();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FlatSelection()),
        );
      } else if (flatsList.isNotEmpty) {
        var flat = flatsList.first;
        await prefs!.setInt("flat_id", flat['id']);
        await prefs!.setString("flat_name", flat['name']);
        await prefs!.setString("building", flat['building']);

        await fetchAndSaveCompanyDataTenant(
          hosting['baseurl'],
          user['company_id'],
          token,
        );
      } else {
        await prefs!.setBool('remember_me', false);
        showErrorSnackbar(context, "No units found for this landlord.");
      }
    } catch (e) {
      await prefs!.setBool('remember_me', false);
      showErrorSnackbar(context, "Something went wrong during login.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // old landlord function
  /*Future<void> landlordLogin(String email, String password) async {
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
          'scope': "landlord",
          "grant_type": "password",
        },
      );

      var loginData = json.decode(loginResponse.body);
      if (loginResponse.statusCode != 200 || !loginData.containsKey('landlord')) {
        showErrorSnackbar(context, "${loginData['message']}" ?? 'Login failed');
        return;
      }

      final user = loginData['landlord'][0];
      final company = user['company'];
      final hosting = company['hosting'];
      final token = user['accessToken'];
      final landlordId = user['id']; // landlord_id

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt("user_id", landlordId);
      await prefs.setBool('remember_me', true);
      await prefs.setString("user_name", user['name']);
      await prefs.setString("scope", loginData["scope"]);
      await prefs.setString("user_email", user['email']);
      await prefs.setString("password", password);

      await prefs.setString("access_token", token);
      await prefs.setInt("company_id", user['company_id'] ?? 0);
      await prefs.setBool('is_admin', false);
      await prefs.setBool('is_landlord', true);

      // no admin from api
      await prefs.remove('is_admin_from_api');

      await prefs.setString("license_expiry", hosting['license_expiry']);
      await prefs.setString("baseurl", hosting['baseurl']);
      await prefs.setString("adminurl", hosting['adminurl']);

      await Future.delayed(Duration(seconds: 1));

      // Step 2: Get tenant + flats details using tenantId
      final landlordUrl = "${hosting['baseurl']}/landlord/$landlordId";

      print('landlord url $landlordUrl');
      print('token -> $token');

      var tenantResponse = await http.get(
        Uri.parse(landlordUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      var landlordData = json.decode(tenantResponse.body);

      print('response 2 landlord login-> ${tenantResponse.body}');

      if (!landlordData['success']) {
        final errorMsg = "${landlordData['message']}" ?? "Failed to fetch tenant details.";
        showErrorSnackbar(context, errorMsg);
        return;
      }

      var landlord = landlordData['data']['landlord'];
      var contracts = landlord['contracts'] as List<dynamic>;

      List<Map<String, dynamic>> flatsList = contracts.expand((contract) {
        return (contract['flats'] as List<dynamic>).map((flatData) {
          var flat = flatData['flat'];
          return {
            'landlord_id': landlord['id'],
            'id': flat['id'],
            'name': flat['name'],
            'building': flat['building']['name'] ?? 'Unknown Building',
            'company_id': landlord['company_id'],
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

        showErrorSnackbar(context, "No flats found for this landlord.");
      }
    } catch (e) {
      await prefs!.setBool('remember_me', false);

      showErrorSnackbar(context, "Something went wrong during login.");
    } finally {
      setState(() => _isLoading = false);
    }
  }*/

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> sendResetRequest() async {

    final url = Uri.parse("$OAuth_URL/forgot");
    final body = {
      "email": emailController.text.trim(),
      "scope": selectedRole.toLowerCase() == "admin" ? "user" : selectedRole.toLowerCase(),
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      // final random = Random();
      // generatedotp = '${random.nextInt(10)}${random.nextInt(10)}${random.nextInt(10)}${random.nextInt(10)}'; // Generates a 4-digit random OTP

     //  print('otp -> $generatedotp');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if(mounted)
          {
            setState(() {
              otpController.clear(); // ✅ safe
              resetToken = data["token"]; // <-- store the token for next step
              otpSent = true;
              otpVerified = false;
              emailLocked = false; // ✅ lock it
            });
          }

         sendOTP(emailController.text.trim()) ;

      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['message'] ?? "Failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> getBase64Image() async {
    final bytes = await rootBundle.load('assets/icon_realestate.png');
    final buffer = bytes.buffer;
    String base64Image = base64Encode(Uint8List.view(buffer));
    return base64Image;
  }

  void sendOTP(String email) async {
     final random = Random();
     generatedotp = '${random.nextInt(10)}${random.nextInt(10)}${random.nextInt(10)}${random.nextInt(10)}'; // Generates a 4-digit random OTP
     print('otp -> $generatedotp');

    final smtpServer = SmtpServer('smtp.zoho.com',
        username: 'contact@tallyuae.ae', // email id
        password: '355dD@3988', // password
        port: 587
    );

    final base64Image = await getBase64Image();

    final message = Message()
      ..from = Address('contact@tallyuae.ae','noreply') // Replace with your Outlook email
      ..recipients.add(email) // Use the email entered by the user
      ..subject = 'Your One-Time Passcode from Fincore RMS'
      ..html =
      '''
                <div style="border: 1px solid #ccc; padding-left: 30px; padding-right: 30px; padding-top: 30px; padding-bottom: 30px; margin-left: 20px; margin-right: 20px; margin-top: 0px; text-align: center;">
                <a href="https://cshllc.ae/">
                <img src="data:image/png;base64,$base64Image" style="width: 150px; height: auto;" alt="Fincore RMS Logo">
            </a>
                <div style="text-align: center;"><p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">Your one-time passcode (OTP) to log into the Fincore RMS is</p></div>
                <br>
                <div style="text-align: center;">
                
                <p style="display: inline-block; background-color: #448AFF; color: #fff; font-size: 16px; font-family: Arial, sans-serif; text-decoration: none; padding: 10px 20px; border-radius: 5px;">$generatedotp</p>
                </div >
                <br>
                <div style="text-align: start;"><p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">If you did not attempt this, please contact <a href="mailto:saadan@ca-eim.com">saadan@ca-eim.com</a></p></div>
                
                <br>
                      <div style="text-align: start;"><p style="color: #999999; font-style: italic; font-size: 12px">Disclaimer: 
                      This email is for verification purposes only.
                      Please do not share your OTP with anyone.<br><br>
                      This is system generated email. Do not reply.</p>
                </div>
              
                <div style="text-align: start;"><div style="text-align: start; border-top: 1px solid #ccc; padding-top: 10px;  "><p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2;">© 2024-2025 Chaturvedi Software House LLC. All Rights Reserved</p>
                <p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2; padding-top: 0px">513 Al Khaleej Center Bur Dubai, Dubai United Arab Emirates, +97143258361 </p>
                
                </div>
                </div>''';

    try {
      final sendReport = await send(message, smtpServer); // send mail

      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP sent to your email.")));

      print('Message sent: ${sendReport.toString()}');
    }
    catch (e)
    {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
      /*print('$e');*/
    }
  }

  void verifyOtp() {
    if (otpController.text.trim() == generatedotp) {
      setState(() => otpVerified = true);

      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP verified successfully.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Incorrect OTP",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );

    }
  }

  Future<void> resetPassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse("$OAuth_URL/change");
    final body = {
      "password":newPasswordController.text.trim(),
      "confirmPassword":confirmPasswordController.text.trim()
    };

    try {
      final response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $resetToken',
            'Content-Type': 'application/json',
          },

        body: jsonEncode(body),
      );


      if (response.statusCode == 200) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Password Reset Successful",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          isForgotPasswordMode = false;
          otpSent = false;
          otpVerified = false;
          resetToken = null;
          newPasswordController.clear();
          confirmPasswordController.clear();
          showNewPassword = false;
          showConfirmPassword: false;
          otpController.clear();
          emailLocked = true; // ✅ unlock
        });
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error["message"] ?? "Reset failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() {
      _isLoading = false;
    });

  }

  void loginUser(String email, String password, bool isAdmin, bool isLandlord) {
    if (isAdmin) {
      _adminlogin(email, password);
    } else if(isLandlord)
      {
        landlordLogin(email, password);
      }else {
      tenantLogin(email, password);
    }
  }

  bool _isStrongPassword(String password) {
    final upperCase = RegExp(r'[A-Z]');
    final lowerCase = RegExp(r'[a-z]');
    final specialChar = RegExp(r'[!@#\$&*~%^()_+=\-]');

    return upperCase.hasMatch(password) &&
        lowerCase.hasMatch(password) &&
        specialChar.hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appbar_color.withOpacity(0.9),
        elevation: 0,
        leading: null,
        centerTitle: true,
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration:  BoxDecoration(
          color: Colors.white,
            /*gradient: LinearGradient(
              colors: [
                Colors.blueGrey.shade700,
                Colors.white,
                Colors.blueGrey.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )*/
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/icon_realestate.png', // Replace with your asset path
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Welcome Back!",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login to your account",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),

        CupertinoSegmentedControl<String>(
              padding: const EdgeInsets.all(4),
              groupValue: selectedRole,
              selectedColor : appbar_color, // segment background when selected
              unselectedColor: Colors.transparent,
              borderColor: Colors.grey,
              pressedColor: appbar_color.withOpacity(0.2),
              children: {
                'Tenant': _buildSegmentLabel('Tenant'),
                'Admin': _buildSegmentLabel('Admin'),
                'Landlord': _buildSegmentLabel('Landlord'),
              },
              onValueChanged: (String value) {
                setState(() {
                  selectedRole = value;
                  isAdmin = value == "Admin";
                  isLandlord = value == "Landlord";
                });
              },
            ),

          const SizedBox(height: 30),
              _buildGlassCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentLabel(String text) {
    final bool isSelected = selectedRole == text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isSelected ? Colors.white : Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }


  Widget _buildGlassCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [

            _buildInputField(
              controller: emailController,
              focusNode: _emailFocusNode,
              readOnly: emailLocked, // ✅ this controls the field
              label: "Email Address",
              icon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email';
                return null;
              },
            ),

            const SizedBox(height: 20),

            if (!isForgotPasswordMode) ...[
              _buildPasswordField(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: remember_me,
                        activeColor: appbar_color,
                        checkColor: Colors.white,
                        onChanged: (val) => setState(() => remember_me = val!),
                      ),
                      Text(
                        'Remember Me',
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isForgotPasswordMode = true;
                        otpSent = false;
                        otpVerified = false;
                      });
                    },

                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                  ),
                ],
              ),

              /*const SizedBox(height: 10),
              Text("Or continue with", style: GoogleFonts.poppins()),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPngSocialIcon('assets/google.png', _handleGoogleSignIn),
                  _buildPngSocialIcon('assets/facebook.png', _handleFacebookSignIn),
                  if (Platform.isIOS)
                    _buildPngSocialIcon('assets/apple.png', _handleAppleSignIn),
                ],
              ),*/

              const SizedBox(height: 30),

              _isLoading
                  ? const CupertinoActivityIndicator(radius: 16, color: Colors.grey)
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appbar_color.withOpacity(0.9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      loginUser(
                        emailController.text,
                        passwordController.text,
                        isAdmin,
                        isLandlord,
                      );
                    }
                  },
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ] else ...[
              if (!otpSent)
                if (!otpSent)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appbar_color.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          sendResetRequest();
                          startOtpTimer();
                        }
                      },
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Send OTP",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

              if (otpSent && !otpVerified) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 100,
                        color: Colors.orange.withOpacity(0.9)), // Mobile phone icon
                    SizedBox(height: 20),
                    Text(
                      'Enter Verification Code',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.9),
                          fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5.0),
                    Center(child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "We've sent you an OTP on ",
                            style: GoogleFonts.poppins(color: Colors.black.withOpacity(0.9)),

                          ),
                          TextSpan(
                            text: emailController.text, // The masked email value
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.9)), // Bold style
                          ),
                        ],
                      ),
                    ),),

                    Text(
                        "Please enter that code below to continue."
                        ,style: GoogleFonts.poppins(color: Colors.black.withOpacity(0.9)),
                        textAlign: TextAlign.center// Regular text style
                    ),

                    const SizedBox(height: 20),

                    PinCodeTextField(
                      appContext: context,
                      autoDisposeControllers: false,
                      length: 4,
                      controller: otpController,
                      obscureText: true,
                      obscuringCharacter: '●',
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(30),
                        fieldHeight: 50,
                        fieldWidth: 50,
                        activeFillColor: Colors.black.withOpacity(0.1),
                        inactiveFillColor: Colors.black.withOpacity(0.05),
                        selectedFillColor: Colors.white.withOpacity(0.15),
                        activeColor: Colors.black,
                        selectedColor: appbar_color,
                        inactiveColor: Colors.black.withOpacity(0.3),
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      enableActiveFill: true,
                      validator: (value) {
                        if (value == null || value.length != 4) {
                          return "Enter 4-digit OTP";
                        }
                        return null;
                      },
                      onChanged: (value) {},
                      onCompleted: (value) {
                        print("OTP Entered: $value");
                        verifyOtp();
                      },
                    ),

                    const SizedBox(height: 20),

                    _showResendButton
                        ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appbar_color.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        sendResetRequest(); // <-- your existing resend OTP logic
                        startOtpTimer();    // <-- restart timer
                      },
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        'Send OTP Again',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                        : Text(
                      "Resend OTP in 00:${_remainingSeconds.toString().padLeft(2, '0')}",
                      style: GoogleFonts.poppins(
                        color: Colors.black.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              if (otpVerified) ...[
                const SizedBox(height: 16),
                _buildInputField(
                  controller: newPasswordController,
                  focusNode: FocusNode(),
                  label: "New Password",
                  icon: Icons.lock,
                  isPassword: true,
                  obscureText: !showNewPassword,
                  onToggleVisibility: () {
                    setState(() => showNewPassword = !showNewPassword);
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter password";
                    if (v.length < 8) return "Minimum 8 characters";
                    return null;
                  },
                ),

                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      isStrongPassword
                          ? "✅ Strong password"
                          : "Entered password must contains one upper case, one lower case & special characters",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isStrongPassword ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _buildInputField(
                  controller: confirmPasswordController,
                  focusNode: FocusNode(),
                  label: "Confirm Password",
                  icon: Icons.lock,
                  isPassword: true,
                  obscureText: !showConfirmPassword,
                  onToggleVisibility: () {
                    setState(() => showConfirmPassword = !showConfirmPassword);
                  },
                  validator: (v) {
                    if (v != newPasswordController.text) return "Passwords do not match";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child:    ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appbar_color.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : (){
                      if(isStrongPassword)
                      {
                        resetPassword();
                      }
                    },
                    child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Update Password",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        )),
                  ),
                ),

              ],

              const SizedBox(height: 12),
              TextButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black.withOpacity(0.9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (!mounted) return;



                  setState(() {
                    isForgotPasswordMode = false;
                    otpSent = false;
                    otpVerified = false;
                    otpController.clear();
                    resetToken = null;
                    emailLocked = true; // ✅ unlock

                    newPasswordController.clear();
                    confirmPasswordController.clear();
                    showNewPassword = false;
                    showConfirmPassword: false;

                  });
                },
                child: Text("Back to Login", style: GoogleFonts.poppins(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),),
              ),

            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool isPassword = false, // ✅ NEW
    bool obscureText = false, // ✅ NEW
    VoidCallback? onToggleVisibility, // ✅ NEW
    bool readOnly = true, // ✅ add this optional param



  }) {
    return TextFormField(
      controller: controller,
      enabled: readOnly, // ✅ respect it here
      obscureText: obscureText,
      style: GoogleFonts.poppins(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black),
        prefixIcon: Icon(icon, color: Colors.black),

        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.black,
          ),
          onPressed: onToggleVisibility,
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: appbar_color),
        ),

      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      focusNode: _passwordFocusNode,
      obscureText: _obscureText,
      style: GoogleFonts.poppins(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: GoogleFonts.poppins(color: Colors.black),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.black),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: appbar_color),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : null,
    );
  }

  Widget _buildPngSocialIcon(String asset, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset(asset),
        ),
      ),
    );
  }


}
