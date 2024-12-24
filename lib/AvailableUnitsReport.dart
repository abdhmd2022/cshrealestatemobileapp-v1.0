import 'package:cshrealestatemobile/AddUser.dart';
import 'package:cshrealestatemobile/ModifyUser.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'constants.dart';

class AvailableUnits {
  final String unitno;
  final String unittype;
  final String building_name;
  final String area;
  final String emirate;

  AvailableUnits({
    required this.unitno,
    required this.unittype,
    required this.building_name,
    required this.area,
    required this.emirate
  });

  factory AvailableUnits.fromJson(Map<String, dynamic> json)
  {
    return AvailableUnits
      (
      unitno: json['unitno'],
        unittype: json['unittype'],
        building_name: json['building_name'],
        area: json['area'],
        emirate: json['emirate'],
    );
  }
}

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
      _isLoading = false,
      isVisibleNoUserFound = false;

  String user_email_fetched = "";

  final List<AvailableUnits> units = [
    AvailableUnits(
      unitno: "101",
      unittype: '1BHK',
      building_name: 'Al Khaleej Center',
      area: 'Bur Dubai',
      emirate: 'Dubai'
    ),
    AvailableUnits(
        unitno: "402",
        unittype: '2BHK',
        building_name: 'Musalla Tower',
        area: 'Bur Dubai',
        emirate: 'Dubai'
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

  int compareDataObjects(AvailableUnits a, AvailableUnits b) {
    return a.area.compareTo(b.area);
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
                    'Available Units',
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
                              itemCount: units.length,
                              itemBuilder: (context, index) {
                                final card = units[index];
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

                                                              Icons.home
                                                          ),
                                                          SizedBox(width: 10),
                                                          Flexible(child: SingleChildScrollView(
                                                            scrollDirection: Axis.horizontal,
                                                            child: Text(card.unittype),
                                                          ))]),

                                                    Padding(padding: EdgeInsets.only(top: 10),
                                                        child: Row(
                                                            children : [
                                                              Icon(

                                                                  Icons.location_city
                                                              ),
                                                              SizedBox(width: 10),
                                                              Flexible(child: SingleChildScrollView(
                                                                scrollDirection: Axis.horizontal,
                                                                child: Text(card.building_name),
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
                                                      padding: EdgeInsets.only(top: 20, bottom: 0),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          ElevatedButton.icon(
                                                            onPressed: () {
                                                              String unitno = card.unitno;
                                                              String unittype = card.unittype;
                                                              String area = card.area;
                                                              String emirate = card.emirate;
                                                              String rent = "AED 50,000";
                                                              String parking = "1 included";
                                                              String balcony = "Yes";
                                                              String bathooms = "2";
                                                              String building = card.building_name;

                                                              showDialog(
                                                                context: context,
                                                                builder: (context) => AvailableUnitsDialog(unitno: unitno, area: area, emirate: emirate, unittype: unittype, rent: rent, parking: parking, balcony: balcony, bathrooms: bathooms,building_name: building,));

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
                      /*Positioned(
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
                      ),*/
                    ]))));}}


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

  const AvailableUnitsDialog({Key? key,
    required this.unitno,
    required this.area,
    required this.building_name,
    required this.emirate,
    required this.unittype,
    required this.rent,
    required this.parking,
    required this.balcony,
    required this.bathrooms
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [

              /*Icon(
                Icons.home
              ),
              SizedBox(width: 5,),*/
              Text("${unitno}",
                style: TextStyle(
                    fontSize: 20,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          )
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children : [

                Icon(
                    Icons.home
                ),
                SizedBox(width: 10),
                Flexible(child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(unittype),
                ))]),

          Padding(padding: EdgeInsets.only(top: 10),
              child: Row(
                  children : [
                    Icon(

                        Icons.business
                    ),
                    SizedBox(width: 10),
                    Flexible(child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(building_name),
                    ))])),

          Padding(padding: EdgeInsets.only(top: 10),
              child: Row(
                  children : [
                    Icon(

                        Icons.location_on
                    ),
                    SizedBox(width: 10),
                    Flexible(child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(area),
                    ))])),

          Padding(padding: EdgeInsets.only(top: 10),
              child: Row(
                  children : [
                    Icon(

                        Icons.public
                    ),
                    SizedBox(width: 10),
                    Flexible(child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(emirate),
                    ))])),

          Padding(padding: EdgeInsets.only(top: 10),
              child: Row(
                  children : [
                    Icon(

                        Icons.payment
                    ),
                    SizedBox(width: 10),
                    Flexible(child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(rent),
                    ))])),

          Padding(padding: EdgeInsets.only(top:10),
              child: Row(
                  children : [
                    Icon(

                        Icons.local_parking

                    ),
                    SizedBox(width: 10),
                    Flexible(child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(parking),
                    ),)
                  ])),

          Padding(padding: EdgeInsets.only(top:10),
              child: Row(
                  children : [
                    Icon(

                        Icons.deck

                    ),
                    SizedBox(width: 10),
                    Flexible(child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text('Balcony: $balcony'),
                    ),)
                  ])),

          Padding(padding: EdgeInsets.only(top:10),
              child: Row(
                  children : [
                    Icon(

                        Icons.bathtub

                    ),
                    SizedBox(width: 10),
                    Flexible(child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text('Bathrooms: $bathrooms'),
                    ),)
                  ])),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close",
            style: TextStyle(
                color: Colors.blueGrey
            ),),
        ),
      ],
    );
  }
}