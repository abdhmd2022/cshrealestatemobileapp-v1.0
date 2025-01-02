import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SalesDashboard.dart';
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
    );}
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

  List<AvailableUnits> filteredUnits = [];

  String searchQuery = "";

  String name = "",email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      filteredUnits = units; // Initially, show all units
    });
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

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredUnits = units
          .where((unit) =>
      unit.unittype.toLowerCase().contains(query.toLowerCase()) ||
          unit.building_name.toLowerCase().contains(query.toLowerCase()) ||
          unit.area.toLowerCase().contains(query.toLowerCase()) ||
          unit.emirate.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

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
            backgroundColor: const Color(0xFFF2F4F8),
            appBar: AppBar(
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: _updateSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search Units',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
                title: Text(
                  'Available Units',
                  style: TextStyle(
                      color: Colors.white
                  ),
                  overflow: TextOverflow.ellipsis, // Truncate text if it overflows
                  maxLines: 2, // Display only one line of text
                ),
                backgroundColor: appbar_color,
                automaticallyImplyLeading: false,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                ),),
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
                            itemCount: filteredUnits.length,
                            itemBuilder: (context, index) {
                              final unit = filteredUnits[index];
                              return Container(
                                margin: const EdgeInsets.only(top: 15.0, bottom: 0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 10.0,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.home),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(unit.unittype, style: TextStyle(fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.location_city),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(unit.building_name, style: TextStyle(fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(unit.area, style: TextStyle(fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.public),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(unit.emirate, style: TextStyle(fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: EdgeInsets.only(top: 0, bottom: 0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [

                                          _buildDecentButton(
                                            'View',
                                            Icons.remove_red_eye,
                                            Colors.orange,
                                                () {
                                              String unitno = unit.unitno;
                                              String unittype = unit.unittype;
                                              String area = unit.area;
                                              String emirate = unit.emirate;
                                              String rent = "AED 50,000";
                                              String parking = "1 included";
                                              String balcony = "Yes";
                                              String bathooms = "2";
                                              String building = unit.building_name;

                                              showDialog(
                                                  context: context,
                                                  builder: (context) => AvailableUnitsDialog(unitno: unitno, area: area, emirate: emirate, unittype: unittype, rent: rent, parking: parking, balcony: balcony, bathrooms: bathooms,building_name: building,));
                                            },
                                          ),

                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),








                      ),
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
      backgroundColor: Colors.white,
      elevation: 8,
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
Widget _buildDecentButton(
    String label, IconData icon, Color color, VoidCallback onPressed) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(30.0),
    splashColor: color.withOpacity(0.2),
    highlightColor: color.withOpacity(0.1),
    child: Container(
      margin: EdgeInsets.only(top: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        color: Colors.white,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8.0),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

