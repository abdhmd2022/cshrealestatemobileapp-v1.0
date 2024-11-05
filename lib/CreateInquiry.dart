import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

class CreateInquiry extends StatefulWidget {

  @override
  State<CreateInquiry> createState() => _CreateInquiryPageState();
}

class _CreateInquiryPageState extends State<CreateInquiry> {

  @override
  void initState() {
    super.initState();

    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(app_name,
            style: TextStyle(
                color: Colors.white
            ),),
        ),
        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,

            child:    Column(
                children: [


                ]))
    );}}
