import 'package:cshrealestatemobile/CreateSalesInquiry.dart';
import 'package:cshrealestatemobile/FollowupSalesInquiry.dart';
import 'package:cshrealestatemobile/SalesInquiryTransfer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'Sidebar.dart';

class SalesInquiryReport extends StatefulWidget {
  @override
  _SalesInquiryReportState createState() =>
      _SalesInquiryReportState();
}

class InquiryModel {
  final String customer_name;
  final String unit_type;
  final String area;
  final String emirate;
  final String status;
  final String inquiry_no;
  final String creation_date;
  final String description;
  final String contactno;
  final String email;

  InquiryModel({
    required this.customer_name,
    required this.unit_type,
    required this.area,
    required this.emirate,
    required this.status,
    required this.inquiry_no,
    required this.creation_date,
    required this.description,
    required this.contactno,
    required this.email,

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
      inquiry_no: json['inquiry_no'],
      creation_date: json['creation_date'],
      description: json['description'],
      contactno: json['contactno'],
      email: json['email'],

    );
  }
}

class _SalesInquiryReportState
    extends State<SalesInquiryReport> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<InquiryModel> salesinquiry = [
    InquiryModel(
        customer_name: 'Ali',
        unit_type: '1BHK, 3BHK',
        area: 'Bur Dubai, Al Khan',
        emirate: 'Dubai, Sharjah',
        status: 'Closed',
        inquiry_no: "INQ-001",
        creation_date: "20-12-2024",
        description: "This is description",
        contactno: "+971 500000000",
        email: "saadan@ca-eim.com"

    ),
    InquiryModel(
        customer_name: 'Saadan',
        unit_type: 'Studio',
        area: 'Al Qusais',
        emirate: 'Dubai',
        status: 'In Progress',
        inquiry_no: "INQ-002",
        creation_date: "22-12-2024",
        description: "This is description",
        contactno: "+971 500000000",
        email: "saadan@ca-eim.com"
    ),

  ];

  List<bool> _expandedinquirys = [];

  @override
  void initState() {
    super.initState();
    // Initialize all inquirys to be collapsed by default
    _expandedinquirys = List.generate(salesinquiry.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu,
              color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),

        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: Text(
          'Inquiries',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 20.0,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Sidebar(
          isDashEnable: true,
          isRolesVisible: true,
          isRolesEnable: true,
          isUserEnable: true,
          isUserVisible: true,
          Username: "",
          Email: "",
          tickerProvider: this),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: salesinquiry.length,
          itemBuilder: (context, index) {
            final inquiry = salesinquiry[index];
            return _buildinquiryCard(inquiry, index);
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.blueGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CreateSalesInquiry()),

            );
          },
          label: Text(
            'New Inquiry',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildinquiryCard(InquiryModel inquiry, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedinquirys[index] = !_expandedinquirys[index];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
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
            _buildinquiryHeader(inquiry),
            Divider(color: Colors.grey[300]),
            _buildinquiryDetails(inquiry),



            Container(
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildDecentButton(
                          'Follow Up',
                          Icons.schedule,
                          Colors.blue,
                              () {

                            String name = inquiry.customer_name;
                            List<String> emiratesList = inquiry.emirate.split(',').map((e) => e.trim()).toList();
                            List<String> areaList = inquiry.area.split(',').map((e) => e.trim()).toList();
                            List<String> unittype = inquiry.unit_type.split(',').map((e) => e.trim()).toList();
                            String contactno = inquiry.contactno;
                            String email = inquiry.email;


                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) =>
                                    FollowupSalesInquiry(name: name, unittype: unittype, existingAreaList: areaList, existingEmirateList: emiratesList, contactno: contactno, email: email)));
                          },
                        ),
                        SizedBox(width:5),
                        Row(children: [


                          if(inquiry.status == 'In Progress')
                            _buildDecentButton(
                              'Transfer',
                              Icons.swap_horiz,
                              Colors.orange,
                                  () {

                                String name = inquiry.customer_name;
                                String emirate = inquiry.emirate;
                                String area = inquiry.area;
                                String unittype = inquiry.unit_type;
                                String contactno = inquiry.contactno;
                                String email = inquiry.email;


                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) =>
                                        SalesInquiryTransfer(name: name, unittype: unittype, area: area, emirate: emirate)));
                              },
                            ),


                          SizedBox(width:5)
                        ],),



                        _buildDecentButton(
                          'Delete',
                          Icons.delete,
                          Colors.red,
                              () {
                            // Delete action
                            // Add your delete functionality here
                          },
                        ),
                      ],
                    ),
                )
              )


            ),


            if (_expandedinquirys[index])
              _buildExpandedinquiryView(inquiry),
          ],
        ),
      ),
    );
  }


  Widget _buildinquiryHeader(InquiryModel inquiry) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [

            Icon(Icons.confirmation_number, color: Colors.teal, size: 24.0),
            SizedBox(width: 8.0),
            Text(
              inquiry.inquiry_no,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        _getStatusBadge(inquiry.status),
      ],
    );
  }

  Widget _buildinquiryDetails(InquiryModel inquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Name:', inquiry.customer_name),
        _buildInfoRow('Unit Type:', inquiry.unit_type),
        _buildInfoRow('Area:', inquiry.area),
        _buildInfoRow('Date:', inquiry.creation_date),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8.0),
          Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child:Text(
                  value,
                  style: TextStyle(
                    color: Colors.black87,
                  ),

                ) ,
              )
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'In Progress':
        color = Colors.orange;
        break;
      case 'Closed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExpandedinquiryView(InquiryModel inquiry) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Emirate:', inquiry.emirate),
          _buildInfoRow('Description:', inquiry.description),

        ],
      ),
    );
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

}

