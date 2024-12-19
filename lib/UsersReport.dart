import 'dart:convert';
import 'package:cshrealestatemobile/AddUser.dart';
import 'package:cshrealestatemobile/ModifyUser.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;

class UserModel {
  final String role_name;
  final String name;
  final String email;

  UserModel({
    required this.role_name,
    required this.name,
    required this.email
  });

  factory UserModel.fromJson(Map<String, dynamic> json)
  {
    return UserModel
      (
        role_name: json['role_name'],
        name: json['customer_name'],
        email: json['user_name']
    );
  }
}

class UsersReport extends StatefulWidget {
  const UsersReport({Key? key}) : super(key: key);
  @override
  _UserReportPageState createState() => _UserReportPageState();
}

class _UserReportPageState extends State<UsersReport> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = false,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoUserFound = false;

  String user_email_fetched = "";

  final List<UserModel> users = [
    UserModel(
      role_name: 'Accountant',
      name: 'John Doe',
      email: 'johndoe@example.com',
    ),
    UserModel(
      role_name: 'Sales',
      name: 'Jane Smith',
      email: 'janesmith@example.com',
    ),
    UserModel(
      role_name: 'Manager',
      name: 'Bob Johnson',
      email: 'bobjohnson@example.com',
    ),
  ];

  String name = "",email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    /*setState(()
    {
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
    });*/
    /*fetchUsers(serial_no!);*/
  }

  /*Future<void> _showConfirmationDialogAndNavigate(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button to close dialog
      builder: (BuildContext context) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: AnimationController(
              duration: const Duration(milliseconds: 500),
              vsync: this,
            )..forward(),
            curve: Curves.fastOutSlowIn,
          ),
          child: AlertDialog(
            title: Text('Removal Confirmation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Do you really want to Delete User'),
                ],
              ),
            ),
            actions: <Widget>[

              TextButton(
                child: Text(
                  'No',
                  style: TextStyle(
                    color: Color(0xFF30D5C8), // Change the text color here
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),

              TextButton(
                child: Text(
                  'Yes',
                  style: TextStyle(
                    color: Color(0xFF30D5C8), // Change the text color here
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  userdelete(serial_no!,user_email_fetched);
                },
              ),
            ],
          ),
        );
      },
    );
  }*/

  /*Future<void> userdelete(String selectedserial,String email) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/login/deleteUser');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': selectedserial,
      'username' : email
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      final responsee = response.body;
      if (responsee != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responsee),
          ),
        );
        setState(()
        {
          _isLoading = true;
          fetchUsers(serial_no!);
        }
        );
      }
      else
      {
        throw Exception('Failed to fetch data');
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
      else {
        error = "Something went wrong!!!";
      }
      Fluttertoast.showToast(msg: error);
    }
    setState(() {
      _isLoading = false;
    });
  }*/

  /*Future<void> fetchUsers(String selectedserial) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/login/getRole');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': selectedserial,
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      users.clear();
      try
      {
        final List<dynamic> jsonList = json.decode(response.body);

        if (jsonList != null)
        {
          isVisibleNoUserFound = false;

          users.addAll(jsonList.map((json) => UserModel.fromJson(json)).toList());
          users.sort(compareDataObjects);
        }
        else
        {
          throw Exception('Error in data fetching');
        }
        setState(()
        {
          if(users.isEmpty)
          {
            isVisibleNoUserFound = true;
          }
          _isLoading = false;
        });
      }
      catch (e)
      {
        print(e);
      }
    }

    setState(()
    {
      if(users.isEmpty)
      {
        isVisibleNoUserFound = true;
      }
      _isLoading = false;
    });
  }*/

  @override
  void initState()
  {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  Future<void> _refresh() async
  {
    setState(() {
      /*fetchUsers(serial_no!);*/
    });
  }

  int compareDataObjects(UserModel a, UserModel b) {
    return a.name.compareTo(b.name);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          /*Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Dashboard()),
          );*/
          return true;
        },
        child:Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
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
                                  'Users',
                                  style: TextStyle(
                                      color: Colors.white
                                  ),
                                  overflow: TextOverflow.ellipsis, // Truncate text if it overflows
                                  maxLines: 1, // Display only one line of text
                                ),
                              ),
                              SizedBox(width: 10), // Add some spacing between text and image
                              Icon(

                                Icons.edit,
                                color: appbar_color,
                              )]))),
                backgroundColor: appbar_color,
                automaticallyImplyLeading: false,
                leading: IconButton(
                    icon: Icon(Icons.menu,color: Colors.white),
                    onPressed: () {
                      _scaffoldKey.currentState!.openDrawer();
                    })),
            drawer: Sidebar
              (
                isDashEnable: isDashEnable,
                isRolesVisible: isRolesVisible,
                isRolesEnable: isRolesEnable,
                isUserEnable: isUserEnable,
                isUserVisible: isUserVisible,
                Username: name,
                Email: email,
                tickerProvider: this
            ),
            body: RefreshIndicator(
                onRefresh: _refresh,
                child:Stack(
                    children: [
                      Visibility(
                          visible: isVisibleNoUserFound,
                          child:  Container(
                              padding: EdgeInsets.only(top: 20.0),
                              child: Center(
                                  child: Text(
                                      'No User Found',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24.0,
                                      ))))),

                      Container(
                          child: ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final card = users[index];
                                return Container(
                                    margin: EdgeInsets.all(0),
                                    child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Padding(padding: EdgeInsets.all(10),
                                            child: ListTile(
                                                title:Column(
                                                    children: [
                                                      Row(
                                                          children : [

                                                            Icon(

                                                                Icons.person
                                                            ),
                                                            SizedBox(width: 10),
                                                            Flexible(child: SingleChildScrollView(
                                                              scrollDirection: Axis.horizontal,
                                                              child: Text(card.name),
                                                            ))]),

                                                      Padding(padding: EdgeInsets.only(top: 10),
                                                          child: Row(
                                                              children : [
                                                                Icon(

                                                                  Icons.email_outlined
                                                                ),
                                                                SizedBox(width: 10),
                                                                Flexible(child: SingleChildScrollView(
                                                                  scrollDirection: Axis.horizontal,
                                                                  child: Text(card.email),
                                                                ))])),

                                                      Padding(padding: EdgeInsets.only(top:10),
                                                          child: Row(
                                                              children : [
                                                                Icon(

                                                                  Icons.group
                                                                ),
                                                                SizedBox(width: 10),
                                                                Flexible(child: SingleChildScrollView(
                                                                  scrollDirection: Axis.horizontal,
                                                                  child: Text(card.role_name),
                                                                ),)
                                                              ])),


                                        Padding(
                                          padding: EdgeInsets.only(top: 20, bottom: 0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  String rolename = card.role_name;
                                                  String full_name = card.name;
                                                  String email_address = card.email;
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => ModifyUser()),
                                                  );
                                                },
                                                icon: Icon(Icons.edit, color: Colors.black),
                                                label: Text(
                                                  'Edit',
                                                  style: TextStyle(color: Colors.black),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white, // Button background color
                                                  shadowColor: Colors.black.withOpacity(0.75), // Shadow color
                                                  elevation: 5, // Elevation value
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20), // Rounded corners
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10), // Spacing between buttons
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  user_email_fetched = card.email;
                                                  // Show confirmation dialog or perform your desired action.
                                                },
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                label: Text(
                                                  'Delete',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white, // Button background color
                                                  shadowColor: Colors.black.withOpacity(0.75), // Shadow color
                                                  elevation: 5, // Elevation value
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20), // Rounded corners
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        ]),
                                               ))));})),
                      Visibility(
                        visible: _isLoading,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        right: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddUser()),
                                  );
                          },
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(), // Makes the button circular
                            padding: EdgeInsets.all(16), // Adjust padding to control button size
                            backgroundColor: Colors.blueGrey, // Button background color
                            shadowColor: Colors.black.withOpacity(1.0), // Shadow color
                            elevation: 6, // Shadow intensity
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white, // Icon color
                            size: 35, // Icon size
                          ),
                        ),
                      ),
                    ]))));}}