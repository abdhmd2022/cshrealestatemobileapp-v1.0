import 'dart:convert';
import 'package:cshrealestatemobile/AddUser.dart';
import 'package:cshrealestatemobile/CreateSalesInquiry.dart';
import 'package:cshrealestatemobile/ModifyUser.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;

class InquiryModel {
  final String customer_name;
  final String unit_type;
  final String area;
  final String emirate;
  final String status;

  InquiryModel({
    required this.customer_name,
    required this.unit_type,
    required this.area,
    required this.emirate,
    required this.status

  });

  factory InquiryModel.fromJson(Map<String, dynamic> json)
  {
    return InquiryModel
      (
        customer_name: json['customer_name'],
        unit_type: json['unit_type'],
        area: json['area'],
        emirate: json['emirate'],
        status: json['status'],
    );
  }
}

class SalesInquiryReport extends StatefulWidget {
  const SalesInquiryReport({Key? key}) : super(key: key);
  @override
  _SalesInquiryReportPageState createState() => _SalesInquiryReportPageState();
}

class _SalesInquiryReportPageState extends State<SalesInquiryReport> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = false,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoUserFound = false;

  String user_email_fetched = "";

  final List<InquiryModel> salesinquiry = [
    InquiryModel(
      customer_name: 'Ali',
      unit_type: '1 bhk',
      area: 'Bur Dubai',
      emirate: 'Dubai',
      status: 'Closed'
    ),
    InquiryModel(
        customer_name: 'Saadan',
        unit_type: 'Studio',
        area: 'Al Qusais',
        emirate: 'Dubai',
        status: 'In Progress'
    ),

  ];

  String name = "",email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";

  late AnimationController _animationController;
  late ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    // Initialize ScrollController


    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..addListener(() {
      // On each animation tick, update the scroll position
      _scrollController.jumpTo(_animationController.value); // Adjust 200 based on the width you want to animate
    });

    // Start the animation automatically when the screen loads
    _animationController.repeat(reverse: true); // Bounce effect (repeat and reverse)


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
                  Text('Do you really want to Delete'),
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

  int compareDataObjects(InquiryModel a, InquiryModel b) {
    return a.customer_name.compareTo(b.customer_name);
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
                title: Flexible(
                  child: Text(
                    'Inquiries',
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
                              itemCount: salesinquiry.length,
                              itemBuilder: (context, index) {
                                final card = salesinquiry[index];
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
                                                            child: Text(card.customer_name),
                                                          ))]),

                                                    Padding(padding: EdgeInsets.only(top: 10),
                                                        child: Row(
                                                            children : [
                                                              Icon(

                                                                  Icons.apartment
                                                              ),
                                                              SizedBox(width: 10),
                                                              Flexible(child: SingleChildScrollView(
                                                                scrollDirection: Axis.horizontal,
                                                                child: Text(card.unit_type),
                                                              ))])),

                                                    Padding(padding: EdgeInsets.only(top:10),
                                                        child: Row(
                                                            children : [
                                                              Icon(

                                                                  Icons.location_on

                                                              ),
                                                              SizedBox(width: 10),
                                                              Flexible(child: SingleChildScrollView(
                                                                scrollDirection: Axis.horizontal,
                                                                child: Text(card.area),
                                                              ),)
                                                            ])),

                                                    Padding(padding: EdgeInsets.only(top:10),
                                                        child: Row(
                                                            children : [
                                                              Icon(

                                                                  Icons.public

                                                              ),
                                                              SizedBox(width: 10),
                                                              Flexible(child: SingleChildScrollView(
                                                                scrollDirection: Axis.horizontal,
                                                                child: Text(card.emirate),
                                                              ),)
                                                            ])),



                                                    Padding(
                                                      padding: EdgeInsets.only(top: 10),
                                                      child: Row(
                                                        children: [
                                                          Icon(

                                                              Icons.assignment

                                                          ),
                                                          SizedBox(width: 10),

                                                          Flexible(
                                                            child: SingleChildScrollView(
                                                              scrollDirection: Axis.horizontal,
                                                              child: Text(
                                                                card.status,
                                                                style: TextStyle(
                                                                  color: Colors.black,
                                                                  fontWeight: FontWeight.normal,
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                          SizedBox(width: 5),

                                                          Container(
                                                            width: 10, // Circle width
                                                            height: 10, // Circle height
                                                            margin: EdgeInsets.only(right: 10,top:1), // Spacing between circle and text
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: card.status.toLowerCase() == 'closed'
                                                                  ? Colors.green
                                                                  : card.status.toLowerCase() == 'in progress'
                                                                  ? Colors.orange
                                                                  : Colors.black, // Default color for other statuses
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),







                                                    SingleChildScrollView(
                                                        controller: _scrollController,
                                                      scrollDirection: Axis.horizontal,
                                                      child: Padding(
                                                        padding: EdgeInsets.only(top: 20, bottom: 10,left:5,right:5),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            ElevatedButton.icon(
                                                              onPressed: () {

                                                                Navigator.pushReplacement(
                                                                  context,
                                                                  MaterialPageRoute(builder: (context) => ModifyUser()),
                                                                );
                                                              },
                                                              icon: Icon(Icons.edit, color: Colors.black),
                                                              label: Text(
                                                                'Follow up',
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
                                                            SizedBox(width: 10),

                                                            ElevatedButton.icon(
                                                              onPressed: () {

                                                                Navigator.pushReplacement(
                                                                  context,
                                                                  MaterialPageRoute(builder: (context) => ModifyUser()),
                                                                );
                                                              },
                                                              icon: Icon(Icons.remove_red_eye, color: Colors.black),
                                                              label: Text(
                                                                'View',
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


                                                            if (card.status.toLowerCase() == 'in progress') // Show only for 'In Progress'
                                                              Row(children:[
                                                                SizedBox(width: 10),
                                                                ElevatedButton.icon(
                                                                  onPressed: () {
                                                                    // Action for transfer button
                                                                  },
                                                                  icon: Icon(Icons.swap_horiz, color: Colors.black),
                                                                  label: Text(
                                                                    'Transfer',
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
                                                              ]),
                                                            // Spacing between buttons

                                                            SizedBox(width: 10),
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
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )

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
                              MaterialPageRoute(builder: (context) => CreateSalesInquiry()),
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