import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'constants.dart';

class RoleModel {
  final String role_name;

  RoleModel({
    required this.role_name
  });
  factory RoleModel.fromJson(Map<String, dynamic> json)
  {
    return RoleModel
      (
        role_name: json['role_name']
    );
  }
}

class RolesReport extends StatefulWidget {
  const RolesReport({Key? key}) : super(key: key);
  @override
  _RolesReportPageState createState() => _RolesReportPageState();
}

class _RolesReportPageState extends State<RolesReport> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = false,
      _isLoading = false,
      isVisibleNoRoleFound = false;

  String rolename_fetched = "";

  /*final List<RoleModel> roles = [];*/

  final List<RoleModel> roles = List<RoleModel>.from([
    {"role_name": "Sales Manager"},
    {"role_name": "Sales Executive"},
  ].map((json) => RoleModel.fromJson(json)));

  String name = "",email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
   /* setState(() {
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
    });
    fetchRoles(serial_no!);*/
  }

  /*Future<void> _showConfirmationDialogAndNavigate(BuildContext context) async
  {
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
                        Text('Do you really want to Delete Role'),
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

                          roledelete(serial_no!,rolename_fetched);
                        })]));});}*/

  /*Future<void> roledelete(String selectedserial,String rolename) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/roles/delete');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode( {
      'serialno': selectedserial,
      'rolename' : rolename
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );


    if (response.statusCode == 200)
    {
      final responsee = response.body;
      if (responsee != null)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responsee),
          ),
        );
        if (responsee == "Unable to Delete! User Exists Against This Role.")
        {
          setState(() {
            _isLoading = false;
          });
        }
        else
        {
          setState(() {
            _isLoading = true;
            fetchRoles(serial_no!);
          });
        }
      } else
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

  Future<void> fetchRoles(String selectedserial) async {
    setState(() {
      _isLoading = true;
    });
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
      roles.clear();

      try
      {
        final List<dynamic> jsonList = json.decode(response.body);

        if (jsonList != null)
        {
          isVisibleNoRoleFound = false;
          roles.addAll(jsonList.map((json) => RoleModel.fromJson(json)).toList());
        }
        else
        {
          throw Exception('Failed to fetch data');
        }
        setState(() {
          if(roles.isEmpty)
          {
            isVisibleNoRoleFound = true;
          }
          _isLoading = false;
        });

      }
      catch (e)
      {
        print(e);
      }
    }
    setState(() {
      if(roles.isEmpty)
      {
        isVisibleNoRoleFound = true;
      }
      _isLoading = false;
    });
  }*/

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  Future<void> _refresh() async
  {
    setState(()
    {
     /* fetchRoles(serial_no!);*/
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return WillPopScope(
        onWillPop: () async
        {
          /*Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Dashboard()),
          );*/
          return true;
        },
        child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Flexible(
                child: Text(
                  'Roles',
                  style: TextStyle(
                      color: Colors.white
                  ),
                  overflow: TextOverflow.ellipsis, // Truncate text if it overflows
                  maxLines: 1, // Display only one line of text
                ),
              ),
              backgroundColor: appbar_color,

              automaticallyImplyLeading: false,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.menu,color: Colors.white),
                onPressed: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
              ),
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
                child:Stack(
                    children: [
                      Visibility(
                          visible: isVisibleNoRoleFound,
                          child:  Container(
                              padding: EdgeInsets.only(top: 20.0),
                              child: Center(
                                  child: Text(
                                      'No Roles Found',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24.0,
                                      ))))),

                      Container(
                          child: ListView.builder(
                              itemCount: roles.length,
                              itemBuilder: (context, index) {
                                final card = roles[index];
                                return Container(
                                    margin: EdgeInsets.all(0),
                                    child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Padding(

                                          padding: EdgeInsets.all(10),
                                          child:ListTile(
                                              title: Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [






                                                    Row(children: [

                                                      Icon(
                                                          Icons.groups_outlined
                                                      ),

                                                      SizedBox(width: 10,),
                                                      Text(card.role_name),
                                                    ],),


                                                    SizedBox(height: 10,),
                                                    Row(children: [

                                                      Icon(
                                                          Icons.group
                                                      ),

                                                      SizedBox(width: 10,),

                                                      Text('Sales'),
                                                    ],),
                                                    Padding(
                                                        padding: EdgeInsets.only(top: 20, bottom: 0),
                                                        child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              ElevatedButton.icon(
                                                                onPressed: () {
                                                                  String rolename = card.role_name;
                                                                  /*String full_name = card.name;
                                                        String email_address = card.email;
                                                        Navigator.pushReplacement(
                                                          context,
                                                          MaterialPageRoute(builder: (context) => ModifyUser()),
                                                        );*/
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
                                                                      )))]))])
                                          )
                                        )
                                        ));})),
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
                            /*Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => AddUser()),
                            );*/
                          },
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(), // Makes the button circular
                            padding: EdgeInsets.all(16), // Adjust padding to control button size
                            backgroundColor: appbar_color, // Button background color
                            shadowColor: Colors.black.withOpacity(1.0), // Shadow color
                            elevation: 6, // Shadow intensity
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white, // Icon color
                            size: 35, // Icon size
                          ),
                        ),
                      ),]))));
    // TODO: implement build
  }}